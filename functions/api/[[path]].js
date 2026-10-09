/**
 * Cloudflare Pages Function backed by D1.
 * Routes:
 *   GET  /api/health
 *   GET  /api/expenses
 *   POST /api/expenses/sync   { ops: [{op,id?,item?}] }
 *
 * Expenses are scoped by the signed-in user. X-Device-Id is only used once,
 * at login, to copy a previous device ledger into that account.
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Device-Id, Authorization',
  'Access-Control-Max-Age': '86400',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...CORS,
    },
  });
}

function deviceId(request) {
  const id = request.headers.get('X-Device-Id') || '';
  if (!/^[A-Za-z0-9_-]{8,80}$/.test(id)) return null;
  return id;
}

async function ensureSchema(env) {
  await env.DB.prepare(`
    CREATE TABLE IF NOT EXISTS expenses (
      id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      timestamp TEXT NOT NULL,
      category TEXT NOT NULL,
      receiptImagePath TEXT,
      rawOcrText TEXT,
      note TEXT,
      PRIMARY KEY (device_id, id)
    )
  `).run();
  await env.DB.prepare(`
    CREATE INDEX IF NOT EXISTS idx_expenses_device_time
    ON expenses (device_id, timestamp)
  `).run();
  await env.DB.prepare(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  `).run();
  await env.DB.prepare(`
    CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  `).run();
}

function randomHex(bytes) {
  const arr = new Uint8Array(bytes);
  crypto.getRandomValues(arr);
  return [...arr].map((value) => value.toString(16).padStart(2, '0')).join('');
}

async function sha256(text) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((value) => value.toString(16).padStart(2, '0')).join('');
}

function cleanUsername(raw) {
  const name = String(raw ?? '').trim().toLowerCase();
  return /^[a-z0-9_]{3,24}$/.test(name) ? name : null;
}

function bearerToken(request) {
  const header = request.headers.get('Authorization') || '';
  if (!header.startsWith('Bearer ')) return null;
  const token = header.slice(7).trim();
  return /^[a-f0-9]{64}$/.test(token) ? token : null;
}

async function requireUser(env, request) {
  const token = bearerToken(request);
  if (!token) return null;
  return env.DB.prepare(
    `SELECT u.id AS userId, u.username AS username
     FROM sessions s
     JOIN users u ON u.id = s.user_id
     WHERE s.token = ?`,
  ).bind(token).first();
}

async function adoptDeviceLedger(env, userId, deviceOwner) {
  if (!deviceOwner || deviceOwner === userId) return;
  if (!/^[A-Za-z0-9_-]{8,80}$/.test(deviceOwner)) return;
  await env.DB.prepare(
    `INSERT INTO expenses (id, device_id, title, amount, timestamp, category, receiptImagePath, rawOcrText, note)
     SELECT id, ?1, title, amount, timestamp, category, receiptImagePath, rawOcrText, note
     FROM expenses
     WHERE device_id = ?2
     ON CONFLICT(device_id, id) DO NOTHING`,
  ).bind(userId, deviceOwner).run();
}

async function openSession(env, userId, username, deviceOwner) {
  const token = randomHex(32);
  await env.DB.prepare(
    'INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)',
  ).bind(token, userId, new Date().toISOString()).run();
  await adoptDeviceLedger(env, userId, deviceOwner);
  return { token, userId, username };
}

function listStmt(env, owner) {
  return env.DB.prepare(
    `SELECT id, title, amount, timestamp, category, receiptImagePath, rawOcrText, note
     FROM expenses
     WHERE device_id = ?
     ORDER BY timestamp DESC`,
  ).bind(owner);
}

function cleanItem(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const id = String(raw.id ?? '').trim();
  const title = String(raw.title ?? '').trim();
  const amount = Number(raw.amount);
  if (!/^[A-Za-z0-9_-]{1,80}$/.test(id)) return null;
  if (!title || title.length > 180) return null;
  if (!Number.isFinite(amount) || amount < 0 || amount > 1e12) return null;
  const timestamp = String(raw.timestamp ?? '');
  if (Number.isNaN(Date.parse(timestamp))) return null;
  const category = String(raw.category ?? 'other').slice(0, 40);
  const clip = (value, max) => {
    if (value == null) return null;
    const text = String(value);
    return text.length > max ? text.slice(0, max) : text;
  };
  return {
    id,
    title,
    amount,
    timestamp,
    category,
    receiptImagePath: clip(raw.receiptImagePath, 500),
    rawOcrText: clip(raw.rawOcrText, 8000),
    note: clip(raw.note, 500),
  };
}

function upsertStmt(env, owner, item) {
  return env.DB.prepare(
    `INSERT INTO expenses (
       id, device_id, title, amount, timestamp, category, receiptImagePath, rawOcrText, note
     ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
     ON CONFLICT(device_id, id) DO UPDATE SET
       title = excluded.title,
       amount = excluded.amount,
       timestamp = excluded.timestamp,
       category = excluded.category,
       receiptImagePath = excluded.receiptImagePath,
       rawOcrText = excluded.rawOcrText,
       note = excluded.note`,
  ).bind(
    item.id,
    owner,
    item.title,
    item.amount,
    item.timestamp,
    item.category,
    item.receiptImagePath,
    item.rawOcrText,
    item.note,
  );
}

async function readItems(env, owner) {
  const result = await listStmt(env, owner).all();
  return result.results ?? [];
}

export async function onRequest(context) {
  const { request, env } = context;
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS });
  }

  if (!env.DB) {
    return json(
      {
        ok: false,
        engine: 'cloudflare-d1',
        error: 'D1 binding DB is missing. Create the database and set database_id in wrangler.toml.',
      },
      503,
    );
  }

  const url = new URL(request.url);
  const parts = url.pathname.replace(/^\/api\/?/, '').split('/').filter(Boolean);

  try {
    await ensureSchema(env);

    if (parts[0] === 'health') {
      return json({ ok: true, engine: 'cloudflare-d1' });
    }

    if (parts[0] === 'auth') {
      if (parts[1] === 'me' && request.method === 'GET') {
        const user = await requireUser(env, request);
        if (!user) return json({ error: 'unauthorized' }, 401);
        return json({ userId: user.userId, username: user.username });
      }

      if (parts[1] === 'logout' && request.method === 'POST') {
        const token = bearerToken(request);
        if (token) {
          await env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(token).run();
        }
        return json({ ok: true });
      }

      if (request.method === 'POST' && (parts[1] === 'login' || parts[1] === 'register')) {
        const body = await request.json();
        const username = cleanUsername(body?.username);
        const password = String(body?.password ?? '');
        if (!username) return json({ error: 'invalid_username' }, 400);
        if (password.length < 6 || password.length > 72) return json({ error: 'weak_password' }, 400);
        const deviceOwner = deviceId(request);

        if (parts[1] === 'register') {
          const userId = `usr_${randomHex(8)}`;
          const salt = randomHex(16);
          const passwordHash = await sha256(`${salt}:${password}`);
          try {
            await env.DB.prepare(
              'INSERT INTO users (id, username, password_hash, salt, created_at) VALUES (?, ?, ?, ?, ?)',
            ).bind(userId, username, passwordHash, salt, new Date().toISOString()).run();
          } catch (error) {
            const text = error instanceof Error ? error.message : String(error);
            if (text.toLowerCase().includes('unique')) {
              return json({ error: 'username_taken' }, 409);
            }
            throw error;
          }
          return json(await openSession(env, userId, username, deviceOwner));
        }

        const row = await env.DB.prepare(
          'SELECT id, password_hash, salt FROM users WHERE username = ?',
        ).bind(username).first();
        if (!row) return json({ error: 'invalid_login' }, 401);
        const passwordHash = await sha256(`${row.salt}:${password}`);
        if (passwordHash !== row.password_hash) return json({ error: 'invalid_login' }, 401);
        return json(await openSession(env, row.id, username, deviceOwner));
      }

      return json({ error: 'Not found' }, 404);
    }

    if (parts[0] !== 'expenses') {
      return json({ error: 'Not found' }, 404);
    }

    const user = await requireUser(env, request);
    if (!user) return json({ error: 'unauthorized' }, 401);
    const owner = user.userId;

    if (request.method === 'GET' && parts.length === 1) {
      return json({ items: await readItems(env, owner) });
    }

    if (request.method === 'POST' && parts[1] === 'sync') {
      const body = await request.json();
      const ops = Array.isArray(body?.ops) ? body.ops : null;
      if (!ops) return json({ error: 'Expected { ops: [] }' }, 400);
      if (ops.length > 200) return json({ error: 'Too many operations' }, 413);

      const statements = [];
      for (const op of ops) {
        if (!op || typeof op !== 'object') {
          return json({ error: 'Invalid operation' }, 400);
        }
        if (op.op === 'clear') {
          statements.push(
            env.DB.prepare('DELETE FROM expenses WHERE device_id = ?').bind(owner),
          );
          continue;
        }
        if (op.op === 'delete') {
          const id = String(op.id ?? '');
          if (!/^[A-Za-z0-9_-]{1,80}$/.test(id)) {
            return json({ error: 'Invalid delete id' }, 400);
          }
          statements.push(
            env.DB.prepare('DELETE FROM expenses WHERE device_id = ? AND id = ?').bind(owner, id),
          );
          continue;
        }
        if (op.op === 'upsert') {
          const item = cleanItem(op.item);
          if (!item) return json({ error: 'Invalid expense' }, 400);
          statements.push(upsertStmt(env, owner, item));
          continue;
        }
        return json({ error: 'Unknown operation' }, 400);
      }

      if (statements.length > 0) {
        await env.DB.batch(statements);
      }
      return json({ items: await readItems(env, owner) });
    }

    return json({ error: 'Not found' }, 404);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'D1 request failed';
    return json({ error: message }, 500);
  }
}
