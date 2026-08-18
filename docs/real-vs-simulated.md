# Real vs. Simulated Evidence Matrix

## Why this distinction matters

The strongest credibility signal in this project is not the number of nodes. It is the explicit boundary between what can be executed against a genuine provider now and what is represented by a controlled simulation because the production vendor or operational surface has not been approved.

| Capability | Implementation in this MVP | Status | Evidence a reviewer can inspect | Production replacement |
|---|---|---|---|---|
| Job-board signal collection | Apify Actor HTTP call with a configurable Actor ID, plus fixture branch | Real in live mode; fixture available | Workflow 00, provider usage, signal rows | Approved Actor or direct source API with terms review |
| Homepage retrieval | Public HTTPS GET with fail-soft handling | Real | Workflow 00 and 02 execution data | Crawler policy, caching, robots and rate controls |
| Technology detection | Deterministic regex/header scan | Real algorithm | `Detect Tech Stack` Code node and `signal_detail` | More complete detector or paid vendor if justified |
| Apollo enrichment | API-key request to People Enrichment endpoint | Real in live mode | Workflow 01, tier and usage ledger | Approved Apollo plan and credit budget |
| Hunter fallback | Domain Search REST call | Real in live mode | Workflow 01, `email_source`, usage ledger | Approved paid tier or alternate provider |
| MX validation | Node DNS MX lookup | Real algorithm | `mx_verified` field | Optional SMTP verification provider after legal review |
| AI research | Single-shot Gemini REST request with JSON mode | Real in live mode; fixture available | Workflow 02, stored research and hook | Model pinning, evaluation set, prompt versioning |
| Offer angle | Deterministic company-size rule | Real algorithm | `Determine Offer Angle` Code node | Configurable rules table and offline evaluation |
| Mailbox capacity | Round-robin and cap enforcement over Postgres rows | Real algorithm | `mailbox_registry`, `send_queue`, cap audit | Real sending provider plus deliverability program |
| Mailbox swarm | Five mock mailbox registry rows | Simulated | `.example` domains, sticky note, `DRY_RUN=true` | Approved domains, accounts, warm-up and compliance controls |
| Outbound send | No send by default; optional one-mailbox Gmail branch | Simulated by default; optional sandbox | `DRY_RUN`, Gmail node | Approved sending platform and human sign-off |
| Reply intake | Webhook accepts a simulated payload | Hybrid | `/reply-received`, validation branch | Gmail trigger or approved inbox integration |
| Reply classification | Single-shot Gemini call or deterministic fixture classifier | Real algorithm; fixture available | `replies_inbox.classification` | Evaluated classifier with monitoring |
| CRM handoff | Postgres adapter row | Simulated destination | `crm_leads`, `Insert CRM Lead Adapter` | HubSpot/Salesforce node replacement |
| SLA alert | Slack webhook | Real in live mode | Slack node and audit log | Slack app with signing and retry policy |

## Claims this project can safely make

The project can claim that it demonstrates a modular signal-to-CRM pipeline, a real waterfall enrichment pattern, deterministic cost logging, fail-soft API orchestration, cap-aware scheduling logic, single-shot AI classification, and an adapter boundary for later CRM replacement.

The project should not claim that it operates a deliverability-safe mailbox swarm, that it replaces a full CRM, that its provider free tiers are unlimited, or that its AI copy is automatically production-ready without review. Those are future validation items, not current evidence.
