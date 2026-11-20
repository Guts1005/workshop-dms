-- Initial Workshop DMS schema. Apply through Supabase migrations, not by
-- editing a live project manually. The client never receives a service key.
create extension if not exists pgcrypto with schema extensions;

create table public.workshops (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 2 and 120),
  created_at timestamptz not null default now()
);

create table public.workshop_memberships (
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'advisor', 'technician')),
  created_at timestamptz not null default now(),
  primary key (workshop_id, user_id),
  unique (user_id)
);

create or replace function public.is_workshop_member(target_workshop uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.workshop_memberships m
    where m.workshop_id = target_workshop and m.user_id = (select auth.uid())
  );
$$;

create or replace function public.create_workshop(workshop_name text)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare new_workshop_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sign in before creating a workshop';
  end if;
  if exists (select 1 from public.workshop_memberships where user_id = auth.uid()) then
    raise exception 'This account already belongs to a workshop';
  end if;
  insert into public.workshops(name) values (trim(workshop_name)) returning id into new_workshop_id;
  insert into public.workshop_memberships(workshop_id, user_id, role)
    values (new_workshop_id, auth.uid(), 'owner');
  return new_workshop_id;
end;
$$;

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 120),
  phone text not null check (phone ~ '^[0-9]{10}$'),
  consent_whatsapp boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workshop_id, phone),
  unique (id, workshop_id)
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  registration_number text not null,
  vin text,
  make text not null,
  model text not null,
  body_type text not null,
  odometer_km integer not null default 0 check (odometer_km >= 0),
  fuel_level_percent integer not null default 50 check (fuel_level_percent between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workshop_id, registration_number),
  unique (id, workshop_id)
);

create table public.job_cards (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  vehicle_id uuid not null,
  customer_id uuid not null,
  status text not null default 'RECEIVED' check (status in (
    'RECEIVED', 'INSPECTION_PENDING', 'ESTIMATE_SENT', 'WAITING_APPROVAL',
    'WORK_IN_PROGRESS', 'READY_FOR_PICKUP', 'DELIVERED', 'CANCELLED'
  )),
  requested_work text not null,
  expected_delivery timestamptz,
  intake_odometer_km integer not null default 0 check (intake_odometer_km >= 0),
  intake_fuel_level_percent integer not null default 50 check (intake_fuel_level_percent between 0 and 100),
  belongings jsonb not null default '{}'::jsonb,
  assigned_technician text,
  customer_approved_at timestamptz,
  customer_approved_by text,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (vehicle_id, workshop_id) references public.vehicles(id, workshop_id),
  foreign key (customer_id, workshop_id) references public.customers(id, workshop_id),
  unique (id, workshop_id)
);

create index job_cards_workshop_created_idx on public.job_cards(workshop_id, created_at desc);
create index vehicles_workshop_plate_idx on public.vehicles(workshop_id, registration_number);

create table public.job_line_items (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  item_type text not null check (item_type in ('labour', 'part')),
  description text not null,
  code text not null,
  quantity numeric(10,2) not null check (quantity > 0),
  unit_rate_paise bigint not null check (unit_rate_paise >= 0),
  gst_rate_percent numeric(5,2) not null check (gst_rate_percent between 0 and 100),
  approval_status text not null default 'PENDING' check (approval_status in ('PENDING', 'APPROVED', 'DECLINED')),
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id) references public.job_cards(id, workshop_id) on delete cascade
);

create table public.bay_photos (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  shot_type text not null check (shot_type in (
    'frontLeft45', 'frontRight45', 'rearLeft45', 'rearRight45',
    'plateCloseup', 'odometerReading', 'dashboardCluster', 'vinPlate'
  )),
  storage_path text not null,
  sha256_hash text not null check (sha256_hash ~ '^[a-f0-9]{64}$'),
  captured_at timestamptz not null,
  created_by uuid not null default auth.uid() references auth.users(id),
  unique (job_card_id, shot_type),
  foreign key (job_card_id, workshop_id) references public.job_cards(id, workshop_id) on delete cascade
);

create table public.condition_reports (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null unique,
  reviewed_areas text[] not null default '{}',
  customer_name text not null,
  customer_phone text not null check (customer_phone ~ '^[0-9]{10}$'),
  advisor_name text not null,
  customer_acknowledged boolean not null default false,
  signed_at timestamptz not null,
  sha256_checksum text not null check (sha256_checksum ~ '^[a-f0-9]{64}$'),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id) references public.job_cards(id, workshop_id) on delete cascade
);

