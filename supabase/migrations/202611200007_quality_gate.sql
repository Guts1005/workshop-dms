alter table public.job_cards
  drop constraint job_cards_status_check;
alter table public.job_cards
  add constraint job_cards_status_check check (status in (
    'RECEIVED', 'INSPECTION_PENDING', 'ESTIMATE_SENT', 'WAITING_APPROVAL',
    'ESTIMATE_REVISION_REQUIRED', 'WORK_IN_PROGRESS', 'QC_PASSED',
    'READY_FOR_PICKUP', 'DELIVERED', 'CANCELLED'
  ));

create table public.job_quality_checks (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  inspector_name text not null check (length(trim(inspector_name)) between 2 and 120),
  work_completed boolean not null,
  checks jsonb not null check (jsonb_typeof(checks) = 'object'),
  road_test_result text not null check (
    road_test_result in ('PASSED', 'FAILED', 'NOT_REQUIRED')
  ),
  road_test_note text not null default '',
  result text not null check (result in ('PASSED', 'FAILED')),
  notes text not null default '',
  recorded_by uuid not null default auth.uid() references auth.users(id),
  recorded_by_label text not null,
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade
);

create index job_quality_checks_job_created_idx
  on public.job_quality_checks(job_card_id, created_at desc);

alter table public.job_quality_checks enable row level security;
create policy job_quality_checks_member_read
  on public.job_quality_checks for select to authenticated
  using (public.is_workshop_member(workshop_id));
grant select on public.job_quality_checks to authenticated;
revoke insert, update, delete on public.job_quality_checks from authenticated;

create or replace function public.record_job_quality_check(
  p_job_card_id uuid,
  p_inspector_name text,
  p_work_completed boolean,
  p_checks jsonb,
  p_road_test_result text,
  p_road_test_note text,
  p_notes text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_status text;
  check_passed boolean;
  qc_result text;
begin
  select wm.workshop_id
    into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if length(trim(coalesce(p_inspector_name, ''))) not between 2 and 120 then
    raise exception 'Enter the quality inspector name';
  end if;
  if p_work_completed is distinct from true then
    raise exception 'Confirm that the approved work is complete before QC';
  end if;
  if jsonb_typeof(p_checks) is distinct from 'object'
     or (select count(*) from jsonb_object_keys(
       case when jsonb_typeof(p_checks) = 'object' then p_checks else '{}'::jsonb end
     )) <> 4
     or jsonb_typeof(p_checks -> 'fluids_ok') is distinct from 'boolean'
     or jsonb_typeof(p_checks -> 'brakes_ok') is distinct from 'boolean'
     or jsonb_typeof(p_checks -> 'warning_lights_clear') is distinct from 'boolean'
     or jsonb_typeof(p_checks -> 'tools_removed') is distinct from 'boolean' then
    raise exception 'Complete each quality check';
  end if;
  if coalesce(p_road_test_result, '') not in ('PASSED', 'FAILED', 'NOT_REQUIRED') then
    raise exception 'Choose a road-test result';
  end if;
  if p_road_test_result in ('FAILED', 'NOT_REQUIRED')
     and length(trim(coalesce(p_road_test_note, ''))) < 2 then
    raise exception 'Add a reason for a failed or skipped road test';
  end if;
  if length(coalesce(p_road_test_note, '')) > 1000
     or length(coalesce(p_notes, '')) > 2000 then
    raise exception 'Quality notes are too long';
  end if;

  select jc.status
    into current_status
    from public.job_cards jc
   where jc.id = p_job_card_id
     and jc.workshop_id = current_workshop
   for update;
  if not found or current_status <> 'WORK_IN_PROGRESS' then
    raise exception 'Quality checks are only available while work is in progress';
  end if;

  check_passed := (p_checks ->> 'fluids_ok')::boolean
    and (p_checks ->> 'brakes_ok')::boolean
    and (p_checks ->> 'warning_lights_clear')::boolean
    and (p_checks ->> 'tools_removed')::boolean;
  qc_result := case
    when check_passed and p_road_test_result <> 'FAILED' then 'PASSED'
    else 'FAILED'
  end;

  insert into public.job_quality_checks (
    workshop_id, job_card_id, inspector_name, work_completed, checks,
    road_test_result, road_test_note, result, notes, recorded_by_label
  ) values (
    current_workshop, p_job_card_id, trim(p_inspector_name), p_work_completed,
    p_checks, p_road_test_result, trim(coalesce(p_road_test_note, '')),
    qc_result, trim(coalesce(p_notes, '')),
    coalesce((select auth.jwt() ->> 'email'), (select auth.uid())::text)
  );

  if qc_result = 'PASSED' then
    update public.job_cards
       set status = 'QC_PASSED', updated_at = now()
     where id = p_job_card_id and workshop_id = current_workshop;
  end if;
  return qc_result;
end;
$$;

revoke all on function public.record_job_quality_check(
  uuid, text, boolean, jsonb, text, text, text
) from public, anon;
grant execute on function public.record_job_quality_check(
  uuid, text, boolean, jsonb, text, text, text
) to authenticated;
