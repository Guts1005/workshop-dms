create or replace function public.finalize_bay_check_in(p_job_card_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_workshop uuid;
  mandatory_photo_count integer;
  has_manager_override boolean;
begin
  select jc.workshop_id
    into target_workshop
    from public.job_cards jc
   where jc.id = p_job_card_id;

  if target_workshop is null or not public.is_workshop_member(target_workshop) then
    raise exception 'Application not found in your workshop';
  end if;

  select count(distinct bp.shot_type)::integer
    into mandatory_photo_count
    from public.bay_photos bp
   where bp.job_card_id = p_job_card_id
     and bp.workshop_id = target_workshop
     and bp.shot_type in (
       'frontLeft45', 'frontRight45', 'rearLeft45',
       'rearRight45', 'plateCloseup', 'odometerReading'
     );

  select exists (
    select 1
      from public.manager_overrides mo
     where mo.job_card_id = p_job_card_id
       and mo.workshop_id = target_workshop
       and length(trim(mo.authorized_by)) >= 2
       and length(trim(mo.reason)) >= 5
  ) into has_manager_override;

  if mandatory_photo_count < 6 and not has_manager_override then
    raise exception 'Capture all six mandatory check-in photos or record a manager override';
  end if;

  update public.job_cards
     set status = 'INSPECTION_PENDING', updated_at = now()
   where id = p_job_card_id
     and workshop_id = target_workshop
     and status in ('RECEIVED', 'INSPECTION_PENDING');

  if not found then
    raise exception 'Application is no longer at the check-in step';
  end if;
end;
$$;

revoke all on function public.finalize_bay_check_in(uuid) from public, anon;
grant execute on function public.finalize_bay_check_in(uuid) to authenticated;

-- A typed manager name alone is not authorization. Only the workshop owner
-- may create an override record; the typed name remains the audit display name.
drop policy if exists manager_overrides_member_insert
  on public.manager_overrides;
create policy manager_overrides_owner_insert
  on public.manager_overrides for insert to authenticated
  with check (
    public.is_workshop_member(workshop_id)
    and exists (
      select 1
        from public.workshop_memberships wm
       where wm.workshop_id = manager_overrides.workshop_id
         and wm.user_id = (select auth.uid())
         and wm.role = 'owner'
    )
  );

-- Keep the evidence gate in force even if a client attempts a direct status update.
create or replace function public.enforce_bay_checkin_before_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  mandatory_photo_count integer;
  has_manager_override boolean;
begin
  if new.status = 'INSPECTION_PENDING'
     and old.status is distinct from new.status then
    select count(distinct bp.shot_type)::integer
      into mandatory_photo_count
      from public.bay_photos bp
     where bp.job_card_id = new.id
       and bp.workshop_id = new.workshop_id
       and bp.shot_type in (
         'frontLeft45', 'frontRight45', 'rearLeft45',
         'rearRight45', 'plateCloseup', 'odometerReading'
       );

    select exists (
      select 1
        from public.manager_overrides mo
       where mo.job_card_id = new.id
         and mo.workshop_id = new.workshop_id
         and length(trim(mo.authorized_by)) >= 2
         and length(trim(mo.reason)) >= 5
    ) into has_manager_override;

    if mandatory_photo_count < 6 and not has_manager_override then
      raise exception 'Capture all six mandatory check-in photos or record a manager override';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_bay_checkin_before_status() from public, anon, authenticated;
drop trigger if exists job_cards_require_bay_checkin on public.job_cards;
create trigger job_cards_require_bay_checkin
before update of status on public.job_cards
for each row execute function public.enforce_bay_checkin_before_status();
