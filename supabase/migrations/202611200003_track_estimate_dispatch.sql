alter table public.job_cards
  add column estimate_sent_at timestamptz,
  add column estimate_sent_by text;
