-- Keep application lifecycle and customer approval decisions inside validated RPCs.

create or replace function public.record_condition_signoff(
  p_job_card_id uuid,
  p_reviewed_areas text[],
  p_customer_name text,
  p_customer_phone text,
  p_advisor_name text,
  p_customer_acknowledged boolean,
  p_signed_at timestamptz,
  p_sha256_checksum text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
begin
  select m.workshop_id
    into current_workshop
    from public.workshop_memberships m
   where m.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if coalesce(array_length(p_reviewed_areas, 1), 0) <> 5 then
    raise exception 'Review all five vehicle views before signing off';
  end if;
  if not exists (
    select 1 from public.job_cards jc
     where jc.id = p_job_card_id and jc.workshop_id = current_workshop
  ) then
    raise exception 'Application not found in your workshop';
  end if;

  insert into public.condition_reports(
    workshop_id, job_card_id, reviewed_areas, customer_name, customer_phone,
    advisor_name, customer_acknowledged, signed_at, sha256_checksum
  ) values (
    current_workshop, p_job_card_id, p_reviewed_areas, trim(p_customer_name),
    right(regexp_replace(p_customer_phone, '\D', '', 'g'), 10), trim(p_advisor_name),
    coalesce(p_customer_acknowledged, false), p_signed_at, p_sha256_checksum
  );

  update public.job_cards
     set status = 'INSPECTION_PENDING', updated_at = now()
   where id = p_job_card_id and workshop_id = current_workshop;
end;
$$;

revoke update on public.job_cards from authenticated;
revoke delete on public.job_cards from authenticated;

-- The estimate editor can change commercial details, but cannot forge response fields.
revoke insert, update on public.job_line_items from authenticated;
grant insert (
  workshop_id, job_card_id, item_type, description, code,
  quantity, unit_rate_paise, gst_rate_percent
) on public.job_line_items to authenticated;
grant update (
  item_type, description, code, quantity, unit_rate_paise, gst_rate_percent
) on public.job_line_items to authenticated;

-- Keep estimate contents editable only before dispatch or while a revision is requested.
drop policy job_line_items_member_access on public.job_line_items;
create policy job_line_items_member_read on public.job_line_items for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy job_line_items_edit_insert on public.job_line_items for insert to authenticated
  with check (
    public.is_workshop_member(workshop_id)
    and exists (
      select 1 from public.job_cards jc
       where jc.id = job_line_items.job_card_id
         and jc.workshop_id = job_line_items.workshop_id
         and jc.status in ('INSPECTION_PENDING', 'ESTIMATE_REVISION_REQUIRED')
    )
  );
create policy job_line_items_edit_update on public.job_line_items for update to authenticated
  using (
    public.is_workshop_member(workshop_id)
    and exists (
      select 1 from public.job_cards jc
       where jc.id = job_line_items.job_card_id
         and jc.workshop_id = job_line_items.workshop_id
         and jc.status in ('INSPECTION_PENDING', 'ESTIMATE_REVISION_REQUIRED')
    )
  ) with check (
    public.is_workshop_member(workshop_id)
    and exists (
      select 1 from public.job_cards jc
       where jc.id = job_line_items.job_card_id
         and jc.workshop_id = job_line_items.workshop_id
         and jc.status in ('INSPECTION_PENDING', 'ESTIMATE_REVISION_REQUIRED')
    )
  );
create policy job_line_items_edit_delete on public.job_line_items for delete to authenticated
  using (
    public.is_workshop_member(workshop_id)
    and exists (
      select 1 from public.job_cards jc
       where jc.id = job_line_items.job_card_id
         and jc.workshop_id = job_line_items.workshop_id
         and jc.status in ('INSPECTION_PENDING', 'ESTIMATE_REVISION_REQUIRED')
    )
  );

create or replace function public.guard_work_in_progress_approval()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'WORK_IN_PROGRESS'
     and old.status is distinct from new.status then
    if old.status not in ('ESTIMATE_SENT', 'WAITING_APPROVAL')
       or not exists (
         select 1 from public.job_line_items li
          where li.job_card_id = new.id and li.workshop_id = new.workshop_id
       )
       or exists (
         select 1 from public.job_line_items li
          where li.job_card_id = new.id
            and li.workshop_id = new.workshop_id
            and li.approval_status <> 'APPROVED'
       )
       or exists (
         select 1 from public.job_line_items li
          where li.job_card_id = new.id
            and li.workshop_id = new.workshop_id
            and not exists (
              select 1 from public.job_item_approval_events e
               where e.line_item_id = li.id
                 and e.job_card_id = new.id
                 and e.workshop_id = new.workshop_id
                 and e.decision = 'APPROVED'
            )
       ) then
      raise exception 'Every estimate item must have an audited customer approval before work starts';
    end if;
  end if;
  return new;
end;
$$;

create trigger job_cards_require_audited_approval
  before update of status on public.job_cards
  for each row execute function public.guard_work_in_progress_approval();
