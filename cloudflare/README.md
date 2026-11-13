# Coki Cloudflare pilot

This folder is the **non-production Cloudflare pilot scaffold** for Coki Driving School. It does not replace Appwrite yet and contains no live credentials or learner data.

## Architecture

- Existing root HTML, question bank and diagrams remain the learner-facing site.
- Cloudflare Pages will host the static site after a preview project is configured.
- A Cloudflare Worker will provide the API.
- Cloudflare D1 will store pilot data.
- A Cron Trigger will run retention cleanup after the cleanup policy is approved and implemented.
- GitHub remains the source of truth.

## Safety status

- No production domain is changed.
- No Appwrite resources or data are modified.
- No paid Cloudflare plan is required for this scaffold.
- The D1 schema is a proposed migration of the five existing Appwrite tables, with additional authentication/session and timed-attempt tables.
- Do not put real learner data into the pilot until authentication, authorization, backup/restore and POPIA controls have passed review.

## Files

- `schema.sql`: initial D1 schema.
- `worker/src/index.js`: minimal API health endpoint only; no learner/admin API is exposed yet.
- `wrangler.toml.example`: configuration template. Replace the D1 database ID only after creating a separate pilot database in Cloudflare.

## Cloudflare setup (manual account step)

1. Sign in to the Cloudflare account that Ekhaya Technologies will own.
2. Confirm the account is on the Free plan. Do not select Workers Paid or enable automatic upgrades.
3. Create a D1 database named `coki-pilot`.
4. Record its database ID and replace `REPLACE_WITH_COKI_PILOT_D1_DATABASE_ID` in a copy of the Wrangler configuration.
5. Apply the schema to the **pilot database only** using Wrangler:
   `npx wrangler d1 execute coki-pilot --remote --file=cloudflare/schema.sql`
6. Deploy the Worker from the repository root using the completed configuration:
   `npx wrangler deploy --config cloudflare/wrangler.toml`
7. Test the `/health` endpoint. This endpoint checks the Worker and D1 connectivity only; it does not prove authentication or application readiness.
8. Set up a separate Cloudflare Pages preview project for the existing static site. Do not attach the production Coki domain yet.

## GitHub Actions secrets (only when automated deployment is approved)

Use repository secrets, never source files:

- `CLOUDFLARE_API_TOKEN`: scoped to the Coki pilot resources only.
- `CLOUDFLARE_ACCOUNT_ID`: the Cloudflare account ID.

The API token should have only the permissions required for the selected deployment workflow. Do not use a Global API Key.

## Pilot acceptance tests before migration

1. A learner can authenticate without exposing passwords or ID numbers.
2. A learner cannot read another learner's records or any answer key.
3. An administrator can create, suspend and extend a learner's access, with audit records.
4. Daily time use is enforced by the server, not only by a browser timer.
5. A test deadline is server-authoritative and cannot be reset by reload, clock changes or another tab.
6. Retaking one test replaces only that learner's result for that test; results for other tests remain unchanged.
7. Cleanup removes only records covered by an approved retention policy.
8. Backup and restore are tested before any real learner data is introduced.

## Data protection

The current Appwrite learner table stores a full name, a lookup value and the last four ID digits. The Cloudflare design must not store a full South African ID number. Use a server-side keyed HMAC for ID lookup, and keep the key in a secret binding, not in D1 or Git.

D1 region and cross-border processing implications must be assessed against POPIA before production use. Keep the pilot on synthetic data until this assessment and the retention policy are signed off.

## Not yet implemented

This scaffold intentionally does not claim to provide production authentication, password reset, admin CRUD, timed-test enforcement, scheduled deletion, email delivery, or production backups. Those are the next implementation stages after the pilot database and Cloudflare account are available.
