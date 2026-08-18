# Research Notes — Signal-to-CRM Outbound Pipeline

## Scope and boundary

The attached MVP specification defines five independently triggerable n8n workflows connected through PostgreSQL state. The concept project must preserve the real-versus-simulated distinction: Apify, Apollo, Hunter, Gemini, homepage fetches, DNS/MX checks, and Slack are real integration paths; mailbox swarm and CRM destination are simulated or adapter-backed by design.

## Verified n8n behavior

- n8n stores workflows as JSON and supports import/export through the editor. Exported workflows may include credential names and IDs, so generated JSON must not contain secret values or sensitive credential names.
- n8n's public REST API is available for programmatic workflow operations on supported plans; current docs state the API is not available during the free trial. The package therefore treats REST deployment as optional and provides editor import as the default path.
- The HTTP Request node supports generic credentials, headers, query parameters, JSON bodies, response formats, pagination, and timeout controls. The generated workflows use credential references and explicit fail-soft behavior instead of embedding keys.

## Verified provider contracts

### Apify

Apify's Actor API supports starting an Actor and retrieving dataset output. The official pricing page currently lists a Free plan at $0 with $5/month of platform usage and a stated $0.20 per compute unit; exact usage depends on the Actor, duration, memory, proxies, transfer, and storage. The workflow therefore stores the Actor ID and input as configuration placeholders and requires a small test run before forecasting volume.

### Apollo

Apollo's People API Search endpoint is `api/v1/mixed_people/api_search` and requires API-key access; it does not return emails or phone numbers. People enrichment is a separate endpoint and may consume credits based on returned data and the account's waterfall configuration. The package models Apollo as the first enrichment tier but records the actual observed credit charge rather than pretending a fixed dollar cost.

### Hunter

Hunter's API base is `https://api.hunter.io/v2/`; the Domain Search endpoint is `GET /domain-search`, authenticated by `api_key`, `X-API-KEY`, or Bearer auth. The current official pricing page lists the Free plan at $0 with 50 monthly credits; Domain Search, Email Finder, and Email Verifier consume credits according to returned results. The fallback path is therefore budget-capped and explicitly logged.

### Gemini

The current Gemini REST generation endpoint is `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`. The model catalog lists Gemini 3.5 Flash-Lite as a stable, cost-efficient model for high-volume tasks and lists Gemini 2.0 Flash under previous models. The MVP should therefore default to a configurable stable model name (`gemini-3.5-flash-lite`) rather than hard-coding the older 2.0 model. Google documents free and paid tiers, with actual rate limits varying by project and model; the workflows capture usage metadata when returned.

## Architecture consequence

The concept project should use a dual-mode configuration: `PILOT_MODE=fixture` for deterministic demonstrations with included sample data, and `PILOT_MODE=live` for real provider credentials. Live credentials are configured only inside n8n credentials or environment variables and never committed to workflow JSON. The generated package must be safe to publish publicly as a portfolio artifact while retaining a documented path to a controlled pilot.

## Sources

1. https://docs.n8n.io/connect/n8n-api — n8n API documentation.
2. https://docs.n8n.io/build/manage-workflows/export-and-import — n8n workflow import/export documentation.
3. https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest — n8n HTTP Request node documentation.
4. https://docs.apify.com/api/v2 — Apify API documentation.
5. https://apify.com/pricing — Apify official pricing.
6. https://docs.apollo.io/reference/apollo-api — Apollo API overview.
7. https://docs.apollo.io/reference/people-api-search — Apollo People API Search.
8. https://docs.apollo.io/docs/api-pricing — Apollo API credit pricing.
9. https://hunter.io/api-documentation — Hunter API documentation.
10. https://hunter.io/api/domain-search — Hunter Domain Search API.
11. https://hunter.io/pricing — Hunter official pricing.
12. https://ai.google.dev/api/generate-content — Gemini GenerateContent API.
13. https://ai.google.dev/gemini-api/docs/models — Gemini model catalog.
14. https://ai.google.dev/gemini-api/docs/pricing — Gemini API pricing.
15. https://ai.google.dev/gemini-api/docs/rate-limits — Gemini API rate limits.

## Render verification

The rendered architecture diagram is readable at 3120 × 2032 and clearly separates signal sources, n8n orchestration, PostgreSQL state, provider boundaries, and operational evidence tables. The before-and-after diagram is readable at 3120 × 3172 and shows the transition from manual job-board research, guessing addresses, and CRM copying to stateful ingestion, waterfall enrichment, AI hooks, cap-aware queueing, and SLA handoff.
