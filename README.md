# Agency Outbound Pipeline — n8n Concept Project

## What this is

This repository is the first iteration of a **signal-to-CRM outbound pipeline** for a RevOps automation portfolio. It is intentionally a concept-proving skeleton rather than production infrastructure. The engineering story is a stateful, modular pipeline that captures a business signal, enriches a prospect through a waterfall, generates a research-backed hook, applies cap-aware scheduling logic, and hands interested replies to a CRM adapter with an SLA alert.

The repository is safe to share because it contains no real credentials and uses reserved `.example` domains for fixture data. Real provider integrations are available behind n8n credentials and environment variables. The mailbox swarm and CRM destination remain explicitly simulated.

## Design principles

> **Real integrations or explicit simulations. Never invent a fake vendor endpoint.**

> **No agent-washing.** Gemini is used through single-shot HTTP Request nodes with deterministic JSON outputs; this MVP does not use an AI Agent node.

> **State over canvas chaining.** The workflows communicate through PostgreSQL tables, so each phase can be tested and replayed independently.

> **DRY_RUN by default.** The optional Gmail branch is one sandbox mailbox only and is not a deliverability system.

## Repository map

| Path | Purpose |
|---|---|
| `workflows/` | Five n8n-importable JSON workflows |
| `schema/schema.sql` | PostgreSQL migration, indexes, audit tables, and fixture seed |
| `generator/build_workflow.py` | Reproducible workflow generator |
| `generator/validate_workflow.py` | Structural import-safety gate |
| `skills/n8n-workflow-builder/SKILL.md` | Reusable generation and delivery contract |
| `tests/T00X_test_cases.md` | Per-workflow acceptance tests |
| `docs/architecture.md` | Architecture and deployment options |
| `docs/cost-model.md` | Source-backed cost assumptions and pilot scenarios |
| `docs/real-vs-simulated.md` | Evidence matrix and claim boundaries |
| `docs/before-after.md` | Portfolio/case-study narrative |
| `docs/pilot-runbook.md` | Fixture-to-live pilot procedure |
| `docs/credential-matrix.md` | Credential setup and security boundaries |
| `diagrams/` | Mermaid source and rendered PNG diagrams |
| `config/pilot.env.example` | Non-secret configuration template |

## Quick start: fixture mode

The safest first run uses no external provider credentials. Create a non-production PostgreSQL database, apply the schema, and import the five workflow JSON files into n8n.

```bash
psql "$DATABASE_URL" -f schema/schema.sql
python3 generator/validate_workflow.py workflows/*.json
```

Set the n8n environment configuration to:

```text
PILOT_MODE=fixture
DRY_RUN=true
GEMINI_MODEL=gemini-3.5-flash-lite
```

Create the `Agency Outbound Postgres` credential in n8n and attach it to the Postgres nodes if the import leaves the credential reference unbound. Run the workflows manually in this order:

```text
00 — Signal Trigger / Ingestion
01 — Waterfall Enrichment
02 — AI Personalization
03 — Deliverability Simulation
04 — CRM Sync / Master Inbox
```

The first four workflows are schedule-triggered but can be run manually for a pilot. Workflow 04 exposes a webhook path `/reply-received`; post a synthetic reply to the generated test URL. The default fixture branch uses no real recipient and no outbound provider.

## Configure a small live sample

Switch to live mode one workflow at a time. Create credentials or secrets for PostgreSQL, Apify, Apollo, Hunter, Gemini, Slack, and optionally one sandbox Gmail mailbox. Follow `docs/credential-matrix.md` and `docs/pilot-runbook.md`. The generated JSON intentionally uses names and references rather than secret values. n8n’s official documentation warns that exported JSON can contain credential names and imported cURL headers, so review public exports before sharing them [1].

Recommended first live batch:

| Stage | Limit | Required review |
|---|---:|---|
| Signal ingestion | 5–10 signals | Normalize domains and inspect source quality |
| Apollo enrichment | Same 5–10 rows | Review returned fields and observed credits |
| Hunter fallback | Only unresolved Apollo rows | Confirm the monthly credit budget |
| Gemini personalization | 5–10 prospects | Human-review every hook |
| Reply sync | Synthetic replies only | Confirm CRM adapter and Slack alert |
| Sending | Zero real sends by default | Enable only one approved sandbox recipient after sign-off |

## Credential boundaries

Never put API keys in workflow JSON, SQL, Git, screenshots, or Slack. Store them in n8n credential records or the approved secret manager. The environment template contains placeholders only. `PILOT_MODE=fixture` and `DRY_RUN=true` are the safe defaults.

## Validation and regeneration

If the generator changes, regenerate and validate in one pass:

```bash
python3 generator/build_workflow.py
python3 generator/validate_workflow.py workflows/*.json
```

The validator checks duplicate node IDs and names, dangling connections, orphaned nodes, missing expression references, fail-soft external calls, non-empty Postgres queries, and state transitions. Workflow 00 is allowed to insert new signal rows without an update because `new` is the intended handoff state for Workflow 01.

## Import and deployment options

n8n supports editor import/export of workflow JSON and also documents public API workflows for programmatic operations [2] [3]. For this concept project, editor import is the default. Once the workflow JSON is stable and credentials are bound, a team can add an API-based promotion path for staging and production environments. Do not make the REST deployment path a prerequisite for the credibility demo.

## What is real and what is simulated

| Surface | Status |
|---|---|
| Apify Actor call | Real when `PILOT_MODE=live` |
| Homepage fetch and regex tech detector | Real algorithm |
| Apollo → Hunter waterfall | Real provider path when credentials are configured |
| MX lookup | Real lightweight DNS lookup |
| Gemini research and classification | Real single-shot REST path when live; deterministic fixture branch available |
| Mailbox cap and round-robin algorithm | Real algorithm |
| Mailbox swarm and warm-up network | Simulated with Postgres mock rows |
| CRM destination | Simulated Postgres adapter |
| Slack SLA alert | Real webhook path when configured |



## References

[1]: https://docs.n8n.io/build/manage-workflows/export-and-import "n8n — Export and import workflows"
[2]: https://docs.n8n.io/connect/n8n-api "n8n — API documentation"
[3]: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest "n8n — HTTP Request node"
