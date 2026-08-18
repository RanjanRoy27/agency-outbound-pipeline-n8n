# Architecture Decision Log

| Decision | Choice | Reason | Revisit when |
|---|---|---|---|
| Workflow handoff | PostgreSQL polling | Independently triggerable and easy to demo against stale rows; failures do not cascade | Latency or volume requires a queue or `LISTEN/NOTIFY` |
| Signal source | Apify plus homepage fetch | Real API path and low-cost experiment; deterministic tech detector avoids a paid BuiltWith dependency | Source terms, reliability, or scale require a sanctioned feed |
| Enrichment | Apollo first, Hunter fallback | Makes provider economics visible and provides a genuine waterfall story | Match quality or credit economics change |
| AI implementation | Single-shot Gemini HTTP Request | The tasks are bounded summarization and classification, not tool-using agent tasks | A stateful tool-using workflow is genuinely required |
| AI model | Configurable `gemini-3.5-flash-lite` default | Current stable, cost-efficient model family with a configurable name | Model catalog or quality evaluation changes |
| Review research | Homepage copy only | Avoids inventing a paid review-scraping path and keeps the source traceable | A lawful, reliable reviews API is approved |
| Delivery | Mock mailbox registry and `DRY_RUN=true` | Proves cap logic without claiming deliverability infrastructure | Real sending provider, compliance, warm-up, and monitoring are approved |
| CRM | Postgres adapter table | Keeps the concept project dependency-light while preserving the replacement boundary | HubSpot/Salesforce field mapping is approved |
| Credentials | n8n credential references and environment variables | Public-safe exports and least exposure of secrets | A managed secret manager and CI promotion path are introduced |
| Evidence | `workflow_runs`, `integration_usage`, `audit_log` | Allows measured case-study claims instead of canvas-only claims | Central observability platform is introduced |
