-- Coki Driving School — Cloudflare D1 pilot schema
-- Synthetic/test data only until security, POPIA, backup and retention reviews pass.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS learners (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  full_name TEXT NOT NULL,
  id_lookup_hmac TEXT UNIQUE,
  id_last4 TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','completed','archived')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Passwords are never stored in plaintext. Hashing must be performed server-side
-- with a deliberately slow password KDF before inserting a credential.
CREATE TABLE IF NOT EXISTS learner_credentials (
  learner_id TEXT PRIMARY KEY REFERENCES learners(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  hash_version TEXT NOT NULL,
  must_change_password INTEGER NOT NULL DEFAULT 1 CHECK (must_change_password IN (0,1)),
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS administrators (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  hash_version TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner','admin')),
  enabled INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  subject_type TEXT NOT NULL CHECK (subject_type IN ('learner','administrator')),
  subject_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  revoked_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_sessions_subject ON sessions(subject_type, subject_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expiry ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS access_grants (
  id TEXT PRIMARY KEY,
  learner_id TEXT NOT NULL REFERENCES learners(id) ON DELETE CASCADE,
  starts_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  days_granted INTEGER NOT NULL CHECK (days_granted BETWEEN 1 AND 30),
  daily_limit_seconds INTEGER NOT NULL CHECK (daily_limit_seconds BETWEEN 1 AND 86400),
  added_seconds INTEGER NOT NULL DEFAULT 0 CHECK (added_seconds BETWEEN 0 AND 86400),
  status TEXT NOT NULL CHECK (status IN ('active','paused','revoked','expired')),
  updated_by TEXT NOT NULL REFERENCES administrators(id),
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_access_grants_learner ON access_grants(learner_id, status, expires_at);

CREATE TABLE IF NOT EXISTS daily_usage (
  learner_id TEXT NOT NULL REFERENCES learners(id) ON DELETE CASCADE,
  day_key TEXT NOT NULL,
  used_seconds INTEGER NOT NULL DEFAULT 0 CHECK (used_seconds >= 0),
  last_heartbeat_at TEXT,
  active_session_id TEXT,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (learner_id, day_key)
);

CREATE TABLE IF NOT EXISTS timed_attempts (
  id TEXT PRIMARY KEY,
  learner_id TEXT NOT NULL REFERENCES learners(id) ON DELETE CASCADE,
  test_number INTEGER NOT NULL CHECK (test_number BETWEEN 1 AND 5),
  started_at TEXT NOT NULL,
  deadline_at TEXT NOT NULL,
  submitted_at TEXT,
  status TEXT NOT NULL CHECK (status IN ('in_progress','submitted','expired','cancelled')),
  answers_json TEXT NOT NULL DEFAULT '{}',
  extension_seconds INTEGER NOT NULL DEFAULT 0 CHECK (extension_seconds >= 0),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_attempts_learner_test ON timed_attempts(learner_id, test_number, status);

-- Exactly one current result per learner and test. An upsert replaces that test's
-- previous result without touching results for any other test.
CREATE TABLE IF NOT EXISTS latest_test_results (
  learner_id TEXT NOT NULL REFERENCES learners(id) ON DELETE CASCADE,
  test_number INTEGER NOT NULL CHECK (test_number BETWEEN 1 AND 5),
  score INTEGER NOT NULL CHECK (score >= 0),
  total_questions INTEGER NOT NULL CHECK (total_questions > 0),
  correct_count INTEGER NOT NULL CHECK (correct_count >= 0),
  incorrect_count INTEGER NOT NULL CHECK (incorrect_count >= 0),
  completed_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  PRIMARY KEY (learner_id, test_number)
);

CREATE TABLE IF NOT EXISTS admin_audit (
  id TEXT PRIMARY KEY,
  admin_user_id TEXT NOT NULL REFERENCES administrators(id),
  action TEXT NOT NULL,
  target_learner_id TEXT REFERENCES learners(id) ON DELETE SET NULL,
  details_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created ON admin_audit(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target ON admin_audit(target_learner_id, created_at);

-- Retention is intentionally not automated in this first migration.
-- Implement cleanup only after the owner approves the final retention schedule.
