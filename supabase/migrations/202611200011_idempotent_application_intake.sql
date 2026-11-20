-- Prevent intake retries from creating duplicate job cards and keep job-card
-- creation inside the validated RPC.
alter table public.job_cards
  add column if not exists intake_request_id uuid;
alter table public.job_cards
  add column if not exists intake_request_hash bytea;

create unique index if not exists job_cards_intake_request_unique
  on public.job_cards(workshop_id, created_by, intake_request_id)
  where intake_request_id is not null;

drop function if exists public.create_application(
  text, text, text, text, text, text, text, boolean, integer, integer,
  text, timestamptz, jsonb
);

create function public.create_application(
  p_registration_number text,
  p_vin text,
  p_make text,
  p_model text,
  p_body_type text,
  p_customer_name text,
  p_customer_phone text,
  p_whatsapp_consent boolean,
  p_odometer_km integer,
  p_fuel_level_percent integer,
  p_requested_work text,
  p_expected_delivery timestamptz,
  p_belongings jsonb,
  p_request_id uuid
)
returns uuid
 language plpgsql security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  customer uuid;
  vehicle uuid;
  new_job_card uuid;
  existing_job_card uuid;
  existing_request_hash bytea;
  request_hash bytea;
  normalized_phone text := right(regexp_replace(p_customer_phone, '\D', '', 'g'), 10);
  normalized_plate text := upper(regexp_replace(p_registration_number, '[\s-]', '', 'g'));
begin
  select m.workshop_id into current_workshop
    from public.workshop_memberships m where m.user_id = auth.uid();
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if p_request_id is null then
    raise exception 'An intake request ID is required';
  end if;

  if length(normalized_phone) <> 10 then
    raise exception 'Enter a valid 10 digit mobile number';
  end if;
  if normalized_plate = '' then
    raise exception 'Vehicle registration is required';
  end if;

  request_hash := extensions.digest(
    convert_to(
      jsonb_build_object(
        'registration_number', normalized_plate,
        'vin', nullif(upper(trim(p_vin)), ''),
        'make', trim(p_make),
        'model', trim(p_model),
        'body_type', trim(p_body_type),
        'customer_name', trim(p_customer_name),
        'customer_phone', normalized_phone,
        'whatsapp_consent', coalesce(p_whatsapp_consent, false),
        'odometer_km', p_odometer_km,
        'fuel_level_percent', p_fuel_level_percent,
        'requested_work', trim(p_requested_work),
        'expected_delivery', p_expected_delivery,
        'belongings', coalesce(p_belongings, '{}'::jsonb)
      )::text,
      'UTF8'
    ),
    'sha256'
  );

  -- Serialize this user action. A retry with unchanged data returns the prior
  -- result; edited details require a new request ID.
  perform pg_advisory_xact_lock(
    hashtextextended(
      current_workshop::text || ':' || auth.uid()::text || ':' || p_request_id::text,
      0
    )
  );
  select jc.id, jc.intake_request_hash
    into existing_job_card, existing_request_hash
    from public.job_cards jc
   where jc.workshop_id = current_workshop
     and jc.created_by = auth.uid()
     and jc.intake_request_id = p_request_id;
  if existing_job_card is not null then
    if existing_request_hash is distinct from request_hash then
      raise exception 'This intake request ID was already used with different details';
    end if;
    return existing_job_card;
  end if;

  insert into public.customers(workshop_id, name, phone, consent_whatsapp)
    values (
      current_workshop,
      trim(p_customer_name),
      normalized_phone,
      coalesce(p_whatsapp_consent, false)
    )
    on conflict (workshop_id, phone) do update set
      name = excluded.name,
      consent_whatsapp = excluded.consent_whatsapp,
      updated_at = now()
    returning id into customer;

  insert into public.vehicles(
    workshop_id, registration_number, vin, make, model, body_type,
    odometer_km, fuel_level_percent
  ) values (
    current_workshop,
    normalized_plate,
    nullif(upper(trim(p_vin)), ''),
    trim(p_make),
    trim(p_model),
    trim(p_body_type),
    p_odometer_km,
    p_fuel_level_percent
  )
  on conflict (workshop_id, registration_number) do update set
    vin = coalesce(excluded.vin, public.vehicles.vin),
    make = excluded.make,
    model = excluded.model,
    body_type = excluded.body_type,
    odometer_km = greatest(public.vehicles.odometer_km, excluded.odometer_km),
    fuel_level_percent = excluded.fuel_level_percent,
    updated_at = now()
  returning id into vehicle;

  insert into public.job_cards(
    workshop_id, vehicle_id, customer_id, requested_work,
    expected_delivery, intake_odometer_km, intake_fuel_level_percent,
    belongings, intake_request_id, intake_request_hash
  ) values (
    current_workshop, vehicle, customer, trim(p_requested_work),
    p_expected_delivery, p_odometer_km, p_fuel_level_percent,
    coalesce(p_belongings, '{}'::jsonb), p_request_id, request_hash
  ) returning id into new_job_card;
  return new_job_card;
end;
$$;

revoke insert on public.job_cards from public, anon, authenticated;

revoke all on function public.create_application(
  text, text, text, text, text, text, text, boolean, integer, integer,
  text, timestamptz, jsonb, uuid
) from public, anon;
grant execute on function public.create_application(
  text, text, text, text, text, text, text, boolean, integer, integer,
  text, timestamptz, jsonb, uuid
) to authenticated;
