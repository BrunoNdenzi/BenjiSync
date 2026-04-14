# BenjiSync — Copilot Context

## What is this project?
BenjiSync is a minimal daily task and operations logging app for a two-person team. Users log planned tasks in the morning and record results in the evening. The app is timezone-aware (users are 6 hours apart).

## Tech Stack
- **Frontend:** React Native + Expo (SDK 52+, managed workflow, Expo Router v4 file-based routing)
- **Backend/DB:** Supabase (Auth, Postgres, Realtime, Edge Functions)
- **Hosting:** Railway (for cron notification service)
- **Language:** TypeScript (strict mode)
- **State:** Zustand
- **Notifications:** Expo Notifications + expo-server-sdk

## Key Patterns
- All database types are defined in `types/index.ts`
- Supabase client is initialized in `lib/supabase.ts`
- Zustand stores are in `stores/` directory
- Reusable components are in `components/`
- Navigation uses Expo Router file-based routing in `app/` directory
- RLS policies ensure users can read all data but only write their own
- Realtime subscriptions are used on the Partner View screen
- Dark mode follows system preference
- Use `dayjs` for all date/time/timezone operations

## Categories
- drivedrop, dot_tree_removal, operations, admin, other

## Important
- This app is for exactly TWO users — no user registration, accounts are pre-created
- Always consider timezone differences when working with dates
- The full specification is in AGENT_INSTRUCTIONS.md — refer to it for all details
