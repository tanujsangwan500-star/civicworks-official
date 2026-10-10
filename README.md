# CivicWorks Official Portal

CivicWorks is a public works transparency portal for Rivermouth. Residents can browse active city projects, see progress and coordination notices, and submit civic issue reports. Authenticated city staff get a separate workspace for reviewing reports and updating project information.

## Features

- Public project overview with status, progress, locations, departments, and completion dates
- Searchable project register
- Citizen issue reporting without requiring an account
- Public coordination and road-conflict summary
- Supabase Auth staff sign-in
- Role-aware staff workspace for citizen reports and project editing
- Admin, manager, and citizen roles
- Team-level project authorization policies
- Supabase Row Level Security migration
- Audit-ready data model with validation constraints
- Responsive layout for desktop and mobile

## Technology

- React
- TypeScript
- Vite
- Lucide React
- Supabase Auth and Postgres RLS

## Local setup

Install Node.js LTS, then run:

```powershell
cd "C:\Users\Lenovo\Documents\Codex\2026-10-11\github-plugin-github-openai-curated-remote\work\civicworks-official"
npm.cmd install
npm.cmd run dev
```

Open the local URL printed by Vite, usually `http://127.0.0.1:5173/`.

If PowerShell blocks `npm.ps1`, use `npm.cmd` as shown above.

## Supabase setup

1. Create a Supabase project.
2. Open **SQL Editor**.
3. Run [`supabase/migrations/001_civicworks_security.sql`](supabase/migrations/001_civicworks_security.sql).
4. Enable Email authentication under **Authentication → Providers**.
5. Create a staff user under **Authentication → Users**.
6. Copy the project URL and public anon key into `.env`:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-public-anon-key
```

Never put a Supabase service-role key in `.env` or browser code.

## Roles and permissions

The database uses three roles:

- `admin`: manage projects, teams, profiles, and reports
- `manager`: manage projects assigned to the manager's team
- `citizen`: public access and report submission

After creating the first Auth user, promote it with the real Auth UUID:

```sql
update public.profiles
set role = 'admin'
where id = 'REAL_AUTH_USER_UUID';
```

The RLS policies enforce these permissions in the database. UI visibility alone is not treated as security.

## Build

```powershell
npm.cmd run build
```

The production output is written to `dist/`.

## Push to GitHub

Create an empty repository named `civicworks-official`, then run:

```powershell
git config --global --add safe.directory "C:/Users/Lenovo/Documents/Codex/2026-10-11/github-plugin-github-openai-curated-remote/work/civicworks-official"
git remote add origin https://github.com/tanujsangwan500-star/civicworks-official.git
git branch -M main
git add .
git commit -m "Complete CivicWorks official portal"
git push -u origin main
```

## Security notes

The public anon key is intended for browser use when RLS is enabled. Passwords are handled by Supabase Auth and are never stored in this application. Configure production email verification, password reset, rate limits, and backup policies in Supabase before launch.







## Demo video lik
https://drive.google.com/file/d/1a74f4PQoDsGjS-7JnuPA8Wq0AFDT9WZA/view?usp=sharing




