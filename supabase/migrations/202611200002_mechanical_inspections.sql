create table public.mechanical_inspections (
  job_card_id uuid primary key,
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  inspector_name text not null check (length(trim(inspector_name)) > 0),
  odometer_km integer not null check (odometer_km >= 0),
  measurements jsonb not null default '{}'::jsonb,
  not_applicable text[] not null default '{}',
  notes text not null default '',
  completed_at timestamptz not null,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade,
  check (jsonb_typeof(measurements) = 'object'),
  check (
    measurements - array[
      'front_brake_pad_mm', 'rear_brake_pad_mm', 'minimum_tyre_tread_mm',
      'battery_voltage_v', 'battery_cca'
    ] = '{}'::jsonb
  ),
  check (
    not_applicable <@ array[
      'front_brake_pad_mm', 'rear_brake_pad_mm', 'minimum_tyre_tread_mm',
      'battery_voltage_v', 'battery_cca'
    ]
  ),
  check (measurements <> '{}'::jsonb),
  check (
    (not (measurements ? 'front_brake_pad_mm') or (
      jsonb_typeof(measurements -> 'front_brake_pad_mm') = 'number'
      and (measurements ->> 'front_brake_pad_mm')::numeric between 0 and 100
    ))
    and (not (measurements ? 'rear_brake_pad_mm') or (
      jsonb_typeof(measurements -> 'rear_brake_pad_mm') = 'number'
      and (measurements ->> 'rear_brake_pad_mm')::numeric between 0 and 100
    ))
    and (not (measurements ? 'minimum_tyre_tread_mm') or (
      jsonb_typeof(measurements -> 'minimum_tyre_tread_mm') = 'number'
      and (measurements ->> 'minimum_tyre_tread_mm')::numeric between 0 and 50
    ))
    and (not (measurements ? 'battery_voltage_v') or (
      jsonb_typeof(measurements -> 'battery_voltage_v') = 'number'
      and (measurements ->> 'battery_voltage_v')::numeric between 0 and 100
    ))
    and (not (measurements ? 'battery_cca') or (
      jsonb_typeof(measurements -> 'battery_cca') = 'number'
      and (measurements ->> 'battery_cca')::numeric between 0 and 5000
    ))
  ),
  check (
    (measurements ? 'front_brake_pad_mm' or 'front_brake_pad_mm' = any(not_applicable))
    and (measurements ? 'rear_brake_pad_mm' or 'rear_brake_pad_mm' = any(not_applicable))
    and (measurements ? 'minimum_tyre_tread_mm' or 'minimum_tyre_tread_mm' = any(not_applicable))
    and (measurements ? 'battery_voltage_v' or 'battery_voltage_v' = any(not_applicable))
    and (measurements ? 'battery_cca' or 'battery_cca' = any(not_applicable))
  )
);

create index mechanical_inspections_workshop_completed_idx
  on public.mechanical_inspections(workshop_id, completed_at desc);

alter table public.mechanical_inspections enable row level security;

create policy mechanical_inspections_member_read
  on public.mechanical_inspections for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy mechanical_inspections_member_insert
  on public.mechanical_inspections for insert to authenticated
  with check (public.is_workshop_member(workshop_id));
create policy mechanical_inspections_member_update
  on public.mechanical_inspections for update to authenticated
  using (public.is_workshop_member(workshop_id))
  with check (public.is_workshop_member(workshop_id));

grant select, insert, update on public.mechanical_inspections to authenticated;
