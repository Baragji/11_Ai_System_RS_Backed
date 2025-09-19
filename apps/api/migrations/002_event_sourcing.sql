BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS event_store (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    event_version INTEGER NOT NULL CHECK (event_version > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (aggregate_id, event_version)
);

CREATE INDEX IF NOT EXISTS idx_event_store_tenant_aggregate ON event_store (tenant_id, aggregate_id, event_version DESC);
CREATE INDEX IF NOT EXISTS idx_event_store_type ON event_store (aggregate_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_event_store_created_at ON event_store (created_at DESC);

ALTER TABLE event_store ENABLE ROW LEVEL SECURITY;

CREATE POLICY event_store_tenant_isolation ON event_store
    USING (tenant_id = current_setting('app.current_tenant')::uuid)
    WITH CHECK (tenant_id = current_setting('app.current_tenant')::uuid);

CREATE TABLE IF NOT EXISTS saga_instances (
    saga_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    saga_type VARCHAR(100) NOT NULL,
    current_step INTEGER NOT NULL DEFAULT 0 CHECK (current_step >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'compensating', 'failed')),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_saga_instances_tenant_type ON saga_instances (tenant_id, saga_type);
CREATE INDEX IF NOT EXISTS idx_saga_instances_tenant_status ON saga_instances (tenant_id, status, updated_at DESC);

ALTER TABLE saga_instances ENABLE ROW LEVEL SECURITY;

CREATE POLICY saga_instances_tenant_isolation ON saga_instances
    USING (tenant_id = current_setting('app.current_tenant')::uuid)
    WITH CHECK (tenant_id = current_setting('app.current_tenant')::uuid);

CREATE TRIGGER saga_instances_updated_at
BEFORE UPDATE ON saga_instances
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;
