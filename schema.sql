-- Winn Gayrimenkul: Supabase PostgreSQL schema
-- Run this in Supabase SQL Editor before creating user accounts.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'agent' check (role in ('admin','agent')),
  created_at timestamptz not null default now()
);

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete restrict,
  title text not null,
  kind text not null check (kind in ('Satılık','Kiralık')),
  property_type text not null default 'Daire',
  price numeric(14,2) not null check (price >= 0),
  district text not null default 'Finike',
  area numeric(10,2) check (area is null or area >= 0),
  rooms text,
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete restrict,
  name text not null,
  phone text not null default '',
  need text not null default 'Satılık daire',
  notes text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists listings_owner_id_idx on public.listings(owner_id);
create index if not exists listings_created_at_idx on public.listings(created_at desc);
create index if not exists clients_owner_id_idx on public.clients(owner_id);

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.clients enable row level security;

-- Security-definer helper avoids recursive RLS checks on the profiles table.
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Profile visibility: each user can read own profile; admins can read all profiles.
drop policy if exists "profiles_select_self_or_admin" on public.profiles;
create policy "profiles_select_self_or_admin" on public.profiles for select to authenticated
using (id = (select auth.uid()) or (select public.is_admin()));
-- A user cannot promote themselves or change their own role through the client.
drop policy if exists "profiles_update_admin_only" on public.profiles;
create policy "profiles_update_admin_only" on public.profiles for update to authenticated
using ((select public.is_admin())) with check ((select public.is_admin()));

-- Listings: admins can see/manage all; agents can see/manage only their own.
drop policy if exists "listings_select_owner_or_admin" on public.listings;
create policy "listings_select_owner_or_admin" on public.listings for select to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "listings_insert_as_self" on public.listings;
create policy "listings_insert_as_self" on public.listings for insert to authenticated
with check (owner_id = (select auth.uid()));
drop policy if exists "listings_update_owner_or_admin" on public.listings;
create policy "listings_update_owner_or_admin" on public.listings for update to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()))
with check (owner_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "listings_delete_owner_or_admin" on public.listings;
create policy "listings_delete_owner_or_admin" on public.listings for delete to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()));

-- Clients: same privacy model as listings.
drop policy if exists "clients_select_owner_or_admin" on public.clients;
create policy "clients_select_owner_or_admin" on public.clients for select to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "clients_insert_as_self" on public.clients;
create policy "clients_insert_as_self" on public.clients for insert to authenticated
with check (owner_id = (select auth.uid()));
drop policy if exists "clients_update_owner_or_admin" on public.clients;
create policy "clients_update_owner_or_admin" on public.clients for update to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()))
with check (owner_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "clients_delete_owner_or_admin" on public.clients;
create policy "clients_delete_owner_or_admin" on public.clients for delete to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()));

-- Optional helper: create profile row automatically when a new auth user is added.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name',''), 'agent');
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- IMPORTANT SETUP:
-- 1) Create your first user in Supabase Authentication > Users.
-- 2) Find their UUID and run the following, replacing UUID and name:
-- update public.profiles set full_name = 'Winn Yönetici', role = 'admin' where id = 'YOUR-AUTH-USER-UUID';
-- 3) Create up to four additional users in Authentication > Users. Their profiles default to role='agent'.
-- Never put a Supabase service_role key in this frontend project.
