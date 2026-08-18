# Setup Guide

## 1. Prerequisites

You need an n8n instance, a PostgreSQL database that the n8n instance can reach, and a local shell with Python 3.11 or later. Live mode additionally requires accounts and approved keys for Apify, Apollo, Hunter, Gemini, and Slack. Gmail is optional and should be limited to one sandbox mailbox.

## 2. Prepare the database

Create a non-production database or schema and run:

```bash
psql "$DATABASE_URL" -f schema/schema.sql
```

Confirm the expected objects:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'agency_outbound'
ORDER BY table_name;
```

You should see the phase tables plus `audit_log`, `integration_usage`, and `workflow_runs`. The seed inserts five mock mailbox rows and three `.example` signal rows.

## 3. Generate and validate the workflows

From the repository root:

```bash
python3 generator/build_workflow.py
python3 generator/validate_workflow.py workflows/*.json
```

Do not import a workflow that fails validation. If you edit a workflow manually in n8n and export it, rerun the validator against the exported JSON after removing any secret headers.

## 4. Import into n8n

In n8n, open the Workflows area and use **Import from File** for each file in `workflows/`. Import them into a dedicated project or folder named `Agency Outbound — Concept`. Keep all five workflows inactive until the fixture pass is complete.

After import, open the Postgres nodes and bind the `Agency Outbound Postgres` credential. The generated JSON uses a placeholder credential reference so it can be safely shared; n8n will require a local credential binding on the target instance.

If an imported node shows a provider placeholder, do not paste the key into the URL or JSON file. Create the corresponding n8n credential or instance secret and keep the workflow expression pointed at that secret.

## 5. Configure the safe defaults

Set the n8n environment or equivalent configuration to:

```text
PILOT_MODE=fixture
DRY_RUN=true
GEMINI_MODEL=gemini-3.5-flash-lite
```

The provider-specific placeholders in `config/pilot.env.example` are not secrets and must be replaced only in the target environment. The fixture branch intentionally uses reserved `.example` domains and does not need external provider credentials.

## 6. Run the fixture pipeline

Run the workflows manually in order. After each execution, inspect the relevant table:

```sql
SELECT * FROM agency_outbound.signal_events ORDER BY id DESC;
SELECT * FROM agency_outbound.prospects_enriched ORDER BY id DESC;
SELECT * FROM agency_outbound.personalization_hooks ORDER BY id DESC;
SELECT * FROM agency_outbound.send_queue ORDER BY id DESC;
SELECT * FROM agency_outbound.replies_inbox ORDER BY id DESC;
SELECT * FROM agency_outbound.crm_leads ORDER BY id DESC;
SELECT * FROM agency_outbound.audit_log ORDER BY id DESC;
```

A fixture run should create deterministic rows and should not send email. The optional Gmail node is behind `DRY_RUN=false`.

## 7. Test the reply webhook

Find the production webhook URL shown by the `Receive Simulated Reply` node after the workflow is saved. Use a synthetic payload:

```bash
curl -X POST "$N8N_REPLY_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "raw_reply_text": "Yes, this is interesting. Can we talk next week?",
    "lead_name": "Alex Morgan",
    "lead_email": "alex.morgan@example.com"
  }'
```

Then query `replies_inbox`, `crm_leads`, and `audit_log`. Repeat with an out-of-office reply and a malformed payload.

## 8. Stage live credentials one provider at a time

When fixture tests pass, create the provider credentials described in `docs/credential-matrix.md`. Switch `PILOT_MODE=live` only for the workflow being tested. Start with 5–10 rows. For Apify, use an approved Actor ID and a small input. For Apollo, inspect the current response shape and record credits. For Hunter, leave the call as a fallback and enforce the monthly credit budget. For Gemini, review every generated hook. For Slack, send only operational metadata.

Do not activate all schedule triggers at once. Use manual runs for the first sample, then enable one schedule at a time after reviewing `integration_usage` and `audit_log`.

## 9. Optional n8n REST/API deployment

Once the workflow JSON is stable, the operator may use the n8n public API or CLI documented by n8n for repeatable promotion. Keep the API key outside the repository and verify plan availability before relying on this path. The user-facing import workflow remains the fallback and the easiest demonstration route.

## 10. Resetting the pilot

For a clean fixture reset, use a new non-production database or truncate tables in foreign-key order. Do not truncate a database that contains live CRM or reply data. Preserve the evidence packet before resetting:

```bash
python3 generator/validate_workflow.py workflows/*.json > validation-output.txt
```

The evidence packet should include this file, execution IDs, row counts, and the real-versus-simulated matrix.
