-- Agency Outbound Pipeline — PostgreSQL schema
-- Safe to run repeatedly in a pilot database.
-- Real provider credentials never belong in this file.

CREATE SCHEMA IF NOT EXISTS agency_outbound;

CREATE TABLE IF NOT EXISTS agency_outbound.signal_events (
    id BIGSERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL CHECK (source IN ('job_post', 'tech_stack', 'fixture')),
    company_name VARCHAR(255) NOT NULL,
    company_domain VARCHAR(255) NOT NULL,
    signal_type VARCHAR(100) NOT NULL,
    signal_detail JSONB NOT NULL DEFAULT '{}'::jsonb,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'enriched', 'rejected', 'error')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_signal_events_domain_type
    ON agency_outbound.signal_events (LOWER(company_domain), signal_type);
CREATE INDEX IF NOT EXISTS ix_signal_events_status_detected
    ON agency_outbound.signal_events (status, detected_at);

CREATE TABLE IF NOT EXISTS agency_outbound.prospects_enriched (
    id BIGSERIAL PRIMARY KEY,
    signal_event_id BIGINT NOT NULL REFERENCES agency_outbound.signal_events(id),
    full_name VARCHAR(255),
    email VARCHAR(255),
    email_source VARCHAR(50) NOT NULL DEFAULT 'unresolved' CHECK (email_source IN ('apollo', 'hunter', 'fixture', 'unresolved')),
    resolution_tier INT NOT NULL DEFAULT 0 CHECK (resolution_tier IN (0, 1, 2)),
    resolution_cost NUMERIC(12, 4) NOT NULL DEFAULT 0,
    title VARCHAR(255),
    linkedin_url VARCHAR(500),
    mx_verified BOOLEAN NOT NULL DEFAULT FALSE,
    enriched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'personalized', 'dead', 'error')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_prospects_signal_event ON agency_outbound.prospects_enriched(signal_event_id);
CREATE INDEX IF NOT EXISTS ix_prospects_status_tier ON agency_outbound.prospects_enriched(status, resolution_tier);
CREATE INDEX IF NOT EXISTS ix_prospects_email ON agency_outbound.prospects_enriched(email);

CREATE TABLE IF NOT EXISTS agency_outbound.personalization_hooks (
    id BIGSERIAL PRIMARY KEY,
    prospect_id BIGINT NOT NULL REFERENCES agency_outbound.prospects_enriched(id),
    research_summary TEXT NOT NULL,
    pain_point_hook TEXT NOT NULL,
    offer_angle VARCHAR(50) NOT NULL CHECK (offer_angle IN ('cost_reduction', 'speed_growth')),
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'queued', 'error')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_hooks_prospect ON agency_outbound.personalization_hooks(prospect_id);
CREATE INDEX IF NOT EXISTS ix_hooks_status_generated ON agency_outbound.personalization_hooks(status, generated_at);

