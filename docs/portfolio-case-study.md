# Portfolio Case Study — Signal-to-CRM Outbound Pipeline

## Challenge

A small RevOps team had a manual outbound research loop: find a signal, investigate the company, locate a contact, write a first line, choose a mailbox, monitor replies, and copy interested leads into a CRM. The process was slow to repeat, difficult to audit, and vulnerable to provider failures and duplicate work.

## Solution

I designed a five-workflow n8n system backed by a dedicated PostgreSQL namespace. Each workflow owns one phase and communicates through explicit table state rather than a synchronous chain. The centerpiece is a waterfall enrichment module that tries Apollo first, falls back to Hunter only when needed, records the resolution tier and observed provider usage, and performs a lightweight MX check. Gemini is used for single-shot research and hook generation, not as an overbuilt agent. Mailbox distribution, daily cap enforcement, and reply-to-CRM handoff are demonstrated with explicit simulations and adapters instead of fake vendor calls.

## Engineering decisions

| Decision | Rationale |
|---|---|
| PostgreSQL polling between workflows | Independent retries and demos; failures do not cascade backward. |
| Apollo then Hunter | Demonstrates a measurable fallback waterfall and cost boundary. |
| Single-shot Gemini REST calls | Appropriate for bounded summarization and classification; avoids agent complexity. |
| `continueOnFail=true` on external calls | Provider failure becomes a state or audit event instead of a pipeline crash. |
| Mock mailboxes and CRM adapter | Proves algorithms without buying risky infrastructure or claiming production deliverability. |
| Validator before import | Turns workflow JSON from a handoff artifact into a checked build output. |

## Evidence packet

The proof is the repository plus a controlled execution packet. It should contain:

1. Validator output showing all five workflows pass.
2. Database migration output and row counts for each phase table.
3. Execution IDs for fixture runs.
4. A screenshot or export of the `integration_usage` table for the live five-to-ten-row sample.
5. Five manually reviewed Gemini hooks.
6. One all-mailboxes-capped example and one daily-reset example.
7. Three reply classifications and the resulting CRM/SLA behavior.
8. The `real-vs-simulated.md` matrix.

## Safe claims

> I built an auditable, modular outbound automation skeleton that separates real provider calls from simulated infrastructure, measures waterfall resolution cost, validates its n8n graph before import, and preserves a clean adapter boundary for a future CRM.

Avoid claiming guaranteed deliverability, a production mailbox swarm, or automatic replacement of human review. Those are explicitly out of scope for this first iteration.

## Next iteration

The next version should add a real queue or Postgres notification mechanism, provider-specific retry policies, asynchronous Apollo waterfall callbacks, a formal evaluation set for hook quality, retention and privacy controls, a real CRM adapter, and a carefully reviewed sending provider. The current concept project is complete when those next steps are visible and testable, not when they are prematurely hidden behind a “production” label.
