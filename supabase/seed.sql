-- BenjiSync Seed Data
-- 
-- INSTRUCTIONS:
-- 1. First, create two users in Supabase Auth dashboard (Authentication > Users > Add user)
-- 2. Copy their UUIDs and replace the placeholders below
-- 3. Run this script in the Supabase SQL Editor
--

-- Replace these with the actual UUIDs from Supabase Auth
DO $$
DECLARE
  user1_id UUID := '00000000-0000-0000-0000-000000000001'; -- Replace with Bruno's auth user UUID
  user2_id UUID := '00000000-0000-0000-0000-000000000002'; -- Replace with Partner's auth user UUID
BEGIN

  -- Create profiles
  INSERT INTO profiles (id, display_name, timezone, partner_id) VALUES
    (user1_id, 'Bruno', 'Africa/Johannesburg', user2_id),
    (user2_id, 'Partner', 'America/New_York', user1_id)
  ON CONFLICT (id) DO NOTHING;

  -- Create notification settings with sensible defaults
  INSERT INTO notification_settings (user_id, morning_reminder_enabled, morning_reminder_time, evening_reminder_enabled, evening_reminder_time, partner_logged_notification) VALUES
    (user1_id, TRUE, '08:00', TRUE, '18:00', TRUE),
    (user2_id, TRUE, '08:00', TRUE, '18:00', TRUE)
  ON CONFLICT (user_id) DO NOTHING;

END $$;
