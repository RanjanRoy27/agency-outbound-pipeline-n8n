# n8n Workflow Builder Skill

## Purpose

This skill generates n8n workflows for the Agency Outbound Pipeline family. It is a repeatable build contract, not a one-off prompt. A future module must preserve the data-state boundaries and the distinction between real integrations, simulated destinations, and hybrid adapters.

## Five-phase state contract

The canonical phase sequence is:

| Phase | Input state | Output state | Owner |
|---|---|---|---|
| 00 Signal ingestion | External signal sources or fixtures | `signal_events.status = new` | Signal trigger workflow |
| 01 Waterfall enrichment | `signal_events.status = new` | `prospects_enriched`; source signal becomes `enriched` | Enrichment workflow |
| 02 AI personalization | `prospects_enriched.status = new AND resolution_tier > 0` | `personalization_hooks`; prospect becomes `personalized` | Personalization workflow |
| 03 Deliverability simulation | `personalization_hooks.status = new` | `send_queue`; hook becomes `queued` | Deliverability workflow |
| 04 CRM handoff | Webhook reply payload | `replies_inbox`, optional `crm_leads`, SLA audit | CRM sync workflow |

Each workflow owns one phase, is independently triggerable, reads from Postgres state, and writes state for the next phase. Polling is intentional for MVP isolation; a production revision may use a queue or `LISTEN/NOTIFY`.

## Node naming

Name nodes after business actions rather than implementation mechanics. Prefer `Check Apollo for Email`, `Mark Signal Enriched`, and `Insert CRM Lead Adapter` over `HTTP Request 3`, `Set 4`, and `Postgres 2`. Names must be unique within the workflow because n8n expressions and debugging rely on readable node identity.

## Real, simulated, and hybrid labels

Every workflow contains a visible sticky note using one of these labels:

- **REAL** means the algorithm and the external call are intended to run against a genuine provider endpoint.
- **SIMULATED** means the algorithm is genuine but the destination, mailbox pool, or other paid vendor surface is represented by a Postgres table or fixture.
- **HYBRID** means the workflow has real logic and notifications but retains an adapter or simulated input for the destination boundary.

Never create a fake integration URL. If the destination is not approved or does not have a stable free-tier path, write to Postgres and label the substitution.

## LLM policy

Use single-shot HTTP Request calls to the Gemini REST API with a small JSON response schema, low temperature, and an explicit output token limit. Do not use n8n AI Agent nodes for this MVP. All deterministic decisions, such as offer-angle selection and classification fallback handling, must be implemented in Code or IF nodes rather than delegated to the model.

## Credential policy

Generated JSON may contain n8n credential references and environment-variable expressions, but never real API keys, passwords, OAuth tokens, webhook secrets, or copied authorization headers. Prefer predefined credentials where available and generic Header Auth credentials for providers without a native node. Public exports must be reviewed for credential names and imported cURL headers.

## Error policy

All external HTTP/Gmail/Slack calls set `continueOnFail=true`. The downstream Code and Postgres nodes must turn failures into explicit audit rows or safe fallback states. A failed homepage fetch must not kill the entire batch. A failed Slack alert must not undo an interested-lead classification or CRM adapter write.

## Test case format

Use the T00X convention. Each case includes `ID`, `Workflow`, `Given`, `When`, `Then`, and `Evidence`. Evidence points to a node result or Postgres table. Minimum coverage includes empty sources, deduplication, provider fallback, unresolved contacts, malformed domains, AI timeouts, capacity caps, daily resets, malformed webhooks, unexpected labels, and notification failures.

## Structural validation gate

Before import, run `python3 generator/validate_workflow.py workflows/*.json`. The validator must reject:

- duplicate node IDs or names;
- dangling connections;
- orphaned non-note nodes;
- expressions referencing missing node names;
- external-call nodes without `continueOnFail=true`;
- empty Postgres queries;
- stateful input reads without a downstream status or counter transition; and
- stateful Postgres writes without a matching mutation, except Workflow 00’s intentional phase-output insert.

## Delivery checklist

The package is not complete until the SQL migration, all workflow JSON files, generator, validator, test cases, architecture documents, cost assumptions, credential matrix, and `PILOT_MODE=fixture` setup are present. Real credentials are entered only by the operator in n8n or the approved secret store after the fixture test suite passes.
