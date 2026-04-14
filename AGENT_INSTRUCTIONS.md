# BenjiSync — Complete Build Specification

> **For the coding agent:** Follow every section of this document to build the BenjiSync app. Do not skip any section. When in doubt, refer back to this file.

---

## 1. Project Overview

Build a **minimal, production-ready mobile app** called **BenjiSync** for exactly **two users** (Bruno and his business partner) to log daily planned tasks each morning and record results/outcomes each evening. The users are in **different timezones (6 hours apart)**. The app must be timezone-aware, support push notifications, and provide visibility into each other's daily logs.

---

## 2. Tech Stack (Non-Negotiable)

| Layer | Technology |
|-------|-----------|
| **Frontend** | React Native with **Expo** (managed workflow, SDK 52+) |
| **Backend/Database** | **Supabase** (Auth, Postgres DB, Realtime, Edge Functions) |
| **Backend Hosting** | **Railway** (for cron notification service) |
| **Push Notifications** | Expo Notifications + Supabase Edge Functions for scheduling |
| **Language** | TypeScript throughout (strict mode) |
| **State Management** | Zustand |
| **Navigation** | Expo Router v4 (file-based routing) |
| **Date/Time** | dayjs (with timezone plugin) |

---

## 3. Database Schema (Supabase Postgres)

Run these in order in the Supabase SQL Editor. The full migration file is at `supabase/migrations/001_initial_schema.sql`.

### Table: `profiles`
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  expo_push_token TEXT,
  partner_id UUID REFERENCES profiles(id),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `daily_logs`
```sql
CREATE TABLE daily_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, log_date)
);
```

### Table: `tasks`
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_log_id UUID NOT NULL REFERENCES daily_logs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('drivedrop', 'dot_tree_removal', 'operations', 'admin', 'other')), 
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'completed', 'in_progress', 'blocked', 'deferred', 'cancelled')),
  result_notes TEXT,
  time_spent_minutes INTEGER,
  blockers TEXT,
  position INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `notification_settings`
```sql
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  morning_reminder_enabled BOOLEAN DEFAULT TRUE,
  morning_reminder_time TIME DEFAULT '08:00',
  evening_reminder_enabled BOOLEAN DEFAULT TRUE,
  evening_reminder_time TIME DEFAULT '18:00',
  partner_logged_notification BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS)
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view all daily logs" ON daily_logs FOR SELECT USING (true);
CREATE POLICY "Users can insert own daily logs" ON daily_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own daily logs" ON daily_logs FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view all tasks" ON tasks FOR SELECT USING (true);
CREATE POLICY "Users can insert own tasks" ON tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tasks" ON tasks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own tasks" ON tasks FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own notification settings" ON notification_settings FOR ALL USING (auth.uid() = user_id);
```

---

## 4. App Screens & Navigation Structure
```
app/
├── (auth)/
│   ├── login.tsx              -- Email/password login (Supabase Auth)
│   └── _layout.tsx
├── (tabs)/
│   ├── _layout.tsx            -- Bottom tab navigator
│   ├── today.tsx              -- Main screen: today's log
│   ├── partner.tsx            -- View partner's logs (read-only)
│   ├── history.tsx            -- Calendar view of past logs
│   └── settings.tsx           -- Profile, timezone, notification preferences
└── _layout.tsx                -- Root layout with auth guard
```

### 4.1 Today Screen (`today.tsx`) — Main Screen
- **Header:** Shows current date in user's local timezone, greeting with user's name
- **Two-section layout with toggle or scroll:**
  - **☀️ Morning Plan Section:**
    - List of planned tasks for today
    - FAB or "Add Task" button to add new tasks
    - Each task card shows: title, category badge (color-coded), priority indicator
    - Swipe-to-delete on tasks
    - If no tasks yet, show encouraging empty state: "What's on the agenda today?"
  - **🌙 Evening Results Section:**
    - Same tasks from morning, but now each has:
      - Status dropdown/selector (completed ✅, in progress 🔄, blocked 🚫, deferred ⏩, cancelled ❌)
      - Result notes text input
      - Time spent (optional, in hours:minutes picker)
      - Blockers text input (shown conditionally when status = 'blocked')
    - "Submit Evening Log" button that locks in the results
