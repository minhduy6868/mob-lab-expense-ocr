-- Cloudflare D1 schema for VKU Ledger.
-- Apply with:
--   npx wrangler d1 execute vku-expense-db --remote --file=schema.sql

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
);

CREATE INDEX IF NOT EXISTS idx_expenses_device_time
  ON expenses (device_id, timestamp);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL
);
