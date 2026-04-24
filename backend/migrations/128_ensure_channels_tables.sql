-- Compatibility: ensure channels, channel_groups, channel_model_pricing, and
-- channel_pricing_intervals tables exist with all columns added through migration 127.
--
-- This migration guards against databases where 081_create_channels.sql was not
-- applied (e.g. the migration was introduced after the DB was already initialised,
-- or the runner failed silently on a previous startup).  Every statement uses
-- IF NOT EXISTS / ADD COLUMN IF NOT EXISTS so it is fully idempotent and safe to
-- run on databases that already have these tables.

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '10min';

-- 1. channels table (081_create_channels.sql)
CREATE TABLE IF NOT EXISTS channels (
    id                   BIGSERIAL    PRIMARY KEY,
    name                 VARCHAR(100) NOT NULL,
    description          TEXT         DEFAULT '',
    status               VARCHAR(20)  NOT NULL DEFAULT 'active',
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_channels_name   ON channels (name);
CREATE INDEX        IF NOT EXISTS idx_channels_status ON channels (status);

-- Columns added by subsequent migrations
ALTER TABLE channels ADD COLUMN IF NOT EXISTS model_mapping          JSONB        DEFAULT '{}';          -- 083
ALTER TABLE channels ADD COLUMN IF NOT EXISTS billing_model_source   VARCHAR(20)  DEFAULT 'channel_mapped'; -- 084 + 088
ALTER TABLE channels ADD COLUMN IF NOT EXISTS restrict_models        BOOLEAN      DEFAULT false;          -- 085
ALTER TABLE channels ADD COLUMN IF NOT EXISTS features               TEXT         NOT NULL DEFAULT '';    -- 095
ALTER TABLE channels ADD COLUMN IF NOT EXISTS features_config        JSONB        NOT NULL DEFAULT '{}'; -- 101

-- 2. channel_groups table (081_create_channels.sql)
CREATE TABLE IF NOT EXISTS channel_groups (
    id         BIGSERIAL   PRIMARY KEY,
    channel_id BIGINT      NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    group_id   BIGINT      NOT NULL REFERENCES groups(id)   ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_channel_groups_group_id   ON channel_groups (group_id);
CREATE INDEX        IF NOT EXISTS idx_channel_groups_channel_id ON channel_groups (channel_id);

-- 3. channel_model_pricing table (081_create_channels.sql)
CREATE TABLE IF NOT EXISTS channel_model_pricing (
    id                 BIGSERIAL      PRIMARY KEY,
    channel_id         BIGINT         NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    models             JSONB          NOT NULL DEFAULT '[]',
    input_price        NUMERIC(20,12),
    output_price       NUMERIC(20,12),
    cache_write_price  NUMERIC(20,12),
    cache_read_price   NUMERIC(20,12),
    image_output_price NUMERIC(20,8),
    created_at         TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_channel_model_pricing_channel_id ON channel_model_pricing (channel_id);

-- Columns added by subsequent migrations
ALTER TABLE channel_model_pricing ADD COLUMN IF NOT EXISTS billing_mode      VARCHAR(20)    NOT NULL DEFAULT 'token'; -- 082
ALTER TABLE channel_model_pricing ADD COLUMN IF NOT EXISTS per_request_price NUMERIC(20,10);                          -- 085
ALTER TABLE channel_model_pricing ADD COLUMN IF NOT EXISTS platform          VARCHAR(50)    NOT NULL DEFAULT 'anthropic'; -- 086

CREATE INDEX IF NOT EXISTS idx_channel_model_pricing_platform ON channel_model_pricing (platform); -- 086

-- 4. channel_pricing_intervals table (082_refactor_channel_pricing.sql)
CREATE TABLE IF NOT EXISTS channel_pricing_intervals (
    id                BIGSERIAL      PRIMARY KEY,
    pricing_id        BIGINT         NOT NULL REFERENCES channel_model_pricing(id) ON DELETE CASCADE,
    min_tokens        INT            NOT NULL DEFAULT 0,
    max_tokens        INT,
    tier_label        VARCHAR(50),
    input_price       NUMERIC(20,12),
    output_price      NUMERIC(20,12),
    cache_write_price NUMERIC(20,12),
    cache_read_price  NUMERIC(20,12),
    per_request_price NUMERIC(20,12),
    sort_order        INT            NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_channel_pricing_intervals_pricing_id ON channel_pricing_intervals (pricing_id);

COMMENT ON TABLE channels                  IS '渠道管理：关联多个分组，提供自定义模型定价';
COMMENT ON TABLE channel_groups            IS '渠道-分组关联表：每个分组最多属于一个渠道';
COMMENT ON TABLE channel_model_pricing     IS '渠道模型定价：一条定价可绑定多个模型，价格一致';
COMMENT ON TABLE channel_pricing_intervals IS '渠道定价区间：支持按 token 区间、按次分层、图片分辨率分层';