create table public.condition_findings (
  id integer not null,
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  area text not null check (area in ('sideLeft', 'sideRight', 'front', 'rear', 'top')),
  finding_type text not null,
  severity text not null check (severity in ('minor', 'moderate', 'severe')),
  note text,
  normalized_x double precision not null default 0.5 check (normalized_x between 0 and 1),
  normalized_y double precision not null default 0.5 check (normalized_y between 0 and 1),
  photo_storage_path text,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (job_card_id, id),
  foreign key (job_card_id, workshop_id) references public.job_cards(id, workshop_id) on delete cascade
);

create table public.condition_review_areas (
  job_card_id uuid primary key,
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  reviewed_areas text[] not null default '{}',
  updated_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id) references public.job_cards(id, workshop_id) on delete cascade
);

create table public.manager_overrides (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  authorized_by text not null,
  reason text not null,
  missing_shots text[] not null default '{}',
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id) references public.job_cards(id, workshop_id) on delete cascade
);

create index condition_findings_job_idx on public.condition_findings(job_card_id, created_at);

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
language plpgsql security invoker
set search_path = ''
as $$
declare current_workshop uuid;
begin
  select m.workshop_id into current_workshop
    from public.workshop_memberships m where m.user_id = auth.uid();
  if current_workshop is null then raise exception 'Your account is not linked to a workshop'; end if;
  if coalesce(array_length(p_reviewed_areas, 1), 0) <> 5 then
    raise exception 'Review all five vehicle views before signing off';
  end if;
  insert into public.condition_reports(
    workshop_id, job_card_id, reviewed_areas, customer_name, customer_phone,
    advisor_name, customer_acknowledged, signed_at, sha256_checksum
  ) values (
    current_workshop, p_job_card_id, p_reviewed_areas, trim(p_customer_name),
    right(regexp_replace(p_customer_phone, '\D', '', 'g'), 10), trim(p_advisor_name),
    coalesce(p_customer_acknowledged, false), p_signed_at, p_sha256_checksum
  );
  update public.job_cards set status = 'INSPECTION_PENDING', updated_at = now()
    where id = p_job_card_id and workshop_id = current_workshop;
  if not found then raise exception 'Application not found in your workshop'; end if;
end;
$$;

create or replace function public.create_application(
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
  p_belongings jsonb
)
returns uuid
language plpgsql security invoker
set search_path = ''
as $$
declare
  current_workshop uuid;
  customer uuid;
  vehicle uuid;
  new_job_card uuid;
  normalized_phone text := right(regexp_replace(p_customer_phone, '\D', '', 'g'), 10);
  normalized_plate text := upper(regexp_replace(p_registration_number, '[\s-]', '', 'g'));
begin
  select m.workshop_id into current_workshop
    from public.workshop_memberships m where m.user_id = auth.uid();
  if current_workshop is null then raise exception 'Your account is not linked to a workshop'; end if;
  if length(normalized_phone) <> 10 then raise exception 'Enter a valid 10 digit mobile number'; end if;
  if normalized_plate = '' then raise exception 'Vehicle registration is required'; end if;

  insert into public.customers(workshop_id, name, phone, consent_whatsapp)
    values (current_workshop, trim(p_customer_name), normalized_phone, coalesce(p_whatsapp_consent, false))
    on conflict (workshop_id, phone) do update set
      name = excluded.name,
      consent_whatsapp = excluded.consent_whatsapp,
      updated_at = now()
    returning id into customer;

  insert into public.vehicles(workshop_id, registration_number, vin, make, model, body_type,
      odometer_km, fuel_level_percent)
    values (current_workshop, normalized_plate, nullif(upper(trim(p_vin)), ''), trim(p_make),
      trim(p_model), trim(p_body_type), p_odometer_km, p_fuel_level_percent)
    on conflict (workshop_id, registration_number) do update set
      vin = coalesce(excluded.vin, public.vehicles.vin),
      make = excluded.make,
      model = excluded.model,
      body_type = excluded.body_type,
      odometer_km = greatest(public.vehicles.odometer_km, excluded.odometer_km),
      fuel_level_percent = excluded.fuel_level_percent,
      updated_at = now()
    returning id into vehicle;

  insert into public.job_cards(workshop_id, vehicle_id, customer_id, requested_work,
      expected_delivery, intake_odometer_km, intake_fuel_level_percent, belongings)
    values (current_workshop, vehicle, customer, trim(p_requested_work), p_expected_delivery,
      p_odometer_km, p_fuel_level_percent, coalesce(p_belongings, '{}'::jsonb))
    returning id into new_job_card;
  return new_job_card;
end;
$$;

alter table public.workshops enable row level security;
alter table public.workshop_memberships enable row level security;
alter table public.customers enable row level security;
alter table public.vehicles enable row level security;
alter table public.job_cards enable row level security;
alter table public.job_line_items enable row level security;
alter table public.bay_photos enable row level security;
alter table public.condition_reports enable row level security;
alter table public.condition_findings enable row level security;
alter table public.condition_review_areas enable row level security;
alter table public.manager_overrides enable row level security;

