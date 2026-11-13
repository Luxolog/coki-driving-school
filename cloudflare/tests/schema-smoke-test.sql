-- Runs only against an ephemeral local SQLite database in CI.
.bail on
PRAGMA foreign_keys = ON;
.read cloudflare/schema.sql

-- Confirm expected tables exist.
SELECT CASE WHEN COUNT(*) = 9 THEN 'PASS: 9 tables created' ELSE RAISE(ABORT, 'Expected 9 tables') END
FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';

-- Seed synthetic administrator and learner records only.
INSERT INTO administrators (id,email,password_hash,password_salt,hash_version,role,enabled,created_at,updated_at)
VALUES ('admin-test','admin@example.invalid','not-a-real-hash','test-salt','test-only','owner',1,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z');

INSERT INTO learners (id,email,full_name,id_last4,created_at,updated_at)
VALUES ('learner-test','learner@example.invalid','Synthetic Learner','0000','2026-01-01T00:00:00Z','2026-01-01T00:00:00Z');

INSERT INTO latest_test_results (learner_id,test_number,score,total_questions,correct_count,incorrect_count,completed_at,expires_at)
VALUES
 ('learner-test',1,60,100,60,40,'2026-01-01T01:00:00Z','2026-03-02T01:00:00Z'),
 ('learner-test',2,70,100,70,30,'2026-01-01T02:00:00Z','2026-03-02T02:00:00Z');

-- Retaking Test 1 must replace Test 1 only.
INSERT INTO latest_test_results (learner_id,test_number,score,total_questions,correct_count,incorrect_count,completed_at,expires_at)
VALUES ('learner-test',1,85,100,85,15,'2026-01-02T01:00:00Z','2026-03-03T01:00:00Z')
ON CONFLICT(learner_id,test_number) DO UPDATE SET
 score=excluded.score,
 total_questions=excluded.total_questions,
 correct_count=excluded.correct_count,
 incorrect_count=excluded.incorrect_count,
 completed_at=excluded.completed_at,
 expires_at=excluded.expires_at;

SELECT CASE WHEN (SELECT score FROM latest_test_results WHERE learner_id='learner-test' AND test_number=1) = 85
 THEN 'PASS: Test 1 result replaced' ELSE RAISE(ABORT, 'Test 1 was not replaced') END;

SELECT CASE WHEN (SELECT score FROM latest_test_results WHERE learner_id='learner-test' AND test_number=2) = 70
 THEN 'PASS: Test 2 result preserved' ELSE RAISE(ABORT, 'Test 2 changed unexpectedly') END;

SELECT CASE WHEN (SELECT COUNT(*) FROM latest_test_results WHERE learner_id='learner-test') = 2
 THEN 'PASS: one result per learner/test' ELSE RAISE(ABORT, 'Unexpected result count') END;
