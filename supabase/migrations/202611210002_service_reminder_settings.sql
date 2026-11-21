-- Persist reminder intervals chosen by the workshop. There is deliberately no
-- default interval; reminders stay disabled until an owner/advisor configures it.
create table public.workshop_service_reminder_settings (
  workshop_id uuid primary key references public.workshops(id) on delete cascade,
  service_interval_km integer not null check (
    service_interval_km between 1 and 1000000
  ),
  service_interval_days integer not null check (
    service_interval_days between 1 and 3650
  ),
  due_soon_days integer not null default 14 check (
    due_soon_days between 1 and 90
  ),
  updated_by uuid not null default auth.uid() references auth.users(id),
  updated_at timestamptz not null default now()
);

alter table public.workshop_service_reminder_settings enable row level security;

create policy workshop_service_reminder_settings_member_read
  on public.workshop_service_reminder_settings for select to authenticated
  using (public.is_workshop_member(workshop_id));

create policy workshop_service_reminder_settings_manager_insert
  on public.workshop_service_reminder_settings for insert to authenticated
  with check (exists (
    select 1
      from public.workshop_memberships wm
     where wm.workshop_id = workshop_service_reminder_settings.workshop_id
       and wm.user_id = (select auth.uid())
       and wm.role in ('owner', 'advisor')
  ) and updated_by = (select auth.uid()));

create policy workshop_service_reminder_settings_manager_update
  on public.workshop_service_reminder_settings for update to authenticated
  using (exists (
    select 1
      from public.workshop_memberships wm
     where wm.workshop_id = workshop_service_reminder_settings.workshop_id
       and wm.user_id = (select auth.uid())
       and wm.role in ('owner', 'advisor')
  ))
  with check (exists (
    select 1
      from public.workshop_memberships wm
     where wm.workshop_id = workshop_service_reminder_settings.workshop_id
       and wm.user_id = (select auth.uid())
       and wm.role in ('owner', 'advisor')
  ) and updated_by = (select auth.uid()));

grant select, insert, update on public.workshop_service_reminder_settings
  to authenticated;
revoke delete on public.workshop_service_reminder_settings from authenticated;