create policy workshop_members_read on public.workshops for select to authenticated
  using (public.is_workshop_member(id));
create policy own_membership_read on public.workshop_memberships for select to authenticated
  using (user_id = (select auth.uid()));

create policy customers_member_access on public.customers for all to authenticated
  using (public.is_workshop_member(workshop_id)) with check (public.is_workshop_member(workshop_id));
create policy vehicles_member_access on public.vehicles for all to authenticated
  using (public.is_workshop_member(workshop_id)) with check (public.is_workshop_member(workshop_id));
create policy job_cards_member_access on public.job_cards for all to authenticated
  using (public.is_workshop_member(workshop_id)) with check (public.is_workshop_member(workshop_id));
create policy job_line_items_member_access on public.job_line_items for all to authenticated
  using (public.is_workshop_member(workshop_id)) with check (public.is_workshop_member(workshop_id));
create policy bay_photos_member_access on public.bay_photos for all to authenticated
  using (public.is_workshop_member(workshop_id)) with check (public.is_workshop_member(workshop_id));
create policy condition_reports_member_read on public.condition_reports for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy condition_reports_member_insert on public.condition_reports for insert to authenticated
  with check (public.is_workshop_member(workshop_id));
create policy condition_findings_member_read on public.condition_findings for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy condition_findings_member_insert on public.condition_findings for insert to authenticated
  with check (public.is_workshop_member(workshop_id) and not exists (
    select 1 from public.condition_reports r where r.job_card_id = condition_findings.job_card_id
  ));
create policy condition_findings_member_update on public.condition_findings for update to authenticated
  using (public.is_workshop_member(workshop_id) and not exists (
    select 1 from public.condition_reports r where r.job_card_id = condition_findings.job_card_id
  )) with check (public.is_workshop_member(workshop_id) and not exists (
    select 1 from public.condition_reports r where r.job_card_id = condition_findings.job_card_id
  ));
create policy condition_findings_member_delete on public.condition_findings for delete to authenticated
  using (public.is_workshop_member(workshop_id) and not exists (
    select 1 from public.condition_reports r where r.job_card_id = condition_findings.job_card_id
  ));
create policy condition_review_member_access on public.condition_review_areas for all to authenticated
  using (public.is_workshop_member(workshop_id) and not exists (
    select 1 from public.condition_reports r where r.job_card_id = condition_review_areas.job_card_id
  )) with check (public.is_workshop_member(workshop_id) and not exists (
    select 1 from public.condition_reports r where r.job_card_id = condition_review_areas.job_card_id
  ));
create policy manager_overrides_member_read on public.manager_overrides for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy manager_overrides_member_insert on public.manager_overrides for insert to authenticated
  with check (public.is_workshop_member(workshop_id));

grant select on public.workshops, public.workshop_memberships to authenticated;
grant select, insert, update, delete on public.customers, public.vehicles, public.job_cards,
  public.job_line_items, public.bay_photos, public.condition_reports,
  public.condition_findings, public.condition_review_areas, public.manager_overrides to authenticated;

revoke all on function public.create_workshop(text) from public;
grant execute on function public.create_workshop(text) to authenticated;
revoke all on function public.create_application(text, text, text, text, text, text, text, boolean, integer, integer, text, timestamptz, jsonb) from public;
grant execute on function public.create_application(text, text, text, text, text, text, text, boolean, integer, integer, text, timestamptz, jsonb) to authenticated;
revoke all on function public.record_condition_signoff(uuid, text[], text, text, text, boolean, timestamptz, text) from public;
grant execute on function public.record_condition_signoff(uuid, text[], text, text, text, boolean, timestamptz, text) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('workshop-checkin', 'workshop-checkin', false, 12582912, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy workshop_checkin_member_select on storage.objects for select to authenticated
  using (bucket_id = 'workshop-checkin' and public.is_workshop_member((storage.foldername(name))[1]::uuid));
create policy workshop_checkin_member_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'workshop-checkin' and public.is_workshop_member((storage.foldername(name))[1]::uuid));
create policy workshop_checkin_member_update on storage.objects for update to authenticated
  using (bucket_id = 'workshop-checkin' and public.is_workshop_member((storage.foldername(name))[1]::uuid))
  with check (bucket_id = 'workshop-checkin' and public.is_workshop_member((storage.foldername(name))[1]::uuid));
create policy workshop_checkin_member_delete on storage.objects for delete to authenticated
  using (bucket_id = 'workshop-checkin' and public.is_workshop_member((storage.foldername(name))[1]::uuid));
