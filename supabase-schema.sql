-- Spillin Tea guest-list database
-- Run this once in Supabase: SQL Editor -> New query -> Run

create extension if not exists pgcrypto;

create table if not exists public.guest_list (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 1 and 120),
  email text not null,
  interest text not null default 'Grand opening',
  source text not null default 'website',
  created_at timestamptz not null default now(),
  constraint guest_list_email_format check (
    email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
  )
);

-- Prevent duplicate signups regardless of capitalization or extra spaces.
create unique index if not exists guest_list_email_unique
  on public.guest_list (lower(trim(email)));

alter table public.guest_list enable row level security;

-- Website visitors may submit a signup, but cannot read, edit, or delete records.
drop policy if exists "Public can join guest list" on public.guest_list;
create policy "Public can join guest list"
  on public.guest_list
  for insert
  to anon
  with check (
    source = 'website'
    and char_length(trim(name)) between 1 and 120
    and char_length(trim(email)) between 5 and 254
  );

revoke all on table public.guest_list from anon, authenticated;
grant insert on table public.guest_list to anon;
grant select, insert, update, delete on table public.guest_list to service_role;

comment on table public.guest_list is 'Customer email list collected from the Spillin Tea website.';
