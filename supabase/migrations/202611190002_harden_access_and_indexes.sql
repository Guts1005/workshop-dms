-- Keep the membership helper available to signed-in RLS checks only.
revoke all on function public.is_workshop_member(uuid) from public, anon;
grant execute on function public.is_workshop_member(uuid) to authenticated;

-- Workshop creation is available only to signed-in users.
revoke all on function public.create_workshop(text) from public, anon;
grant execute on function public.create_workshop(text) to authenticated;

-- Cover lookup, workshop scoping, and parent delete/update paths.
create index if not exists job_cards_customer_workshop_idx
  on public.job_cards(customer_id, workshop_id);
create index if not exists job_cards_vehicle_workshop_idx
  on public.job_cards(vehicle_id, workshop_id);
create index if not exists job_cards_created_by_idx
  on public.job_cards(created_by);

create index if not exists bay_photos_workshop_idx
  on public.bay_photos(workshop_id);
create index if not exists bay_photos_job_workshop_idx
  on public.bay_photos(job_card_id, workshop_id);
create index if not exists bay_photos_created_by_idx
  on public.bay_photos(created_by);

create index if not exists job_line_items_workshop_idx
  on public.job_line_items(workshop_id);
create index if not exists job_line_items_job_workshop_idx
  on public.job_line_items(job_card_id, workshop_id);

create index if not exists condition_reports_workshop_idx
  on public.condition_reports(workshop_id);
create index if not exists condition_reports_job_workshop_idx
  on public.condition_reports(job_card_id, workshop_id);
create index if not exists condition_reports_created_by_idx
  on public.condition_reports(created_by);

create index if not exists condition_findings_workshop_idx
  on public.condition_findings(workshop_id);
create index if not exists condition_findings_job_workshop_idx
  on public.condition_findings(job_card_id, workshop_id);
create index if not exists condition_findings_created_by_idx
  on public.condition_findings(created_by);

create index if not exists condition_review_areas_workshop_idx
  on public.condition_review_areas(workshop_id);
create index if not exists condition_review_areas_job_workshop_idx
  on public.condition_review_areas(job_card_id, workshop_id);

create index if not exists manager_overrides_workshop_idx
  on public.manager_overrides(workshop_id);
create index if not exists manager_overrides_job_workshop_idx
  on public.manager_overrides(job_card_id, workshop_id);
create index if not exists manager_overrides_created_by_idx
  on public.manager_overrides(created_by);