- **Partner Status Indicator:** Small badge/banner showing "Partner has/hasn't logged today"

### 4.2 Partner View Screen (`partner.tsx`)
- **Read-only** view of partner's daily log
- Shows partner's name, timezone, and current time in their timezone
- Displays their morning plan and evening results (if submitted)
- Date picker to view partner's previous days
- If partner hasn't logged yet today, show: "Your partner hasn't logged yet today"
- **Supabase Realtime subscription** — updates live when partner makes changes

### 4.3 History Screen (`history.tsx`)
- **Calendar view** (use `react-native-calendars`)
- Days with logs are marked with dots (green = completed evening log, yellow = only morning plan)
- Tapping a date shows that day's full log (both users side by side or tabbed)
- **Weekly/Monthly summary stats:**
  - Total tasks planned vs completed
  - Breakdown by category (pie chart or simple bar)
  - Completion rate percentage

### 4.4 Settings Screen (`settings.tsx`)
- Display name edit
- Timezone selector (searchable dropdown of IANA timezones)
- Notification preferences:
  - Morning reminder toggle + time picker
  - Evening reminder toggle + time picker
  - Partner activity notification toggle
- Sign out button
- App version info

### 4.5 Login Screen (`login.tsx`)
- Simple email + password auth via Supabase
- No sign-up screen needed (pre-create the 2 accounts via Supabase dashboard)
- "Forgot password" link → Supabase password reset email
- Clean, minimal design with app logo

---

## 5. Task Add/Edit Modal

When adding or editing a task, show a form/bottom sheet with:
- **Title** (required, text input)
- **Description** (optional, multiline text input)
- **Category** (required, selectable chips):
  - 🚗 DriveDrop (`drivedrop`) — blue `#2563EB`
  - 🌳 Dot & Tree Removal (`dot_tree_removal`) — green `#16A34A`
  - ⚙️ Operations (`operations`) — orange `#EA580C`
  - 📋 Admin (`admin`) — gray `#6B7280`
  - 📌 Other (`other`) — purple `#9333EA`
- **Priority** (required, selectable):
  - 🔴 High — `#DC2626`
  - 🟡 Medium — `#EAB308`
  - 🟢 Low — `#16A34A`
- Save / Cancel buttons

---

## 6. Push Notifications

### 6.1 Expo Push Token Registration
On app launch after successful auth, register the device's Expo push token using `expo-notifications` and save it to `profiles.expo_push_token` in Supabase.

### 6.2 Notification Cron Service (Railway)
Build a small Node.js/Express service deployed on Railway:
- **Single cron endpoint** that runs every 15 minutes
- For each user, query their `notification_settings` and `profiles.timezone`
- Convert current UTC time to each user's local time
- **Morning reminder:** If local time matches `morning_reminder_time` (within 15-min window) AND user has NOT created today's log → send push: "☀️ Good morning! What's on your agenda today?"
- **Evening reminder:** If local time matches `evening_reminder_time` (within 15-min window) AND user has tasks still with status 'planned' → send push: "🌙 Time to log your results for today!"
- **Partner notification:** When a user submits their log and their partner has `partner_logged_notification` enabled → send push: "📋 Your partner just logged their day — check it out!"
- Use `expo-server-sdk` to send push notifications via Expo's push API

### 6.3 Railway Service Structure
```
notification-service/
├── src/
│   ├── index.ts          -- Express server with cron endpoint
│   ├── supabase.ts       -- Supabase client (service role key)
│   ├── notifications.ts  -- Expo push notification logic
│   └── cron.ts           -- Cron job logic
├── package.json
├── tsconfig.json
└── Dockerfile
```

---

## 7. Realtime Subscriptions

