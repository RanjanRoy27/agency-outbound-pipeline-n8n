# Security and Pilot-Readiness Review

**Review status:** Pass for concept-project sharing; live pilot requires operator configuration and approval.

## Checks completed

| Check | Result |
|---|---|
| All workflow JSON files parse | Pass |
| Duplicate node IDs or names | Pass — none detected |
| Dangling connections | Pass |
| Orphaned non-note nodes | Pass |
| Missing node-expression references | Pass |
| External HTTP/Gmail/Slack nodes set fail-soft | Pass |
| Stateful workflows contain status/counter mutations | Pass |
| Credential-like values in repository | Pass — scan found none |
| Fixture domains use reserved `.example` names | Pass |
| Default mode is fixture and dry-run | Pass by configuration template and workflow branches |
| Mailbox swarm represented as real infrastructure | Fail by design — explicitly simulated |
| CRM destination represented as real CRM | Fail by design — explicitly an adapter table |

## Security controls in the package

The workflow JSON contains credential references and placeholder environment expressions rather than secrets. The SQL schema contains no credentials. The fixture data uses synthetic names and reserved domains. Slack payloads contain an operational alert and an email field, but the pilot runbook instructs operators not to post raw reply text or unnecessary personal information. The optional Gmail node is visually and logically behind `DRY_RUN=false` and is scoped to one sandbox mailbox.

## Required operator actions before live mode

The operator must create a separate non-production PostgreSQL database or schema, bind the `Agency Outbound Postgres` credential, obtain and restrict real provider keys, choose an approved Apify Actor, confirm Apollo and Hunter credit budgets, configure a current Gemini model, and verify the Slack webhook destination. The operator must decide whether live data may be retained and for how long. Those decisions cannot be inferred from the repository and should not be silently invented.

The operator must also confirm the legal and policy basis for collecting job-board signals, visiting public sites, storing contact data, sending outbound messages, and handling replies. This package does not provide legal approval or deliverability assurance.

## Current limitations

The package has not connected to the user’s n8n instance because the session only showed disabled n8n connectors and no user-provided n8n URL or API key. That is not a blocker for import-based setup. If the user later provides a reachable n8n instance and approves direct deployment, the workflows can be imported manually or promoted through the instance’s supported API path.

The package also does not include real credentials or real lead data. That is intentional. Real secrets should be entered by the operator in the target n8n instance or approved secret manager, and the live pilot should begin with 5–10 records after the fixture tests pass.

## Go/no-go recommendation

**Go** for a fixture-mode demo and controlled live provider sample. **No-go** for bulk outbound sending, a mailbox swarm, or CRM production cutover until the operator completes credential setup, data-retention review, provider usage measurement, human hook review, and explicit sending approval.
