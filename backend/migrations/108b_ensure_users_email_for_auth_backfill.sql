-- Ensure legacy users.email exists before migration 109 compat backfill.
ALTER TABLE users
ADD COLUMN IF NOT EXISTS email TEXT;
