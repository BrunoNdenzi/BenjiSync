# BenjiSync

**BenjiSync** — Daily Task & Operations Logger for a two-person team. Built with Expo (React Native), Supabase, and Railway.

## What is this?

A minimal, production-ready mobile app for exactly **two users** (Bruno and his business partner) to:
- **Morning:** Log planned tasks/activities/operations for the day
- **Evening:** Record results, statuses, blockers, and time spent
- **Anytime:** View your partner's logs in real-time

The app is **timezone-aware** (users are 6 hours apart) and sends push notification reminders.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React Native + Expo (SDK 52+, managed workflow, Expo Router v4) |
| **Backend/DB** | Supabase (Auth, Postgres, Realtime, Edge Functions) |
| **Hosting** | Railway (for cron notification service) |
| **Language** | TypeScript (strict mode) |
| **State** | Zustand |
| **Notifications** | Expo Notifications + expo-server-sdk |

## Getting Started

### Prerequisites
- Node.js 18+
- Expo CLI (`npm install -g expo-cli`)
- A Supabase project
- Expo Go app on your phone (for development)

### Setup

1. **Clone the repo:**
   ```bash
   git clone https://github.com/BrunoNdenzi/BenjiSync.git
   cd BenjiSync
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   Fill in your Supabase URL and keys in `.env`.

4. **Run the database migration:**
   Execute `supabase/migrations/001_initial_schema.sql` in your Supabase SQL editor.

5. **Create the two user accounts** in Supabase Auth dashboard, then run the seed script:
   Execute `supabase/seed.sql` in your Supabase SQL editor (update the UUIDs to match your auth users).

6. **Start the app:**
   ```bash
   npx expo start
   ```

### Environment Variables

See `.env.example` for all required variables.

## Project Structure

```
benjisync/
├── app/                          -- Expo Router file-based routing
│   ├── _layout.tsx               -- Root layout, auth provider, notification setup
│   ├── (auth)/
│   │   ├── _layout.tsx
│   │   └── login.tsx
│   └── (tabs)/
│       ├── _layout.tsx           -- Tab navigator config
│       ├── today.tsx
│       ├── partner.tsx
│       ├── history.tsx
│       └── settings.tsx
├── components/                   -- Reusable UI components
├── lib/                          -- Supabase client, notifications, utilities
├── stores/                       -- Zustand state stores
├── types/                        -- TypeScript type definitions
├── supabase/                     -- Migrations, seed data, edge functions
└── assets/                       -- App icon, splash screen, images
```

## Agent Instructions

**For the coding agent:** See `AGENT_INSTRUCTIONS.md` for the complete, detailed build specification.

## Categories

- 🚗 **DriveDrop** — DriveDrop app development work
- 🌳 **Dot & Tree Removal** — Dot and tree removal operations
- ⚙️ **Operations** — General business operations
- 📋 **Admin** — Administrative tasks
- 📌 **Other** — Everything else

## License

Private — For internal use only.
