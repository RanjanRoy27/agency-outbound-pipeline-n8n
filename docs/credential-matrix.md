# Credential and Data Setup

## Principle

The repository is intentionally safe to share. It contains no API keys, webhook secrets, database passwords, mailbox credentials, CRM tokens, or real lead records. n8n credentials and environment variables are the control plane for live operation; the JSON files contain only credential references and non-secret configuration expressions.

| Service | n8n setup | Used by | Pilot mode | Live-pilot guardrail |
|---|---|---|---|---|
| PostgreSQL | Create a Postgres credential named `Agency Outbound Postgres`; apply `schema/schema.sql` first. | All workflows | Fixture and live | Use a separate database/schema from production CRM data; least-privilege user should only access `agency_outbound`. |
| Apify | Create a Header Auth credential or configure an environment secret for the Apify token; set an approved Actor ID. | Workflow 00 | Live only | Run against a small, approved source and `maxItems <= 25`; observe Actor usage before increasing frequency. |
| Apollo | Create an API-key/header credential and approve the People Enrichment endpoint. | Workflow 01 | Live only | Start with 5–10 rows; record observed credits; do not enable waterfall enrichment until credit impact is understood. |
| Hunter | Create a Header Auth credential containing `X-API-KEY`; use `api.hunter.io/v2/domain-search`. | Workflow 01 | Live only | Use as fallback only; cap the monthly search budget and review each returned contact. |
| Gemini | Create a Header Auth credential containing `x-goog-api-key`; set `GEMINI_MODEL=gemini-3.5-flash-lite`. | Workflows 02 and 04 | Fixture and live | Keep prompts single-shot, temperature low, JSON-mode enabled, and output token limits small. Human-review generated copy before sending. |
| Slack | Store the incoming webhook URL as a secret or n8n credential. | Workflow 04 | Live only | Send only operational alerts; never include full raw reply text or unnecessary PII in Slack. |
| Gmail sandbox | Create one Gmail OAuth2 credential only if a controlled demo send is required. | Workflow 03 | Optional live demo | Keep `DRY_RUN=true` until a human has verified the recipient, subject, body, and account. Never treat this as a mailbox swarm. |
| CRM destination | Leave as Postgres adapter for the concept project. | Workflow 04 | Fixture and live | Replace only the adapter node after a real CRM and field mapping are approved. |

## Recommended credential names

Credential names are deliberately generic enough to avoid disclosing account identifiers in exported JSON: `Agency Outbound Postgres`, `Apollo API Key`, `Hunter API Key`, `Gemini API Key`, `Sandbox Gmail OAuth2`, and `Slack Operational Webhook`.

## Live pilot sequence

The safe sequence is to run the database migration, import all five workflows, keep `PILOT_MODE=fixture` and `DRY_RUN=true`, execute the test cases, and review the audit tables. Next, switch only Workflow 00 to live mode for a small signal sample. Then enable live enrichment for 5–10 rows and inspect the resulting evidence and provider usage. Only after those checks should live homepage research, reply classification, and the optional one-mailbox sandbox message be enabled.

## Data handling

Use reserved `.example` domains and synthetic names for fixture data. For live mode, store only the minimum fields required for the approved pilot, define a retention period, avoid posting raw reply content to Slack, and restrict database access to the automation operator. Exported workflow JSON should be treated as shareable only after checking that no imported cURL headers or credential values were embedded.
