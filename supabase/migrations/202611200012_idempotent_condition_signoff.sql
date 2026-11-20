-- A client may retry when the database committed a sign-off but its response was lost.
-- Serialize by job card and return successfully for an identical repeat request.
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
  existing_report public.condition_reports%rowtype;
  normalized_phone text;
begin
  select m.workshop_id
    into current_workshop
    from public.workshop_memberships m
   where m.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;

  if p_reviewed_areas is null
     or cardinality(p_reviewed_areas) <> 5
     or not (p_reviewed_areas @> array['sideLeft', 'sideRight', 'front', 'rear', 'top']) then
    raise exception 'Review all five vehicle views before signing off';
  end if;

  -- Locking the parent prevents concurrent retries from both observing no report.
  perform 1
    from public.job_cards jc
   where jc.id = p_job_card_id
     and jc.workshop_id = current_workshop
   for update;
  if not found then
    raise exception 'Application not found in your workshop';
  end if;

  normalized_phone := right(
    regexp_replace(coalesce(p_customer_phone, ''), '\D', '', 'g'),
    10
  );

  select r.*
    into existing_report
    from public.condition_reports r
   where r.job_card_id = p_job_card_id
     and r.workshop_id = current_workshop;

  if found then
    if existing_report.reviewed_areas @> p_reviewed_areas
       and p_reviewed_areas @> existing_report.reviewed_areas
       and existing_report.customer_name = trim(p_customer_name)
       and existing_report.customer_phone = normalized_phone
       and existing_report.advisor_name = trim(p_advisor_name)
       and existing_report.customer_acknowledged = coalesce(p_customer_acknowledged, false)
       and existing_report.signed_at = p_signed_at
       and existing_report.sha256_checksum = p_sha256_checksum then
      return;
    end if;
    raise exception 'A different condition sign-off is already recorded for this application';
  end if;

  insert into public.condition_reports(
    workshop_id, job_card_id, reviewed_areas, customer_name, customer_phone,
    advisor_name, customer_acknowledged, signed_at, sha256_checksum
  ) values (
    current_workshop, p_job_card_id, p_reviewed_areas, trim(p_customer_name),
    normalized_phone, trim(p_advisor_name), coalesce(p_customer_acknowledged, false),
    p_signed_at, p_sha256_checksum
  );

  update public.job_cards
     set status = 'INSPECTION_PENDING', updated_at = now()
   where id = p_job_card_id and workshop_id = current_workshop;
end;
$$;

revoke all on function public.record_condition_signoff(
  uuid, text[], text, text, text, boolean, timestamptz, text
) from public, anon;
grant execute on function public.record_condition_signoff(
  uuid, text[], text, text, text, boolean, timestamptz, text
) to authenticated;
