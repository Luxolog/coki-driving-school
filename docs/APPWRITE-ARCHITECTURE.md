# Coki Appwrite Architecture

## Decision
Coki uses Appwrite Cloud as its managed backend. The existing static Coki site remains the frontend for the first implementation. Appwrite is a separate project from Ekhaya's infrastructure.

## Services
- Appwrite Auth: learner and administrator identities/sessions.
- Appwrite TablesDB: learner profiles, access grants, daily usage, latest test results, and admin audit events.
- Appwrite Functions: ID-based login, provisioning, time accounting, test-result upserts, admin operations, and scheduled cleanup.
- Existing GitHub Pages frontend initially; Appwrite Sites can be considered later if the frontend needs server-side rendering or a single hosting platform.

## Identity and access
- Learner login form asks for South African ID number and password.
- Never use an ID number as a password or expose it in a URL.
- The browser must not query learner records by ID directly.
- A server function normalizes the ID, calculates a keyed HMAC lookup value, finds the Appwrite user, validates credentials, and establishes an Appwrite session. The HMAC secret and Appwrite API key exist only in Function environment variables.
- Learner profiles store the Appwrite user ID and keyed ID lookup value; avoid storing a plain ID unless a documented operational requirement is approved. Show only the last four digits in admin lists where possible.
- Admin accounts are provisioned manually by the project owner. The admin interface is a separate route and checks an administrator role server-side on every privileged operation. No public admin signup.
- All client-facing database access is denied by default. Functions verify the caller's session and role before reading or writing data.

## Data model (TablesDB)
Create database `coki_main` and these tables:

### learners
- `userId` (string, unique): Appwrite Auth user ID
- `idLookup` (string, unique): HMAC-SHA256 of normalized ID number
- `idLast4` (string)
- `fullName` (string)
- `status` (enum: active, suspended, completed)
- `createdAt` (datetime)
- `updatedAt` (datetime)

### access_grants
- `learnerId` (string, unique per active grant)
- `startsAt` (datetime)
- `expiresAt` (datetime)
- `daysGranted` (integer; initial default 4)
- `dailyLimitSeconds` (integer; default 10800)
- `addedSeconds` (integer; default 0; admin-approved extension)
- `status` (enum: active, expired, revoked)
- `updatedBy` (string; admin user ID)
- `updatedAt` (datetime)

### daily_usage
- `learnerId` (string)
- `dayKey` (string; South African date YYYY-MM-DD)
- `usedSeconds` (integer)
- `lastHeartbeatAt` (datetime)
- `activeSessionId` (string)
- `updatedAt` (datetime)
- Unique index: learnerId + dayKey

### latest_test_results
- `learnerId` (string)
- `testNumber` (integer 1–5)
- `score` (integer)
- `totalQuestions` (integer)
- `correctCount` (integer)
- `incorrectCount` (integer)
- `completedAt` (datetime)
- `expiresAt` (datetime)
- Unique index: learnerId + testNumber

### admin_audit
- `adminUserId` (string)
- `action` (string)
- `targetLearnerId` (string)
- `details` (string / JSON)
- `createdAt` (datetime)

## Access and time policy
- Initial access begins when an administrator activates the learner, not when the account is merely created.
- Access runs for four consecutive calendar days in `Africa/Johannesburg`; each calendar day allows 10,800 seconds (3 hours).
- A daily usage row is keyed by the South African date. The next local date starts with a fresh allowance automatically; no browser clock or client-side reset is trusted.
- A server function starts/renews a usage heartbeat every 30 seconds. It credits only bounded server-measured intervals (maximum 45 seconds per heartbeat), and denies access when the daily allowance or four-day grant expires.
- The frontend must pause the study/test workspace when the server denies a heartbeat. Refreshing or opening another tab does not reset the server-side usage.
- Admin extensions are audited and update the grant end time and/or an explicitly approved additional time allowance. No client can alter grants or usage rows.
- The initial rule is 3 hours per calendar day for 4 consecutive days. If Coki later wants rolling 24-hour windows instead, that is a policy change.

## Test result policy
- Save only the latest result for each learner and test number.
- Upsert by the unique key (learnerId, testNumber): a new Test 2 replaces only the old Test 2 result; Test 1 and other tests remain untouched.
- Set expiresAt to completedAt + 5 days.
- An hourly scheduled Function deletes expired results. Result reads also exclude expired rows, so cleanup timing does not expose expired results.
- Store score, total, correct, incorrect, and completion timestamp. Do not store full answer sheets unless separately approved.

## Appwrite Functions
1. `learner-login`: ID + password authentication; generic failure message and rate limiting.
2. `admin-provision-learner`: create Auth user and profile; set initial grant only after admin activation.
3. `session-start`: verify learner session and grant; initialize daily usage.
4. `usage-heartbeat`: server-authoritative time accounting and lockout decision.
5. `save-test-result`: validate caller, test number and score payload; upsert latest result.
6. `admin-list-learners`: admin-only learner and usage overview.
7. `admin-extend-access`: admin-only access/time extension with audit event.
8. `admin-learner-results`: admin-only result history/latest results.
9. `cleanup-expired-results`: scheduled hourly deletion of expired results.

## Security and POPIA controls
- Appwrite API keys and HMAC/encryption secrets are Function secrets only; never commit them to Git.
- Restrict database/table permissions; client access should go through authenticated functions until row-level access rules are fully tested.
- Enforce admin authorization in Functions, not by hiding admin links in the browser.
- Rate-limit ID login attempts and use generic errors to prevent account enumeration.
- Do not log passwords, full ID numbers, session secrets, or test answers.
- Use HTTPS, least-privilege API key scopes, audit admin actions, and define a retention/deletion process for learner profiles.
- Confirm Coki's POPIA notice, lawful basis, operator arrangements, and retention policy before collecting real learner ID numbers.

## Frontend integration
- Add distinct learner and admin login pages.
- Learner dashboard shows access expiry, today's remaining time, and Test 1–5 status.
- Admin dashboard becomes live data, with learner creation, activation, suspension, time extension, results and audit trail.
- Existing study pages and test content remain in place; protect test entry points with the authenticated learner session and server time checks.

## Rollout sequence
1. Create Appwrite Cloud project and record endpoint/project ID.
2. Create database/tables/indexes and least-privilege permissions.
3. Deploy Functions and set secrets.
4. Create the first admin account securely.
5. Connect login pages and learner dashboard.
6. Connect test player result submission and heartbeat enforcement.
7. Replace admin prototype with live admin operations.
8. Test lockout, midnight reset, 4-day expiry, per-test replacement, 5-day deletion, and unauthorized access before launch.

## Required project configuration (do not commit secrets)
Frontend public config: `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`.
Function secrets: Appwrite API key with minimum scopes, `ID_LOOKUP_HMAC_SECRET`, and any session/login signing secret required by the selected implementation.
