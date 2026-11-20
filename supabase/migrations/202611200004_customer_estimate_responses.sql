alter table public.job_cards
  drop constraint job_cards_status_check;
alter table public.job_cards
  add constraint job_cards_status_check check (status in (
    'RECEIVED', 'INSPECTION_PENDING', 'ESTIMATE_SENT', 'WAITING_APPROVAL',
    'ESTIMATE_REVISION_REQUIRED', 'WORK_IN_PROGRESS', 'READY_FOR_PICKUP',
    'DELIVERED', 'CANCELLED'
  ));

alter table public.job_line_items
  drop constraint job_line_items_approval_status_check;
alter table public.job_line_items
  add constraint job_line_items_approval_status_check check (
    approval_status in ('PENDING', 'APPROVED', 'DECLINED', 'REVISION_REQUESTED')
  );
alter table public.job_line_items
  add column approval_note text,
  add column approval_decided_at timestamptz,
  add column approval_decided_by text;

create table public.job_item_approval_events (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  line_item_id uuid not null,
  item_type text not null check (item_type in ('labour', 'part')),
  description text not null,
  code text not null,
  quantity numeric(10,2) not null,
  unit_rate_paise bigint not null,
  decision text not null check (
    decision in ('APPROVED', 'DECLINED', 'REVISION_REQUESTED')
  ),
  customer_name text not null check (length(trim(customer_name)) >= 2),
  note text,
  recorded_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade
);

create index job_item_approval_events_job_created_idx
  on public.job_item_approval_events(job_card_id, created_at desc);

alter table public.job_item_approval_events enable row level security;
create policy job_item_approval_events_member_read
  on public.job_item_approval_events for select to authenticated
  using (public.is_workshop_member(workshop_id));
grant select on public.job_item_approval_events to authenticated;
revoke insert, update, delete on public.job_item_approval_events from authenticated;

create or replace function public.mark_estimate_sent(p_job_card_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_status text;
  estimate_item_count integer;
begin
  select wm.workshop_id
    into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;

  select jc.status
    into current_status
    from public.job_cards jc
   where jc.id = p_job_card_id
     and jc.workshop_id = current_workshop;
  if not found or current_status not in ('INSPECTION_PENDING', 'ESTIMATE_REVISION_REQUIRED') then
    raise exception 'This estimate is not ready to send';
  end if;

  select count(*)::integer
    into estimate_item_count
    from public.job_line_items li
   where li.job_card_id = p_job_card_id
     and li.workshop_id = current_workshop;
  if estimate_item_count = 0 then
    raise exception 'Add at least one estimate item before sending';
  end if;

  update public.job_line_items
     set approval_status = 'PENDING',
         approval_note = null,
         approval_decided_at = null,
         approval_decided_by = null
   where job_card_id = p_job_card_id
     and workshop_id = current_workshop;

  update public.job_cards
     set status = 'ESTIMATE_SENT',
         estimate_sent_at = now(),
         estimate_sent_by = coalesce((select auth.jwt() ->> 'email'), (select auth.uid())::text),
         customer_approved_at = null,
         customer_approved_by = null,
         updated_at = now()
   where id = p_job_card_id
     and workshop_id = current_workshop;
end;
$$;

create or replace function public.record_estimate_response(
  p_job_card_id uuid,
  p_customer_name text,
  p_decisions jsonb
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_status text;
  expected_count integer;
  decision_count integer;
  distinct_item_count integer;
  matched_count integer;
  has_non_approval boolean;
  resulting_status text;
begin
  select wm.workshop_id
    into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if length(trim(coalesce(p_customer_name, ''))) < 2 then
    raise exception 'Enter the name of the customer who responded';
  end if;
  if p_decisions is null or jsonb_typeof(p_decisions) <> 'array' then
    raise exception 'Select a response for every estimate item';
  end if;

  select jc.status
    into current_status
    from public.job_cards jc
   where jc.id = p_job_card_id
     and jc.workshop_id = current_workshop;
  if not found or current_status not in ('ESTIMATE_SENT', 'WAITING_APPROVAL') then
    raise exception 'This estimate is not awaiting a customer response';
  end if;

  select count(*)::integer
    into expected_count
    from public.job_line_items li
   where li.job_card_id = p_job_card_id
     and li.workshop_id = current_workshop;
  select count(*)::integer,
         count(distinct d.value ->> 'lineItemId')::integer
    into decision_count, distinct_item_count
    from jsonb_array_elements(p_decisions) as d(value);
  select count(*)::integer
    into matched_count
    from jsonb_array_elements(p_decisions) as d(value)
    join public.job_line_items li
      on li.id::text = d.value ->> 'lineItemId'
     and li.job_card_id = p_job_card_id
     and li.workshop_id = current_workshop;

  if expected_count = 0
     or decision_count <> expected_count
     or distinct_item_count <> expected_count
     or matched_count <> expected_count then
    raise exception 'Customer response must include each current estimate item exactly once';
  end if;
  if exists (
    select 1
      from jsonb_array_elements(p_decisions) as d(value)
     where coalesce(d.value ->> 'decision', '') not in (
       'APPROVED', 'DECLINED', 'REVISION_REQUESTED'
     )
       or length(coalesce(d.value ->> 'note', '')) > 1000
  ) then
    raise exception 'One or more estimate decisions are invalid';
  end if;

  insert into public.job_item_approval_events (
    workshop_id, job_card_id, line_item_id, item_type, description, code,
    quantity, unit_rate_paise, decision, customer_name, note
  )
  select current_workshop, p_job_card_id, li.id, li.item_type, li.description,
         li.code, li.quantity, li.unit_rate_paise, d.value ->> 'decision',
         trim(p_customer_name), nullif(trim(d.value ->> 'note'), '')
    from jsonb_array_elements(p_decisions) as d(value)
    join public.job_line_items li
      on li.id::text = d.value ->> 'lineItemId'
     and li.job_card_id = p_job_card_id
     and li.workshop_id = current_workshop;

  update public.job_line_items li
     set approval_status = d.value ->> 'decision',
         approval_note = nullif(trim(d.value ->> 'note'), ''),
         approval_decided_at = now(),
         approval_decided_by = trim(p_customer_name)
    from jsonb_array_elements(p_decisions) as d(value)
   where li.id::text = d.value ->> 'lineItemId'
     and li.job_card_id = p_job_card_id
     and li.workshop_id = current_workshop;

  select exists (
    select 1
      from jsonb_array_elements(p_decisions) as d(value)
     where d.value ->> 'decision' <> 'APPROVED'
  ) into has_non_approval;

  resulting_status := case
    when has_non_approval then 'ESTIMATE_REVISION_REQUIRED'
    else 'WORK_IN_PROGRESS'
  end;

  update public.job_cards jc
     set status = resulting_status,
         customer_approved_at = case when has_non_approval then null else now() end,
         customer_approved_by = case when has_non_approval then null else trim(p_customer_name) end,
         updated_at = now()
   where jc.id = p_job_card_id
     and jc.workshop_id = current_workshop;

  return resulting_status;
end;
$$;

revoke all on function public.mark_estimate_sent(uuid) from public, anon;
grant execute on function public.mark_estimate_sent(uuid) to authenticated;
revoke all on function public.record_estimate_response(uuid, text, jsonb) from public, anon;
grant execute on function public.record_estimate_response(uuid, text, jsonb) to authenticated;
