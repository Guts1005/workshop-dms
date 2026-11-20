-- Append-only payment history and a server-enforced vehicle handover gate.

create table public.job_payments (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null,
  amount_paise bigint not null check (amount_paise > 0),
  method text not null check (method in ('CASH', 'UPI', 'CARD', 'BANK_TRANSFER', 'OTHER')),
  reference text not null default '' check (length(reference) <= 160),
  request_id uuid not null,
  received_by_label text not null,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade,
  unique (workshop_id, request_id)
);

create index job_payments_job_created_idx
  on public.job_payments(job_card_id, created_at);

create table public.job_deliveries (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null unique,
  balance_at_delivery_paise bigint not null check (balance_at_delivery_paise >= 0),
  credit_override_reason text not null default '',
  delivered_by_label text not null,
  delivered_by uuid not null default auth.uid() references auth.users(id),
  delivered_at timestamptz not null default now(),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade
);

create index job_deliveries_workshop_date_idx
  on public.job_deliveries(workshop_id, delivered_at desc);

alter table public.job_payments enable row level security;
alter table public.job_deliveries enable row level security;
create policy job_payments_member_read on public.job_payments for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy job_deliveries_member_read on public.job_deliveries for select to authenticated
  using (public.is_workshop_member(workshop_id));
grant select on public.job_payments, public.job_deliveries to authenticated;
revoke insert, update, delete on public.job_payments, public.job_deliveries from authenticated;

create or replace function public.record_job_payment(
  p_job_card_id uuid,
  p_amount_paise bigint,
  p_method text,
  p_reference text,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_status text;
  invoice_total bigint;
  paid_total bigint;
  new_paid_total bigint;
  new_payment_id uuid;
  existing_request record;
begin
  select wm.workshop_id into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if p_amount_paise is null or p_amount_paise <= 0 then
    raise exception 'Enter a payment amount greater than zero';
  end if;
  if coalesce(p_method, '') not in ('CASH', 'UPI', 'CARD', 'BANK_TRANSFER', 'OTHER') then
    raise exception 'Choose a valid payment method';
  end if;
  if length(coalesce(p_reference, '')) > 160 then
    raise exception 'Payment reference is too long';
  end if;
  if p_request_id is null then
    raise exception 'Payment request identifier is required';
  end if;

  select jc.status into current_status
    from public.job_cards jc
   where jc.id = p_job_card_id and jc.workshop_id = current_workshop
   for update;
  if not found or current_status not in ('READY_FOR_PICKUP', 'DELIVERED') then
    raise exception 'Payments can only be recorded for an invoiced job';
  end if;
  select jp.job_card_id, jp.amount_paise, jp.method, jp.id
    into existing_request
    from public.job_payments jp
   where jp.workshop_id = current_workshop and jp.request_id = p_request_id;
  if found then
    if existing_request.job_card_id <> p_job_card_id
       or existing_request.amount_paise <> p_amount_paise
       or existing_request.method <> p_method then
      raise exception 'Payment request identifier was already used for a different payment';
    end if;
    select ji.grand_total_paise into invoice_total
      from public.job_invoices ji
     where ji.job_card_id = p_job_card_id and ji.workshop_id = current_workshop
       and ji.status = 'ISSUED';
    select coalesce(sum(jp.amount_paise), 0)::bigint into paid_total
      from public.job_payments jp
     where jp.job_card_id = p_job_card_id and jp.workshop_id = current_workshop;
    return jsonb_build_object(
      'payment_id', existing_request.id,
      'paid_paise', paid_total,
      'balance_paise', invoice_total - paid_total
    );
  end if;
  if current_status = 'DELIVERED' and not exists (
    select 1 from public.job_deliveries jd
     where jd.job_card_id = p_job_card_id
       and jd.workshop_id = current_workshop
       and jd.balance_at_delivery_paise > 0
  ) then
    raise exception 'This delivered job has no approved credit balance';
  end if;
  select ji.grand_total_paise into invoice_total
    from public.job_invoices ji
   where ji.job_card_id = p_job_card_id and ji.workshop_id = current_workshop
     and ji.status = 'ISSUED';
  if invoice_total is null then
    raise exception 'An issued invoice is required before recording payment';
  end if;
  select coalesce(sum(jp.amount_paise), 0)::bigint into paid_total
    from public.job_payments jp
   where jp.job_card_id = p_job_card_id and jp.workshop_id = current_workshop;
  if paid_total + p_amount_paise > invoice_total then
    raise exception 'Payment exceeds the outstanding balance';
  end if;
  insert into public.job_payments (
    workshop_id, job_card_id, amount_paise, method, reference, request_id,
    received_by_label
  ) values (
    current_workshop, p_job_card_id, p_amount_paise, p_method,
    trim(coalesce(p_reference, '')), p_request_id,
    coalesce((select auth.jwt() ->> 'email'), (select auth.uid())::text)
  ) returning id into new_payment_id;
  new_paid_total := paid_total + p_amount_paise;
  return jsonb_build_object(
    'payment_id', new_payment_id,
    'paid_paise', new_paid_total,
    'balance_paise', invoice_total - new_paid_total
  );
end;
$$;

create or replace function public.confirm_job_delivery(
  p_job_card_id uuid,
  p_credit_override_reason text
)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_role text;
  current_status text;
  invoice_total bigint;
  paid_total bigint;
  outstanding bigint;
  delivered_time timestamptz;
begin
  select wm.workshop_id, wm.role into current_workshop, current_role
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  select jc.status into current_status
    from public.job_cards jc
   where jc.id = p_job_card_id and jc.workshop_id = current_workshop
   for update;
  if not found or current_status <> 'READY_FOR_PICKUP' then
    raise exception 'This job is not awaiting vehicle pickup';
  end if;
  select ji.grand_total_paise into invoice_total
    from public.job_invoices ji
   where ji.job_card_id = p_job_card_id and ji.workshop_id = current_workshop
     and ji.status = 'ISSUED';
  if invoice_total is null then
    raise exception 'An issued invoice is required before delivery';
  end if;
  select coalesce(sum(jp.amount_paise), 0)::bigint into paid_total
    from public.job_payments jp
   where jp.job_card_id = p_job_card_id and jp.workshop_id = current_workshop;
  outstanding := invoice_total - paid_total;
  if outstanding < 0 then
    raise exception 'Payment ledger exceeds the invoice total; reconcile it before delivery';
  end if;
  if outstanding > 0 and (
    current_role <> 'owner'
    or length(trim(coalesce(p_credit_override_reason, ''))) not between 5 and 500
  ) then
    raise exception 'Clear the balance or ask a workshop owner to record a credit override';
  end if;
  insert into public.job_deliveries (
    workshop_id, job_card_id, balance_at_delivery_paise,
    credit_override_reason, delivered_by_label
  ) values (
    current_workshop, p_job_card_id, outstanding,
    case when outstanding > 0 then trim(p_credit_override_reason) else '' end,
    coalesce((select auth.jwt() ->> 'email'), (select auth.uid())::text)
  ) returning delivered_at into delivered_time;
  update public.job_cards set status = 'DELIVERED', updated_at = now()
   where id = p_job_card_id and workshop_id = current_workshop;
  return delivered_time;
end;
$$;

revoke all on function public.record_job_payment(uuid, bigint, text, text, uuid) from public, anon;
grant execute on function public.record_job_payment(uuid, bigint, text, text, uuid) to authenticated;
revoke all on function public.confirm_job_delivery(uuid, text) from public, anon;
grant execute on function public.confirm_job_delivery(uuid, text) to authenticated;
