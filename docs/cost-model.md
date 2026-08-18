# Cost Model — Signal-to-CRM Outbound Pipeline

**Purpose:** give a reviewer a credible cost story without inventing vendor usage, pretending a free tier is unlimited, or hiding the simulated mailbox and CRM boundaries.

## Executive view

The fixture-mode concept project has **$0 incremental provider spend** if the operator already has an n8n instance, PostgreSQL database, Slack workspace, and access to a Gemini free tier. The live pilot is usage-dependent. The largest uncertainty is not the two Gemini prompts; it is the provider economics of signal collection and contact enrichment, especially Apollo credit consumption and the chosen Apify Actor’s compute or store pricing.

> **Cost discipline:** The project records observed provider units in `agency_outbound.integration_usage` instead of claiming a fixed price where the provider’s price depends on plan, returned data, Actor duration, or account configuration.

## Current price inputs

| Component | Current documented input | Cost treatment in this project |
|---|---|---|
| Apify | Free plan is $0 with $5/month of platform usage; the official page lists $0.20 per compute unit and explains that exact usage depends on Actor behavior, storage, transfer, and proxies [1]. | Use fixture mode first. In live mode, run a small Actor test and record the observed usage before extrapolating. |
| Apollo | People Search is listed as 0 credits, while People Enrichment is listed as 1–9 credits per person without waterfall enrichment; the actual charge depends on returned data and plan configuration [2] [3]. | Treat Apollo as a variable cost. Record `credits_consumed` or account usage and calculate from the workspace’s effective plan economics. |
| Hunter | The Free plan is $0 with 50 credits/month. Starter is shown as $49 monthly or $34 monthly on annual billing, with 2,000 credits/month; one credit is used per email found by Domain Search, Email Finder, or verification rules documented by Hunter [4]. | Make Hunter fallback-only and set a monthly cap. Use the Free plan for the first sample, then quote paid cost only if the observed fallback rate justifies it. |
| Gemini | Google documents a free tier for selected models and a paid tier. The current pricing page lists Gemini 3.5 Flash-Lite at $0.30 per 1M input tokens and $2.50 per 1M output tokens in the standard paid table [5]. | Estimate from actual `usageMetadata` when returned. Keep the model configurable because pricing and model availability can change. |
| Slack webhook | The workflow uses an incoming webhook only for operational alerts. | Assume an existing Slack workspace; treat any plan or workspace cost as external to this concept project. |
| PostgreSQL and n8n | The package assumes an existing n8n instance and Postgres endpoint. | Show as $0 incremental when already available; quote separately if the pilot needs new hosting. |
| Mailboxes and CRM | The mailbox swarm and CRM destination are intentionally not purchased for this MVP. | $0 in the concept project. The mailboxes are mocked and the CRM is a Postgres adapter. |

## Illustrative pilot scenario

The following is a transparent example, not a forecast. Replace every assumption with measured pilot values before a client quote.

| Assumption | Example value |
|---|---:|
| Signals collected | 100 per month |
| Enrichment attempts | 100 Apollo attempts |
| Hunter fallback attempts | 25 domains |
| Personalization calls | 200 Gemini calls, two per resolved prospect |
| Reply classifications | 50 Gemini calls |
| Average Gemini input per call | 1,000 tokens |
| Average Gemini output per call | 200 tokens |
| Apify usage | Must be measured from the selected Actor |
| Mailbox infrastructure | Simulated; no mailbox purchase |
| CRM destination | Simulated Postgres adapter |

Under those assumptions, Gemini volume is 250 calls, 250,000 input tokens, and 50,000 output tokens. At the cited standard Gemini 3.5 Flash-Lite paid rates, the illustrative generation cost is approximately **$0.075 input + $0.125 output = $0.20**, before any account-specific free-tier treatment. The calculation is:

```text
(250,000 / 1,000,000 × $0.30) + (50,000 / 1,000,000 × $2.50) = $0.20
```

The Apollo and Hunter portions cannot be responsibly collapsed into a single dollar number without the operator’s actual plan, credit balance, waterfall settings, and observed matches. The project therefore logs `provider_units` and `estimated_cost_usd` for a later measured report.

## Scenario ranges

| Scenario | External provider posture | Expected incremental spend | What is proven |
|---|---|---:|---|
| A. Portfolio demo | Fixture mode, `DRY_RUN=true`, mock mailboxes, Postgres CRM adapter | $0 if n8n/Postgres already exist | Workflow structure, state transitions, cap logic, safe fallbacks, test evidence |
| B. Controlled live sample | 5–10 live signals, Apollo first, Hunter fallback, Gemini live, Slack alert, no send | Usually low single-digit provider usage plus any existing infrastructure cost; exact amount must be measured | Real provider authentication, enrichment fallback economics, AI output quality, audit trail |
| C. Small pilot | 100 signals/month, 25 Hunter fallbacks, 250 Gemini calls, no mailbox swarm | Apify and Apollo are usage-dependent; Hunter may remain on Free if within 50 credits; Gemini is likely very small relative to enrichment costs | Throughput, cost per resolved contact, hook quality, reply classification, operator SLA |
| D. Production direction | Real CRM, approved sending platform, multiple domains/mailboxes, stronger queue and observability | Vendor and compliance review required; not a number this MVP should pretend to know | Upgrade path rather than a production claim |

## Cost metrics to report after the pilot

The most credible client-facing metrics are measured unit economics, not generic “AI savings” claims:

| Metric | Calculation |
|---|---|
| Cost per signal captured | Provider usage cost for Workflow 00 divided by inserted unique signals |
| Cost per resolved prospect | Apollo + Hunter observed cost divided by prospects with a non-null email |
| Fallback rate | Hunter fallback rows divided by Apollo attempts |
| AI cost per personalized hook | Gemini usage cost divided by valid hooks inserted |
| Queue utilization | Sent or queued rows divided by available daily mailbox capacity |
| Interested-reply SLA coverage | Interested replies with successful Slack alert divided by interested replies |
| Manual review rate | Rows held for human review divided by total processed rows |

## Budget controls

The live pilot should begin with a hard batch limit of 5–10 rows, a monthly Hunter fallback budget, a small Apify Actor input, a configurable Gemini model, and `DRY_RUN=true`. Provider usage should be reviewed after the first batch. Increasing schedule frequency or batch size without reviewing `integration_usage` would undermine the cost credibility of the case study.

## References

[1]: https://apify.com/pricing "Apify official pricing"
[2]: https://docs.apollo.io/reference/people-enrichment "Apollo People Enrichment"
[3]: https://docs.apollo.io/docs/api-pricing "Apollo API pricing and credits"
[4]: https://hunter.io/pricing "Hunter official pricing"
[5]: https://ai.google.dev/gemini-api/docs/pricing "Gemini API pricing"
