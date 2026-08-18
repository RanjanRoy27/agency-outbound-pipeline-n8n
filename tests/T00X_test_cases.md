# T00X Test Cases — Signal-to-CRM Outbound Pipeline

These tests are designed for the fixture mode first. They are deliberately framed as observable behavior with evidence in n8n execution data or the `agency_outbound` audit tables.

| ID | Workflow | Given | When | Then | Evidence |
|---|---|---|---|---|---|
| T001 | 00 Signal Trigger | The fixture source returns zero rows. | Run the signal ingestion workflow. | The execution succeeds, inserts zero signal rows, and records a successful run with `rows_seen=0`. | `workflow_runs`, execution log |
| T002 | 00 Signal Trigger | A signal already exists for the same normalized domain and signal type. | Run the workflow twice. | The second run does not create a duplicate. | Unique index on `signal_events`, row count |
| T003 | 00 Signal Trigger | Homepage fetch returns malformed HTML or a non-2xx response. | Run the workflow. | The run continues, the signal is retained, and tech detection falls back to `unknown_or_missing_tracking`. | `signal_events.signal_detail`, execution log |
| T004 | 00 Signal Trigger | Apify returns a quota or rate-limit error. | Run in live mode with a deliberately exhausted test key or mocked failure. | The workflow records the failure and does not terminate the whole pipeline. | `audit_log`, external node `continueOnFail` |
| T005 | 01 Waterfall Enrich | Apollo returns a valid person and email. | Process a new signal. | A tier-1 prospect is inserted with `email_source='apollo'`, `resolution_tier=1`, and the input signal becomes `enriched`. | `prospects_enriched`, `signal_events` |
| T006 | 01 Waterfall Enrich | Apollo returns no email; Hunter returns one email. | Process a new signal. | A tier-2 prospect is inserted with `email_source='hunter'` and a recorded fallback unit cost. | `prospects_enriched`, `integration_usage` |
| T007 | 01 Waterfall Enrich | Both Apollo and Hunter return no email. | Process a new signal. | A tier-0 unresolved prospect is inserted, no fake email is manufactured, and the signal still leaves `new`. | `prospects_enriched.email`, `resolution_tier` |
| T008 | 01 Waterfall Enrich | The domain is malformed and DNS MX lookup fails. | Process a new signal. | The prospect is retained with `mx_verified=false`; the run does not crash. | `prospects_enriched.mx_verified`, execution log |
| T009 | 02 AI Personalize | Homepage fetch fails. | Process an enriched prospect. | The prospect stays `status='new'`, and no incomplete hook is inserted. | `prospects_enriched`, `personalization_hooks` |
| T010 | 02 AI Personalize | Gemini returns a timeout or malformed JSON. | Process an enriched prospect. | The run records a review-required outcome or safe fallback and does not mark the prospect personalized without a valid hook. | execution log, `audit_log` |
| T011 | 02 AI Personalize | Company size is exactly the chosen offer-angle threshold. | Generate a hook. | The deterministic boundary rule returns the documented side of the threshold, not an LLM guess. | `personalization_hooks.offer_angle` |
| T012 | 02 AI Personalize | A valid single-shot Gemini response is returned. | Generate research and hook. | Both outputs are stored, the hook is `new`, and the prospect becomes `personalized`. | `personalization_hooks`, `prospects_enriched` |
| T013 | 03 Deliverability Sim | Every registered mailbox has `sent_today >= daily_cap`. | Run the workflow. | Hooks remain queued, no send row is created, and a capacity event is logged. | `audit_log`, `personalization_hooks` |
| T014 | 03 Deliverability Sim | The date crosses midnight and prior caps are stale. | Run the workflow on the next date. | All enabled mailboxes reset to zero exactly once. | `mailbox_registry.last_reset_date` |
| T015 | 03 Deliverability Sim | There are zero registered mailboxes. | Run the workflow. | The workflow fails loudly with an operator-readable error; hooks are not silently dropped. | execution error, hook status |
| T016 | 03 Deliverability Sim | `DRY_RUN=true`. | Process a new hook. | A queue row and audit record are created, but no Gmail send occurs. | `send_queue`, `audit_log` |
| T017 | 03 Deliverability Sim | `DRY_RUN=false` and one approved sandbox mailbox exists. | Process one hook. | Exactly one sandbox send attempt is made, and the queue row is marked `sent` only after the send path returns. | Gmail execution, `send_queue` |
| T018 | 04 CRM Sync | Webhook payload omits `raw_reply_text`. | POST the payload. | The reply is rejected, a validation audit row is written, and no CRM lead is created. | HTTP response, `audit_log` |
| T019 | 04 CRM Sync | Reply contains clear positive intent. | POST the reply payload. | The reply is classified `interested`, the CRM adapter row is created, and an SLA alert is attempted. | `replies_inbox`, `crm_leads`, Slack execution |
| T020 | 04 CRM Sync | Classifier returns an unexpected label. | Process the reply. | The classification is normalized to `objection`; the workflow does not crash. | `replies_inbox.classification` |
| T021 | 04 CRM Sync | Slack webhook returns an error. | Process an interested reply. | The interested lead remains persisted and the failed alert is logged for retry; classification is not reversed. | `crm_leads`, `audit_log` |
| T022 | 04 CRM Sync | Reply is `ooo`, `not_interested`, or `objection`. | Process the reply. | The raw reply and classification are stored, but no CRM lead adapter row is created. | `replies_inbox`, `crm_leads` |

## Execution protocol

Run T001–T004 in fixture or mocked-provider mode. Run T005–T012 with fixture records first, then repeat T005–T008 against a five-row live sample after credentials are configured. Run T013–T017 against the included mock mailbox seed. Run T018–T022 with HTTP POST payloads that contain no real personal data.

A test is not considered passed because the canvas is green. Record the n8n execution ID, the relevant table rows, and any provider usage observed. Any test that uses a real provider must also record the account and date separately from the shareable project repository.
