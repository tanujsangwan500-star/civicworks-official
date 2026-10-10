-- CivicWorks security baseline. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

do $$ begin
  create type public.app_role as enum ('admin', 'manager', 'citizen');
exception when duplicate_object then null; end $$;

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 120),
  manager_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (display_name is null or length(trim(display_name)) between 2 and 120),
  role public.app_role not null default 'citizen',
  team_id uuid references public.teams(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id text primary key check (id ~ '^CW-[0-9]{3,}$'),
  title text not null check (length(trim(title)) between 3 and 180),
  location text not null check (length(trim(location)) between 2 and 180),
  department text not null check (length(trim(department)) between 2 and 120),
  status text not null check (status in ('Planned','In progress','Delayed','Completed')),
  progress integer not null default 0 check (progress between 0 and 100),
  end_date date,
  team_id uuid references public.teams(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'Completed' or progress = 100)
);

create table if not exists public.citizen_reports (
  id uuid primary key default gen_random_uuid(),
  category text not null check (length(trim(category)) between 2 and 80),
  location text not null check (length(trim(location)) between 2 and 180),
  description text not null check (length(trim(description)) between 10 and 3000),
  project_id text references public.projects(id) on delete set null,
  status text not null default 'Submitted' check (status in ('Submitted','Under Review','Resolved','Closed')),
  response text,
  submitted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null check (length(trim(action)) between 2 and 80),
  entity_type text not null,
  entity_id text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.cw_current_role() returns public.app_role
language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.cw_current_team_id() returns uuid
language sql stable security definer set search_path = public
as $$ select team_id from public.profiles where id = auth.uid() $$;

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists projects_updated_at on public.projects;
create trigger projects_updated_at before update on public.projects for each row execute function public.set_updated_at();
drop trigger if exists reports_updated_at on public.citizen_reports;
create trigger reports_updated_at before update on public.citizen_reports for each row execute function public.set_updated_at();

alter table public.teams enable row level security;
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.citizen_reports enable row level security;
alter table public.audit_log enable row level security;

drop policy if exists public_projects_read on public.projects;
create policy public_projects_read on public.projects for select using (true);
drop policy if exists admin_projects_write on public.projects;
create policy admin_projects_write on public.projects for all using (public.cw_current_role() = 'admin') with check (public.cw_current_role() = 'admin');
drop policy if exists manager_projects_update on public.projects;
create policy manager_projects_update on public.projects for update using (public.cw_current_role() = 'manager' and team_id = public.cw_current_team_id()) with check (team_id = public.cw_current_team_id());

drop policy if exists own_profile_read on public.profiles;
create policy own_profile_read on public.profiles for select using (id = auth.uid() or public.cw_current_role() = 'admin');
drop policy if exists admin_profile_write on public.profiles;
create policy admin_profile_write on public.profiles for all using (public.cw_current_role() = 'admin') with check (public.cw_current_role() = 'admin');
drop policy if exists team_read on public.teams;
create policy team_read on public.teams for select using (id = public.cw_current_team_id() or public.cw_current_role() = 'admin');
drop policy if exists admin_team_write on public.teams;
create policy admin_team_write on public.teams for all using (public.cw_current_role() = 'admin') with check (public.cw_current_role() = 'admin');

drop policy if exists reports_public_insert on public.citizen_reports;
create policy reports_public_insert on public.citizen_reports for insert with check (true);
drop policy if exists reports_staff_read on public.citizen_reports;
create policy reports_staff_read on public.citizen_reports for select using (public.cw_current_role() in ('admin','manager'));
drop policy if exists admin_reports_write on public.citizen_reports;
create policy admin_reports_write on public.citizen_reports for update using (public.cw_current_role() = 'admin') with check (public.cw_current_role() = 'admin');

drop policy if exists audit_admin_read on public.audit_log;
create policy audit_admin_read on public.audit_log for select using (public.cw_current_role() = 'admin');
drop policy if exists audit_staff_insert on public.audit_log;
create policy audit_staff_insert on public.audit_log for insert with check (actor_id = auth.uid());

-- Create a profile automatically for every new Auth user.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles (id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'display_name', new.email)); return new; end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

