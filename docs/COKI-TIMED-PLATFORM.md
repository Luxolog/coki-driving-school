# Coki Timed Digital K53 Platform — Implementation Notes

## Objective
Build a Coki-branded timed learner assessment platform in this repository without changing the Inganathi K53 repository.

## Agreed learner experience
- Learner signs in with Learner ID or email.
- Learner sees an assigned test and the allocated time before beginning.
- Countdown timer, saved answers, time warnings, and automatic submission at expiry.
- Results and progress are available according to Coki's access settings.

## Agreed administrator experience
- Manage learner accounts and identify each learner by ID/email.
- Allocate or change test duration.
- Monitor learner activity, answered-question progress, and results.
- Extend an active session and record the reason, admin, time, and minutes added.
- Pause/revoke a session where authorized.
- Export progress/results.

## Security and integrity requirements
- The browser timer is only a display. The authoritative deadline must be stored and enforced server-side.
- Reloading, opening another tab, changing the device clock, or modifying browser storage must not reset/extend a session.
- Learners must not be able to read answer keys or administer their own accounts.
- Apply least-privilege authorization and row-level access policies to learner/session data.
- Record administrator time changes in an audit log.
- Do not use real learner ID numbers in test/demo data.

## Proposed cost-conscious stack
- Existing GitHub repository and GitHub Pages for the static frontend/demo.
- React + Vite for the evolving learner/admin UI (or keep the existing static pages while migrating incrementally).
- Supabase free tier for initial development: Postgres, Auth, and server-side functions/RPC as needed.
- Reassess hosting and service limits before production launch; free-tier availability and limits can change.

## Delivery stages
1. Preserve existing Coki manual and knowledge pages; inspect and reuse existing question content.
2. Add a sample-data admin dashboard UI for learner list, progress, time allocation, and time extension.
3. Add authentication and database schema for learners, question sets, attempts, answers, time allocations, and audit events.
4. Implement server-authoritative attempt start/deadline, autosave, expiry submission, and extension logic.
5. Connect UI to backend; add role-based admin access and secure policies.
6. Test edge cases (reload, offline/reconnect, duplicate tabs, clock manipulation, expiry, extensions) and deploy.

## Important status
This file is a development plan, not a claim that backend authentication, live monitoring, or secure timer enforcement already exists. The sample dashboard must be clearly marked as a prototype until connected to the backend.
