# Pilot Runbook

## Objective

Validate the pipeline’s state transitions, provider fallbacks, AI output quality, cost logging, and reply handoff on a small controlled sample. The pilot is not an invitation to start bulk outbound sending. It is an evidence-gathering exercise that keeps `DRY_RUN=true` until the operator explicitly approves the one-mailbox sandbox branch.

## Phase 0 — Prepare the environment

Create or select a non-production PostgreSQL database. Apply `schema/schema.sql`. Confirm that the `agency_outbound` schema exists and that the five mock mailbox rows use reserved `.example` domains. Import the five JSON files through the n8n editor. If the n8n instance supports its public API, the API path can be added later; the editor import is the default because it is easy to inspect and does not require an API key.

Configure one Postgres credential named `Agency Outbound Postgres`. Do not enter Apollo, Hunter, Apify, Gemini, Slack, or Gmail credentials yet. Set `PILOT_MODE=fixture` and `DRY_RUN=true`. Run the structural validator locally before importing:

```bash
python3 generator/validate_workflow.py workflows/*.json
```

## Phase 1 — Prove the fixture path

Run Workflow 00 manually and confirm that the three fixture signals appear once in `signal_events`. Run Workflow 01 and inspect the three prospect rows. Run Workflow 02 and inspect the research and hook rows. Run Workflow 03 and confirm that cap-aware queue rows and audit events are created without a Gmail send. Use Workflow 04’s webhook URL with a synthetic payload such as:

```json
{
  "raw_reply_text": "Yes, this is interesting. Can we talk next week?",
  "lead_name": "Alex Morgan",
  "lead_email": "alex.morgan@example.com"
}
```

Confirm that an interested reply produces one CRM adapter row and an SLA audit/alert attempt. Execute the negative and malformed payload tests as well.

## Phase 2 — Review evidence and reset

Record the n8n execution IDs, row counts, and any `audit_log` entries. Check that no real recipient address, API key, webhook secret, or non-`.example` fixture domain appears in the repository. Reset fixture tables or use a fresh pilot database before live data is introduced.

## Phase 3 — Enable one live provider at a time

Set `PILOT_MODE=live` only for the workflow under test. Start with Workflow 00 and a small, approved Apify Actor input. Keep the batch limit at 5–10 rows and observe Actor usage. If the Actor returns results that do not normalize cleanly, stop and adjust the mapping rather than increasing volume.

Next, configure Apollo and run Workflow 01 against the captured sample. Inspect the Apollo response shape, returned email, credit usage, and the `resolution_tier`. If Apollo does not resolve a contact, enable Hunter as the fallback and verify that the monthly credit budget is not exceeded. Do not enable Apollo waterfall enrichment in the first pass because its asynchronous webhook behavior and account-specific credit usage require a separate test.

Only after the data quality is acceptable should Workflow 02 call Gemini live. Review 5–10 generated summaries and hooks manually. Reject any output that makes unsupported claims or implies knowledge not present on the company homepage. Keep `GEMINI_MODEL` configurable and capture usage metadata when returned.

## Phase 4 — Reply and CRM handoff pilot

Keep Workflow 04 on the simulated reply webhook. Post three synthetic replies representing interested, not interested, and out-of-office cases. Confirm that only the interested case creates a CRM adapter row. Verify that Slack contains operationally useful alert text without raw reply content or unnecessary personal data.

## Stop conditions

Stop the pilot immediately if a provider key is rejected, a provider returns unexpected personal data, a deduplication constraint fails, a workflow writes rows without a traceable state transition, a Slack message leaks raw sensitive content, or any branch can send without `DRY_RUN=false` and explicit operator approval. Stop if cost usage is not observable.

## Evidence packet

The final pilot evidence packet should include the validator output, the schema migration result, one n8n execution ID per workflow, counts from each phase table, one Apollo/Hunter usage observation, five reviewed AI hooks, a cap-enforcement example, three reply-classification examples, and a written list of what remains simulated. This packet is stronger than a canvas screenshot because it proves behavior, not just configuration.
