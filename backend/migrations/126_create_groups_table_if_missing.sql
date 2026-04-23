-- Compatibility: some legacy deployments may miss the entire groups table.
-- Create a schema-compatible groups table so runtime queries (e.g. ops aggregation) can run.
CREATE TABLE IF NOT EXISTS groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    rate_multiplier DECIMAL(10, 4) NOT NULL DEFAULT 1.0,
    is_exclusive BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    platform VARCHAR(50) NOT NULL DEFAULT 'anthropic',
    subscription_type VARCHAR(20) NOT NULL DEFAULT 'standard',
    daily_limit_usd DECIMAL(20, 8),
    weekly_limit_usd DECIMAL(20, 8),
    monthly_limit_usd DECIMAL(20, 8),
    default_validity_days INT NOT NULL DEFAULT 30,
    image_price_1k DECIMAL(20, 8),
    image_price_2k DECIMAL(20, 8),
    image_price_4k DECIMAL(20, 8),
    claude_code_only BOOLEAN NOT NULL DEFAULT FALSE,
    fallback_group_id BIGINT,
    fallback_group_id_on_invalid_request BIGINT,
    model_routing JSONB,
    model_routing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mcp_xml_inject BOOLEAN NOT NULL DEFAULT TRUE,
    supported_model_scopes JSONB NOT NULL DEFAULT '["claude","gemini_text","gemini_image"]'::jsonb,
    sort_order INT NOT NULL DEFAULT 0,
    allow_messages_dispatch BOOLEAN NOT NULL DEFAULT FALSE,
    require_oauth_only BOOLEAN NOT NULL DEFAULT FALSE,
    require_privacy_set BOOLEAN NOT NULL DEFAULT FALSE,
    default_mapped_model VARCHAR(100) NOT NULL DEFAULT '',
    messages_dispatch_model_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_groups_deleted_at ON groups(deleted_at);
CREATE INDEX IF NOT EXISTS idx_groups_platform ON groups(platform);
CREATE INDEX IF NOT EXISTS idx_groups_status ON groups(status);
