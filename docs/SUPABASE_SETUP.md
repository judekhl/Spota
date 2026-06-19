# Spota — Supabase Setup

## 1. Create a Supabase Account
- Go to [supabase.com](https://supabase.com) and sign up.
- Verify your email.

## 2. Create a New Project
- Click **New Project**.
- Set a project name (e.g. `spota`).
- Choose a strong database password — save it somewhere safe.
- Select the region closest to Israel (e.g. EU West).
- Click **Create new project** and wait for provisioning (~1 minute).

## 3. Find Your Project URL and Anon Key
- In your project dashboard, go to **Settings → API**.
- You will find:
  - **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
  - **anon / public key** — a long JWT string under "Project API keys"
- These two values are used to connect FlutterFlow to Supabase.

> **Never paste your service_role key into any AI chat or public place.**
> The anon key is safe to use in the app. The service_role key is not — it bypasses all security rules.

## 4. Enable Email Auth
- Go to **Authentication → Providers**.
- Confirm **Email** is enabled (it is by default).
- This is used for operator login.

## 5. Note Your Credentials for FlutterFlow
When connecting FlutterFlow to Supabase you will need:
- Project URL
- Anon key

Keep these in a private notes file or password manager — not in any AI chat.

## Next Step
Once the project is set up, create the database tables as defined in `docs/DATABASE_SCHEMA.md`.
