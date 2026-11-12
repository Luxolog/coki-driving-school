# Ekhaya Development Assistant

This repository has a scheduled, safe inspection workflow at `.github/workflows/development-assistant.yml`.

## Schedule
- Tuesday and Friday at 09:00 South Africa time (07:00 UTC).
- A run can also be started manually from GitHub Actions using **Ekhaya Development Assistant**.

## Safety boundaries
- The workflow has `contents: read` permissions only.
- It does not deploy, edit source files, commit, create pull requests, or write to Appwrite.
- Appwrite checks are read-only: health endpoint and TablesDB table listing.
- No production data is read from individual rows.
- The workflow does not guarantee protection against Appwrite's Free-plan inactivity policy.

## Configure Appwrite access
In this repository, open **Settings → Secrets and variables → Actions → New repository secret** and add:

- Name: `APPWRITE_API_KEY`
- Value: a project API key created in Appwrite with only the read scopes needed to list TablesDB tables (database/table read access).

Use a separate, project-scoped key in each repository. Never put the key in source code, workflow YAML, issues, or chat. If the secret is absent, code checks still run and the Appwrite check is marked as skipped.

## Reviewing results
Open **Actions → Ekhaya Development Assistant** and inspect the run summary and logs. A failed check is a report for human review; it does not trigger an automatic production change.
