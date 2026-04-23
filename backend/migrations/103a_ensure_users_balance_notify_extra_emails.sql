-- Ensure legacy balance notification email column exists before migration 104.
ALTER TABLE users
ADD COLUMN IF NOT EXISTS balance_notify_extra_emails TEXT NOT NULL DEFAULT '[]';