On the **Partner View** screen, subscribe to Supabase Realtime changes on:
- `daily_logs` table (filtered to partner's user_id)
- `tasks` table (filtered to partner's user_id)

When partner adds/updates tasks, the view updates in real-time. Show a subtle toast when new data arrives.

---

## 8. UI/UX Design Guidelines

- **Color Palette:**
  - Primary: `#2563EB` (blue)
  - Success: `#16A34A` (green)
  - Warning: `#EAB308` (yellow)
  - Danger: `#DC2626` (red)
  - Background Light: `#F8FAFC`
  - Background Dark: `#0F172A`
  - Surface Light: `#FFFFFF`
  - Surface Dark: `#1E293B`
- **Dark mode support** — follow system preference using `useColorScheme()`
- **Typography:** System fonts or Inter via `expo-font`
- **Animations:** Subtle — use `react-native-reanimated` for task list reordering and status changes
- **Haptic feedback:** Light haptics on task completion toggle using `expo-haptics`
- **Empty states:** Friendly icons with helpful text for every empty state
- **Loading states:** Skeleton loaders, NOT spinners

---

## 9. Key Dependencies

```json
{
  "dependencies": {
    "expo": "~52.0.0",
    "expo-router": "~4.0.0",
    "expo-notifications": "~0.29.0",
    "expo-haptics": "~13.0.0",
    "expo-font": "~13.0.0",
    "expo-splash-screen": "~0.29.0",
    "expo-device": "~7.0.0",
    "@supabase/supabase-js": "^2.45.0",
    "@react-native-async-storage/async-storage": "^2.0.0",
    "zustand": "^5.0.0",
    "react-native-calendars": "^1.1306.0",
    "react-native-reanimated": "~3.16.0",
    "react-native-gesture-handler": "~2.20.0",
    "react-native-safe-area-context": "~4.14.0",
    "dayjs": "^1.11.0",
    "expo-dev-client": "~5.0.0"
  }
}
```

---

## 10. Project File Structure

```
benjisync/
├── app/
│   ├── _layout.tsx
│   ├── (auth)/
│   │   ├── _layout.tsx
│   │   └── login.tsx
│   └── (tabs)/
│       ├── _layout.tsx
│       ├── today.tsx
│       ├── partner.tsx
│       ├── history.tsx
│       └── settings.tsx
├── components/
│   ├── TaskCard.tsx
│   ├── TaskForm.tsx
│   ├── CategoryBadge.tsx
│   ├── PriorityIndicator.tsx
│   ├── StatusSelector.tsx
│   ├── DaySummaryCard.tsx
│   ├── PartnerStatusBanner.tsx
│   ├── EmptyState.tsx
│   └── SkeletonLoader.tsx
├── lib/
│   ├── supabase.ts
│   ├── notifications.ts
│   ├── timezone.ts
│   └── constants.ts
├── stores/
│   ├── authStore.ts
│   ├── taskStore.ts
│   └── settingsStore.ts
├── types/
│   └── index.ts
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql
│   ├── seed.sql
│   └── functions/
│       └── send-reminder/
│           └── index.ts
├── notification-service/
│   ├── src/
│   │   ├── index.ts
│   │   ├── supabase.ts
│   │   ├── notifications.ts
│   │   └── cron.ts
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
├── assets/
├── app.json
├── tsconfig.json
├── package.json
├── .env.example
└── README.md
```

---

## 11. Environment Variables

```env
# Expo App
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Railway Notification Service
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
EXPO_ACCESS_TOKEN=your-expo-access-token
```

---

## 12. Acceptance Criteria

1. ✅ Both users can log in with email/password via Supabase Auth
2. ✅ Users can add, edit, and delete morning plan tasks with title, category, priority, and description
3. ✅ Users can update task statuses and add result notes in the evening
4. ✅ Users can view their partner's daily log in real-time (read-only)
5. ✅ Calendar history view shows all past logs with day-level completion indicators
6. ✅ Push notifications fire at the correct local time for each user's timezone
7. ✅ App respects timezone differences — dates and times display in each user's local timezone
8. ✅ Dark mode support following system preference
9. ✅ All data persists in Supabase with proper RLS policies
10. ✅ App builds and runs on Android via Expo (ready for Google Play Store)
11. ✅ Railway notification service is deployable and functional
12. ✅ TypeScript strict mode with no type errors

---