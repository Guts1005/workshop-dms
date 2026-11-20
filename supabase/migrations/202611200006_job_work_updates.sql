create table public.job_work_updates (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  update_type text not null check (
    update_type in ('PROGRESS_NOTE', 'WAITING_FOR_PARTS', 'CUSTOMER_UPDATE')
  ),
  note text not null check (length(trim(note)) between 2 and 1000),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_by_label text not null,
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade
);

create index job_work_updates_job_created_idx
  on public.job_work_updates(job_card_id, created_at desc);

alter table public.job_work_updates enable row level security;
create policy job_work_updates_member_read
  on public.job_work_updates for select to authenticated
  using (public.is_workshop_member(workshop_id));
grant select on public.job_work_updates to authenticated;
revoke insert, update, delete on public.job_work_updates from authenticated;

create or replace function public.record_job_work_update(
  p_job_card_id uuid,
  p_update_type text,
  p_note text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  update_id uuid;
begin
  select wm.workshop_id
    into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if coalesce(p_update_type, '') not in (
    'PROGRESS_NOTE', 'WAITING_FOR_PARTS', 'CUSTOMER_UPDATE'
  ) then
    raise exception 'Choose a valid progress update type';
  end if;
  if length(trim(coalesce(p_note, ''))) not between 2 and 1000 then
    raise exception 'Enter a progress note between 2 and 1000 characters';
  end if;
  if not exists (
    select 1 from public.job_cards jc
     where jc.id = p_job_card_id
       and jc.workshop_id = current_workshop
       and jc.status = 'WORK_IN_PROGRESS'
  ) then
    raise exception 'Progress updates are only available while work is in progress';
  end if;

  insert into public.job_work_updates (
    workshop_id, job_card_id, update_type, note, created_by_label
  ) values (
    current_workshop, p_job_card_id, p_update_type, trim(p_note),
    coalesce((select auth.jwt() ->> 'email'), (select auth.uid())::text)
  ) returning id into update_id;
  return update_id;
end;
$$;

revoke all on function public.record_job_work_update(uuid, text, text) from public, anon;
grant execute on function public.record_job_work_update(uuid, text, text) to authenticated;
