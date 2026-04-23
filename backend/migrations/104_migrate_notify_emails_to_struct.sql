-- Migrate notification email lists from old []string format to new []NotifyEmailEntry format
-- Old: ["a@x.com", "b@x.com"]
-- New: [{"email":"a@x.com","disabled":false,"verified":true}, ...]
-- Existing emails are marked as verified=false (unverified), disabled=false (enabled)

-- 1. User balance notification emails
-- Use dynamic SQL to avoid parse-time failures on schema variants lacking this column.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'balance_notify_extra_emails'
  ) THEN
    EXECUTE $migrate_users$
      UPDATE users
      SET balance_notify_extra_emails = (
        SELECT COALESCE(
          jsonb_agg(jsonb_build_object('email', elem::text, 'disabled', false, 'verified', false)),
          '[]'::jsonb
        )::text
        FROM jsonb_array_elements_text(balance_notify_extra_emails::jsonb) AS elem
      )
      WHERE balance_notify_extra_emails IS NOT NULL
        AND balance_notify_extra_emails <> '[]'
        AND balance_notify_extra_emails <> ''
        AND (balance_notify_extra_emails::jsonb -> 0) IS NOT NULL
        AND jsonb_typeof(balance_notify_extra_emails::jsonb -> 0) = 'string'
    $migrate_users$;
  END IF;
END
$$;

-- 2. Admin account quota notification emails
UPDATE settings
SET value = (
  SELECT COALESCE(
    jsonb_agg(jsonb_build_object('email', elem::text, 'disabled', false, 'verified', false)),
    '[]'::jsonb
  )::text
  FROM jsonb_array_elements_text(value::jsonb) AS elem
)
WHERE key = 'account_quota_notify_emails'
  AND value IS NOT NULL
  AND value <> '[]'
  AND value <> ''
  AND (value::jsonb -> 0) IS NOT NULL
  AND jsonb_typeof(value::jsonb -> 0) = 'string';
