begin;
create table public.lab_owner (id uuid primary key references auth.users(id) on delete cascade);
alter table public.lab_owner enable row level security;
revoke all on public.lab_owner from anon, authenticated;

create function public.is_lab_owner() returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.lab_owner where id = auth.uid()); $$;
revoke all on function public.is_lab_owner() from public;
grant execute on function public.is_lab_owner() to authenticated;

create table public.projects (
 id uuid primary key default gen_random_uuid(),
 name text not null check (length(btrim(name)) > 0),
 description text not null default '',
 repo_url text not null default '' check (repo_url = '' or repo_url ~ '^https?://'),
 created_at timestamptz not null default now()
);
create table public.thoughts (
 id uuid primary key default gen_random_uuid(),
 body text not null check (length(btrim(body)) > 0),
 tags text[] not null default '{}',
 parent_id uuid references public.thoughts(id) on delete set null,
 project_ids uuid[] not null default '{}',
 created_at timestamptz not null default now(),
 check (parent_id is distinct from id)
);
create index thoughts_time on public.thoughts(created_at desc,id);
create index thoughts_parent on public.thoughts(parent_id);
create index thoughts_tags on public.thoughts using gin(tags);
create table public.pages (
 id text primary key check (id in ('vision','eurus')),
 body text not null default ''
);
insert into public.pages(id) values ('vision'), ('eurus');

alter table public.projects enable row level security;
alter table public.thoughts enable row level security;
alter table public.pages enable row level security;
grant select on public.projects, public.thoughts, public.pages to anon, authenticated;
revoke insert, update, delete on public.projects, public.thoughts, public.pages from anon, authenticated;
grant insert (name,description,repo_url), update (name,description,repo_url), delete on public.projects to authenticated;
grant insert (body,tags,parent_id,project_ids), update (body,tags,project_ids), delete on public.thoughts to authenticated;
grant update (body) on public.pages to authenticated;

create policy public_projects on public.projects for select to anon, authenticated using (true);
create policy public_thoughts on public.thoughts for select to anon, authenticated using (true);
create policy public_pages on public.pages for select to anon, authenticated using (true);
create policy owner_projects on public.projects for all to authenticated using ((select public.is_lab_owner())) with check ((select public.is_lab_owner()));
create policy owner_thoughts on public.thoughts for all to authenticated using ((select public.is_lab_owner())) with check ((select public.is_lab_owner()));
create policy owner_pages on public.pages for update to authenticated using ((select public.is_lab_owner())) with check ((select public.is_lab_owner()));

create function public.validate_projects() returns trigger language plpgsql set search_path = '' as $$
begin
 if exists (select 1 from unnest(new.project_ids) as p(id) where not exists(select 1 from public.projects where id=p.id)) then
 raise exception 'Unknown project';
 end if;
 return new;
end;
$$;
create trigger thought_projects before insert or update of project_ids on public.thoughts for each row execute function public.validate_projects();

create function public.remove_project_links() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 update public.thoughts set project_ids=array_remove(project_ids,old.id) where old.id=any(project_ids);
 return old;
end;
$$;
revoke all on function public.remove_project_links() from public;
create trigger project_deleted after delete on public.projects for each row execute function public.remove_project_links();
commit;

-- After creating the administrator in Authentication > Users, run separately:
-- insert into public.lab_owner(id) values ('YOUR-AUTH-USER-UUID');
