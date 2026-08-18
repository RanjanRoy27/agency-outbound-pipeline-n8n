# Before and After — Concept Project Narrative

## Before: a manual outbound research loop

The starting process is a sequence of context switches. An operator searches job boards, opens company websites, interprets signals, finds or guesses contact details, writes a first line, chooses a mailbox, watches several inboxes, and copies interested replies into a CRM. Each step can be performed by a skilled person, but the process has weak memory: duplicate companies are easy to revisit, the cost of the second enrichment source is invisible, and a failed provider call can force a full restart.

The most expensive problem is not simply “too much clicking.” It is the absence of a shared state model. Without explicit rows and statuses, there is no reliable answer to which signal was captured, which contact source resolved it, whether the email had a valid MX domain, whether a hook was generated, why a send was held, or whether an interested reply reached a CRM queue.

## After: a controlled signal-to-CRM pipeline

The concept project turns the manual loop into five stateful modules. Signal ingestion creates a durable event; enrichment consumes only new events and records whether Apollo or Hunter resolved the contact; AI personalization consumes only resolved prospects and stores the research and hook; deliverability simulation assigns queued hooks under explicit mailbox caps; and the CRM workflow validates, classifies, persists, and alerts on replies.

The architecture does not remove judgment. It moves judgment to the right boundaries. Deterministic code decides whether a signal matches a target pattern, whether a mailbox is capped, whether an AI label is valid, and whether a contact has an MX record. Single-shot Gemini calls are used only where natural-language summarization or classification is appropriate. Human review remains in the loop before any real outbound send.

## Portfolio proof points

| Proof point | Why it builds credibility |
|---|---|
| Five independent workflows | Demonstrates modular ownership and independent testability rather than one unmaintainable canvas. |
| Postgres state between phases | Makes retries, stale-row replays, and failure isolation visible. |
| Apollo → Hunter fallback | Shows a real waterfall pattern with a measurable resolution tier and cost ledger. |
| `continueOnFail=true` plus audit rows | Shows failure handling as a designed behavior rather than a green-path demo. |
| `DRY_RUN=true` and mock mailboxes | Proves cap logic without pretending to own production deliverability infrastructure. |
| CRM adapter table | Shows how a real HubSpot or Salesforce destination can replace one node without rewriting upstream logic. |
| T00X tests | Converts the concept from a screenshot into an inspectable engineering artifact. |
| Public-safe JSON | Demonstrates professional credential hygiene and a reproducible import path. |

## What success looks like in a pilot

A successful pilot does not begin with a large send volume. It begins with evidence: a five-to-ten-row live signal sample, measured Apollo and Hunter usage, a reviewed set of personalized hooks, deterministic cap behavior, a simulated or sandbox reply, and an SLA alert that can be traced from webhook to database to Slack. The case study should report these facts with execution IDs and table counts rather than relying on unverified productivity claims.

## Suggested case-study headline

> **From manual outbound research to an auditable signal-to-CRM pipeline: five n8n workflows, a Postgres state machine, waterfall enrichment economics, and a safe deliverability simulation.**
