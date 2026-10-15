-- AETHEL COLLECTIVE shared books for Supabase.
-- Run this entire script once in Supabase Dashboard > SQL Editor.
-- The browser app uses only the project's publishable/anon key. Never add a service_role key to the app.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table if not exists public.aethel_workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.aethel_members (
  workspace_id uuid not null references public.aethel_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  role text not null check (role in ('owner','editor','viewer')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.aethel_books (
  workspace_id uuid primary key references public.aethel_workspaces(id) on delete cascade,
  revision bigint not null default 1 check (revision > 0),
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  updated_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.aethel_backups (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.aethel_workspaces(id) on delete cascade,
  revision bigint not null,
  reason text not null default 'Restore point',
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists aethel_backups_workspace_created_idx
  on public.aethel_backups(workspace_id, created_at desc);
create index if not exists aethel_members_user_idx
  on public.aethel_members(user_id, workspace_id);

alter table public.aethel_workspaces enable row level security;
alter table public.aethel_members enable row level security;
alter table public.aethel_books enable row level security;
alter table public.aethel_backups enable row level security;

revoke all on public.aethel_workspaces, public.aethel_members,
  public.aethel_books, public.aethel_backups from anon, authenticated;
grant select on public.aethel_workspaces, public.aethel_members,
  public.aethel_books, public.aethel_backups to authenticated;

create or replace function private.aethel_is_member(p_workspace_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.aethel_members m
    where m.workspace_id = p_workspace_id
      and m.user_id = (select auth.uid())
  );
$$;

create or replace function private.aethel_can_write(p_workspace_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.aethel_members m
    where m.workspace_id = p_workspace_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','editor')
  );
$$;

create or replace function private.aethel_is_owner(p_workspace_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.aethel_members m
    where m.workspace_id = p_workspace_id
      and m.user_id = (select auth.uid())
      and m.role = 'owner'
  );
$$;
revoke all on function private.aethel_is_member(uuid) from public, anon;
revoke all on function private.aethel_can_write(uuid) from public, anon;
revoke all on function private.aethel_is_owner(uuid) from public, anon;
grant execute on function private.aethel_is_member(uuid) to authenticated;
grant execute on function private.aethel_can_write(uuid) to authenticated;
grant execute on function private.aethel_is_owner(uuid) to authenticated;

drop policy if exists aethel_workspace_member_read on public.aethel_workspaces;
create policy aethel_workspace_member_read on public.aethel_workspaces
  for select to authenticated using (private.aethel_is_member(id));
drop policy if exists aethel_member_list_read on public.aethel_members;
create policy aethel_member_list_read on public.aethel_members
  for select to authenticated using (private.aethel_is_member(workspace_id));
drop policy if exists aethel_book_member_read on public.aethel_books;
create policy aethel_book_member_read on public.aethel_books
  for select to authenticated using (private.aethel_is_member(workspace_id));
drop policy if exists aethel_backup_member_read on public.aethel_backups;
create policy aethel_backup_member_read on public.aethel_backups
  for select to authenticated using (private.aethel_is_member(workspace_id));


create or replace function public.aethel_create_workspace(p_name text, p_data jsonb)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare v_workspace_id uuid;
begin
  if (select auth.uid()) is null then raise exception 'Sign in required.'; end if;
  if jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 8000000 then
    raise exception 'Book data is invalid or exceeds the 8 MB limit.';
  end if;
  insert into public.aethel_workspaces(name, created_by)
    values (coalesce(nullif(trim(p_name), ''), 'AETHEL COLLECTIVE'), (select auth.uid()))
    returning id into v_workspace_id;
  insert into public.aethel_members(workspace_id, user_id, email, role)
    values (v_workspace_id, (select auth.uid()),
      coalesce((select email from auth.users where id=(select auth.uid())), ''), 'owner');
  insert into public.aethel_books(workspace_id, revision, data, updated_by)
    values (v_workspace_id, 1, p_data, (select auth.uid()));
  return jsonb_build_object('workspace_id', v_workspace_id, 'revision', 1);
end;
$$;

create or replace function public.aethel_invite_member(
  p_workspace_id uuid, p_email text, p_role text default 'editor'
)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid; v_email text;
begin
  if not private.aethel_is_owner(p_workspace_id) then raise exception 'Only the workspace owner can add partners.'; end if;
  if p_role not in ('editor','viewer') then raise exception 'Choose editor or viewer access.'; end if;
  v_email := lower(trim(coalesce(p_email,'')));
  if v_email = '' then raise exception 'Partner email is required.'; end if;
  select u.id into v_user_id from auth.users u where lower(u.email)=v_email limit 1;
  if v_user_id is null then raise exception 'That partner must create their Supabase sign-in first.'; end if;
  insert into public.aethel_members(workspace_id,user_id,email,role)
    values (p_workspace_id,v_user_id,v_email,p_role)
    on conflict (workspace_id,user_id) do update set email=excluded.email, role=excluded.role;
  return jsonb_build_object('email',v_email,'role',p_role);
end;
$$;

create or replace function public.aethel_save_book(
  p_workspace_id uuid, p_expected_revision bigint, p_data jsonb
)
returns bigint
language plpgsql security definer set search_path = ''
as $$
declare v_book public.aethel_books%rowtype; v_revision bigint;
begin
  if not private.aethel_can_write(p_workspace_id) then raise exception 'You do not have edit access to this workspace.'; end if;
  if jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 8000000 then
    raise exception 'Book data is invalid or exceeds the 8 MB limit.';
  end if;
  select * into v_book from public.aethel_books
    where workspace_id=p_workspace_id for update;
  if not found then raise exception 'Shared book record not found.'; end if;
  if v_book.revision <> p_expected_revision then
    raise exception using errcode='40001', message='Cloud revision conflict: another partner has saved newer books. Load the shared copy before syncing.';
  end if;
  if not exists (
    select 1 from public.aethel_backups b
    where b.workspace_id=p_workspace_id
      and b.reason='Automatic daily restore point'
      and b.created_at::date=(now() at time zone 'utc')::date
  ) then
    insert into public.aethel_backups(workspace_id,revision,reason,data,created_by)
      values (p_workspace_id,v_book.revision,'Automatic daily restore point',v_book.data,(select auth.uid()));
  end if;
  update public.aethel_books set data=p_data,revision=v_book.revision+1,
    updated_by=(select auth.uid()),updated_at=now()
    where workspace_id=p_workspace_id returning revision into v_revision;
  return v_revision;
end;
$$;

create or replace function public.aethel_create_backup(p_workspace_id uuid, p_reason text default 'Manual restore point')
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_id uuid;
begin
  if not private.aethel_can_write(p_workspace_id) then raise exception 'You do not have edit access to this workspace.'; end if;
  insert into public.aethel_backups(workspace_id,revision,reason,data,created_by)
    select b.workspace_id,b.revision,coalesce(nullif(trim(p_reason),''),'Manual restore point'),b.data,(select auth.uid())
      from public.aethel_books b where b.workspace_id=p_workspace_id
    returning id into v_id;
  if v_id is null then raise exception 'Shared book record not found.'; end if;
  return v_id;
end;
$$;

create or replace function public.aethel_restore_backup(
  p_workspace_id uuid, p_backup_id uuid, p_expected_revision bigint
)
returns bigint
language plpgsql security definer set search_path = ''
as $$
declare v_book public.aethel_books%rowtype; v_restore jsonb; v_revision bigint;
begin
  if not private.aethel_can_write(p_workspace_id) then raise exception 'You do not have edit access to this workspace.'; end if;
  select * into v_book from public.aethel_books where workspace_id=p_workspace_id for update;
  if not found then raise exception 'Shared book record not found.'; end if;
  if v_book.revision <> p_expected_revision then
    raise exception using errcode='40001', message='Cloud revision conflict: reload the shared workspace before restoring.';
  end if;
  select b.data into v_restore from public.aethel_backups b
    where b.id=p_backup_id and b.workspace_id=p_workspace_id;
  if v_restore is null then raise exception 'Restore point not found in this workspace.'; end if;
  insert into public.aethel_backups(workspace_id,revision,reason,data,created_by)
    values (p_workspace_id,v_book.revision,'Before restoring an earlier snapshot',v_book.data,(select auth.uid()));
  update public.aethel_books set data=v_restore,revision=v_book.revision+1,
    updated_by=(select auth.uid()),updated_at=now()
    where workspace_id=p_workspace_id returning revision into v_revision;
  return v_revision;
end;
$$;

revoke all on function public.aethel_create_workspace(text,jsonb) from public, anon;
revoke all on function public.aethel_invite_member(uuid,text,text) from public, anon;
revoke all on function public.aethel_save_book(uuid,bigint,jsonb) from public, anon;
revoke all on function public.aethel_create_backup(uuid,text) from public, anon;
revoke all on function public.aethel_restore_backup(uuid,uuid,bigint) from public, anon;
grant execute on function public.aethel_create_workspace(text,jsonb) to authenticated;
grant execute on function public.aethel_invite_member(uuid,text,text) to authenticated;
grant execute on function public.aethel_save_book(uuid,bigint,jsonb) to authenticated;
grant execute on function public.aethel_create_backup(uuid,text) to authenticated;
grant execute on function public.aethel_restore_backup(uuid,uuid,bigint) to authenticated;
