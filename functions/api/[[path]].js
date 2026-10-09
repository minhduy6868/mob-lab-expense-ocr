/**
 * Cloudflare Pages Function backed by D1.
 * Routes:
 *   GET  /api/health
 *   GET  /api/expenses
 *   POST /api/expenses/sync   { ops: [{op,id?,item?}] }
 *
 * Rows are scoped by the X-Device-Id header so each install keeps its own ledger.
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Device-Id',
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

    if (parts[0] !== 'expenses') {
      return json({ error: 'Not found' }, 404);
    }

    const owner = deviceId(request);
    if (!owner) {
      return json({ error: 'Missing or invalid X-Device-Id header' }, 400);
    }

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