CREATE TABLE IF NOT EXISTS agency_outbound.mailbox_registry (
    mailbox_id VARCHAR(80) PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    daily_cap INT NOT NULL DEFAULT 30 CHECK (daily_cap > 0),
    sent_today INT NOT NULL DEFAULT 0 CHECK (sent_today >= 0),
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agency_outbound.send_queue (
    id BIGSERIAL PRIMARY KEY,
    prospect_id BIGINT NOT NULL REFERENCES agency_outbound.prospects_enriched(id),
    hook_id BIGINT NOT NULL REFERENCES agency_outbound.personalization_hooks(id),
    mailbox_id VARCHAR(80) NOT NULL REFERENCES agency_outbound.mailbox_registry(mailbox_id),
    scheduled_for TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'capped', 'failed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_send_queue_hook ON agency_outbound.send_queue(hook_id);
CREATE INDEX IF NOT EXISTS ix_send_queue_status_schedule ON agency_outbound.send_queue(status, scheduled_for);

CREATE TABLE IF NOT EXISTS agency_outbound.replies_inbox (
    id BIGSERIAL PRIMARY KEY,
    send_queue_id BIGINT REFERENCES agency_outbound.send_queue(id),
    raw_reply_text TEXT NOT NULL,
    classification VARCHAR(30) CHECK (classification IN ('interested', 'not_interested', 'ooo', 'objection')),
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    crm_synced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_replies_classification ON agency_outbound.replies_inbox(classification, crm_synced);

CREATE TABLE IF NOT EXISTS agency_outbound.crm_leads (
    id BIGSERIAL PRIMARY KEY,
    reply_id BIGINT NOT NULL REFERENCES agency_outbound.replies_inbox(id),
    lead_name VARCHAR(255),
    lead_email VARCHAR(255),
    status VARCHAR(30) NOT NULL DEFAULT 'new_lead',
    sla_alert_sent BOOLEAN NOT NULL DEFAULT FALSE,
    pushed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_crm_leads_reply ON agency_outbound.crm_leads(reply_id);

-- Operational evidence tables. They make the concept project auditable rather than a canvas-only demo.
CREATE TABLE IF NOT EXISTS agency_outbound.workflow_runs (
    id BIGSERIAL PRIMARY KEY,
    workflow_name VARCHAR(120) NOT NULL,
    phase VARCHAR(80) NOT NULL,
    status VARCHAR(30) NOT NULL CHECK (status IN ('started', 'success', 'partial', 'failed')),
    rows_seen INT NOT NULL DEFAULT 0,
    provider_calls INT NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    error_message TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS ix_workflow_runs_recent ON agency_outbound.workflow_runs(workflow_name, started_at DESC);

CREATE TABLE IF NOT EXISTS agency_outbound.integration_usage (
    id BIGSERIAL PRIMARY KEY,
    workflow_name VARCHAR(120) NOT NULL,
    provider VARCHAR(80) NOT NULL,
    operation VARCHAR(120) NOT NULL,
    rows_processed INT NOT NULL DEFAULT 0,
    provider_units NUMERIC(14, 4) NOT NULL DEFAULT 0,
    estimated_cost_usd NUMERIC(14, 6) NOT NULL DEFAULT 0,
    observed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS ix_integration_usage_provider_time ON agency_outbound.integration_usage(provider, observed_at DESC);

CREATE TABLE IF NOT EXISTS agency_outbound.audit_log (
    id BIGSERIAL PRIMARY KEY,
    workflow_name VARCHAR(120) NOT NULL,
    event_type VARCHAR(120) NOT NULL,
    status VARCHAR(50) NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_audit_log_recent ON agency_outbound.audit_log(workflow_name, created_at DESC);

-- Idempotent demo seed. These are not real mailboxes and must never be used for production sending.
INSERT INTO agency_outbound.mailbox_registry (mailbox_id, domain, daily_cap)
VALUES
    ('mock-mailbox-01', 'mock-outbound-01.example', 30),
    ('mock-mailbox-02', 'mock-outbound-02.example', 30),
    ('mock-mailbox-03', 'mock-outbound-03.example', 30),
    ('mock-mailbox-04', 'mock-outbound-04.example', 30),
    ('mock-mailbox-05', 'mock-outbound-05.example', 30)
ON CONFLICT (mailbox_id) DO NOTHING;

-- Demo-only fixture rows. They use reserved .example domains and cannot be delivered to real recipients.
INSERT INTO agency_outbound.signal_events (source, company_name, company_domain, signal_type, signal_detail)
VALUES
    ('fixture', 'Northstar Support', 'northstarsupport.example', 'hiring_support_reps', '{"title":"Customer Support Representative","fixture":true}'),
    ('fixture', 'Orbit Commerce', 'orbitcommerce.example', 'missing_tracking_script', '{"technology":"analytics-missing","fixture":true}'),
    ('fixture', 'Harbor SaaS', 'harborsaas.example', 'hiring_support_reps', '{"title":"Support Operations Manager","fixture":true}')
ON CONFLICT (LOWER(company_domain), signal_type) DO NOTHING;
