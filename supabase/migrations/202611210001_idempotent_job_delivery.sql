-- Return the committed delivery timestamp when a client retries after a lost response.
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
  if not found then
    raise exception 'This job is not awaiting vehicle pickup';
  end if;
  if current_status = 'DELIVERED' then
    select jd.delivered_at into delivered_time
      from public.job_deliveries jd
     where jd.job_card_id = p_job_card_id
       and jd.workshop_id = current_workshop;
    if delivered_time is not null then
      return delivered_time;
    end if;
    raise exception 'Delivery status exists without a delivery record';
  end if;
  if current_status <> 'READY_FOR_PICKUP' then
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

revoke all on function public.confirm_job_delivery(uuid, text) from public, anon;
grant execute on function public.confirm_job_delivery(uuid, text) to authenticated;
