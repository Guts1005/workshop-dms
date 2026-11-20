create table public.invoice_number_sequences (
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  financial_year text not null,
  last_number integer not null check (last_number > 0),
  primary key (workshop_id, financial_year)
);

create table public.workshop_invoice_profiles (
  workshop_id uuid primary key references public.workshops(id) on delete cascade,
  legal_name text not null,
  address text not null,
  gstin text not null check (gstin ~ '^[A-Z0-9]{15}$'),
  state_code text not null check (state_code ~ '^[0-9]{2}$'),
  updated_at timestamptz not null default now()
);

create table public.customer_invoice_profiles (
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  customer_id uuid not null,
  billing_address text not null,
  gstin text check (gstin is null or gstin ~ '^[A-Z0-9]{15}$'),
  place_of_supply_state_code text not null check (place_of_supply_state_code ~ '^[0-9]{2}$'),
  updated_at timestamptz not null default now(),
  primary key (workshop_id, customer_id),
  foreign key (customer_id, workshop_id)
    references public.customers(id, workshop_id) on delete cascade
);

create table public.job_invoices (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  job_card_id uuid not null unique,
  invoice_number text not null,
  financial_year text not null,
  serial_number integer not null check (serial_number > 0),
  issue_date date not null,
  supplier_name text not null,
  supplier_address text not null,
  supplier_gstin text not null check (supplier_gstin ~ '^[A-Z0-9]{15}$'),
  supplier_state_code text not null check (supplier_state_code ~ '^[0-9]{2}$'),
  recipient_name text not null,
  recipient_address text not null,
  recipient_gstin text check (
    recipient_gstin is null or recipient_gstin ~ '^[A-Z0-9]{15}$'
  ),
  place_of_supply_state_code text not null check (place_of_supply_state_code ~ '^[0-9]{2}$'),
  tax_type text not null check (tax_type in ('INTRA_STATE', 'INTER_STATE')),
  total_taxable_paise bigint not null check (total_taxable_paise >= 0),
  cgst_paise bigint not null check (cgst_paise >= 0),
  sgst_paise bigint not null check (sgst_paise >= 0),
  igst_paise bigint not null check (igst_paise >= 0),
  total_tax_paise bigint not null check (total_tax_paise >= 0),
  grand_total_paise bigint not null check (grand_total_paise >= 0),
  status text not null default 'ISSUED' check (status in ('ISSUED', 'CANCELLED')),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  unique (workshop_id, invoice_number),
  unique (workshop_id, financial_year, serial_number),
  unique (id, workshop_id),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id) on delete cascade,
  check (grand_total_paise = total_taxable_paise + total_tax_paise),
  check (total_tax_paise = cgst_paise + sgst_paise + igst_paise),
  check (
    (tax_type = 'INTRA_STATE' and igst_paise = 0)
    or (tax_type = 'INTER_STATE' and cgst_paise = 0 and sgst_paise = 0)
  )
);

create table public.job_invoice_lines (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  invoice_id uuid not null,
  source_line_item_id uuid not null,
  item_type text not null check (item_type in ('labour', 'part')),
  description text not null,
  code text not null,
  quantity numeric(10,2) not null check (quantity > 0),
  unit_rate_paise bigint not null check (unit_rate_paise >= 0),
  gst_rate_percent numeric(5,2) not null check (gst_rate_percent between 0 and 100),
  taxable_paise bigint not null check (taxable_paise >= 0),
  cgst_paise bigint not null check (cgst_paise >= 0),
  sgst_paise bigint not null check (sgst_paise >= 0),
  igst_paise bigint not null check (igst_paise >= 0),
  total_paise bigint not null check (total_paise = taxable_paise + cgst_paise + sgst_paise + igst_paise),
  foreign key (invoice_id, workshop_id)
    references public.job_invoices(id, workshop_id) on delete cascade
);

create index job_invoices_workshop_date_idx
  on public.job_invoices(workshop_id, issue_date desc);
create index job_invoice_lines_invoice_idx
  on public.job_invoice_lines(invoice_id);

alter table public.invoice_number_sequences enable row level security;
alter table public.workshop_invoice_profiles enable row level security;
alter table public.customer_invoice_profiles enable row level security;
alter table public.job_invoices enable row level security;
alter table public.job_invoice_lines enable row level security;

create policy job_invoices_member_read on public.job_invoices for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy job_invoice_lines_member_read on public.job_invoice_lines for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy workshop_invoice_profiles_member_read on public.workshop_invoice_profiles for select to authenticated
  using (public.is_workshop_member(workshop_id));
create policy customer_invoice_profiles_member_read on public.customer_invoice_profiles for select to authenticated
  using (public.is_workshop_member(workshop_id));

grant select on public.job_invoices, public.job_invoice_lines,
  public.workshop_invoice_profiles, public.customer_invoice_profiles to authenticated;
revoke all on public.invoice_number_sequences from authenticated;
revoke insert, update, delete on public.job_invoices, public.job_invoice_lines,
  public.workshop_invoice_profiles, public.customer_invoice_profiles from authenticated;

create or replace function public.issue_job_invoice(
  p_job_card_id uuid,
  p_supplier_name text,
  p_supplier_address text,
  p_supplier_gstin text,
  p_supplier_state_code text,
  p_recipient_address text,
  p_recipient_gstin text,
  p_place_of_supply_state_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_status text;
  recipient_customer_id uuid;
  recipient_name text;
  invoice_date date := (now() at time zone 'Asia/Kolkata')::date;
  fy_start integer;
  fy_end integer;
  fy_label text;
  next_serial integer;
  new_invoice_id uuid;
  new_invoice_number text;
  new_tax_type text;
  taxable_total bigint;
  cgst_total bigint;
  sgst_total bigint;
  igst_total bigint;
  tax_total bigint;
begin
  select wm.workshop_id
    into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if length(trim(coalesce(p_supplier_name, ''))) < 2
     or length(trim(coalesce(p_supplier_address, ''))) < 5
     or length(coalesce(p_supplier_address, '')) > 500
     or coalesce(p_supplier_gstin, '') !~ '^[A-Z0-9]{15}$'
     or coalesce(p_supplier_state_code, '') !~ '^[0-9]{2}$'
     or left(upper(coalesce(p_supplier_gstin, '')), 2) <> p_supplier_state_code
     or length(trim(coalesce(p_recipient_address, ''))) < 5
     or length(coalesce(p_recipient_address, '')) > 500
     or coalesce(p_place_of_supply_state_code, '') !~ '^[0-9]{2}$' then
    raise exception 'Complete the supplier and recipient tax invoice details';
  end if;
  if p_recipient_gstin is not null
     and p_recipient_gstin !~ '^[A-Z0-9]{15}$' then
    raise exception 'Enter a valid recipient GSTIN or leave it blank';
  end if;

  select jc.status, jc.customer_id
    into current_status, recipient_customer_id
    from public.job_cards jc
   where jc.id = p_job_card_id
     and jc.workshop_id = current_workshop
   for update;
  if not found or current_status <> 'QC_PASSED' then
    raise exception 'An invoice can only be issued after QC has passed';
  end if;
  if exists (
    select 1 from public.job_invoices ji
     where ji.job_card_id = p_job_card_id and ji.workshop_id = current_workshop
  ) then
    raise exception 'An invoice already exists for this job';
  end if;

  select c.name into recipient_name
    from public.customers c
   where c.id = recipient_customer_id and c.workshop_id = current_workshop;
  if recipient_name is null then
    raise exception 'Customer record was not found';
  end if;

  insert into public.workshop_invoice_profiles (
    workshop_id, legal_name, address, gstin, state_code, updated_at
  ) values (
    current_workshop, trim(p_supplier_name), trim(p_supplier_address),
    upper(trim(p_supplier_gstin)), p_supplier_state_code, now()
  ) on conflict (workshop_id) do update set
    legal_name = excluded.legal_name,
    address = excluded.address,
    gstin = excluded.gstin,
    state_code = excluded.state_code,
    updated_at = now();

  insert into public.customer_invoice_profiles (
    workshop_id, customer_id, billing_address, gstin,
    place_of_supply_state_code, updated_at
  ) values (
    current_workshop, recipient_customer_id, trim(p_recipient_address),
    nullif(upper(trim(coalesce(p_recipient_gstin, ''))), ''),
    p_place_of_supply_state_code, now()
  ) on conflict (workshop_id, customer_id) do update set
    billing_address = excluded.billing_address,
    gstin = excluded.gstin,
    place_of_supply_state_code = excluded.place_of_supply_state_code,
    updated_at = now();
  if not exists (
    select 1 from public.job_line_items li
     where li.job_card_id = p_job_card_id
       and li.workshop_id = current_workshop
       and li.approval_status = 'APPROVED'
  ) or exists (
    select 1 from public.job_line_items li
     where li.job_card_id = p_job_card_id
       and li.workshop_id = current_workshop
       and li.approval_status <> 'APPROVED'
  ) then
    raise exception 'Every invoiced estimate item must have customer approval';
  end if;

  new_tax_type := case
    when p_supplier_state_code = p_place_of_supply_state_code then 'INTRA_STATE'
    else 'INTER_STATE'
  end;
  fy_start := extract(year from invoice_date)::integer
    - case when extract(month from invoice_date) < 4 then 1 else 0 end;
  fy_end := (fy_start + 1) % 100;
  fy_label := fy_start::text || '-' || lpad(fy_end::text, 2, '0');

  insert into public.invoice_number_sequences(workshop_id, financial_year, last_number)
    values (current_workshop, fy_label, 1)
  on conflict (workshop_id, financial_year)
    do update set last_number = invoice_number_sequences.last_number + 1
  returning last_number into next_serial;
  new_invoice_number := 'INV/' || fy_label || '/' || lpad(
    next_serial::text, greatest(5, length(next_serial::text)), '0'
  );

  with line_tax as (
    select
      li.item_type,
      li.description,
      li.code,
      li.quantity,
      li.unit_rate_paise,
      li.gst_rate_percent,
      round(li.quantity * li.unit_rate_paise)::bigint as taxable,
      round(round(li.quantity * li.unit_rate_paise) * li.gst_rate_percent / 100)::bigint as tax
    from public.job_line_items li
    where li.job_card_id = p_job_card_id
      and li.workshop_id = current_workshop
      and li.approval_status = 'APPROVED'
  )
  select
    coalesce(sum(taxable), 0)::bigint,
    coalesce(sum(case when new_tax_type = 'INTRA_STATE' then round(tax / 2.0)::bigint else 0 end), 0)::bigint,
    coalesce(sum(case when new_tax_type = 'INTRA_STATE' then tax - round(tax / 2.0)::bigint else 0 end), 0)::bigint,
    coalesce(sum(case when new_tax_type = 'INTER_STATE' then tax else 0 end), 0)::bigint
  into taxable_total, cgst_total, sgst_total, igst_total
  from line_tax;
  tax_total := cgst_total + sgst_total + igst_total;

  insert into public.job_invoices (
    workshop_id, job_card_id, invoice_number, financial_year, serial_number,
    issue_date, supplier_name, supplier_address, supplier_gstin,
    supplier_state_code, recipient_name, recipient_address, recipient_gstin,
    place_of_supply_state_code, tax_type, total_taxable_paise,
    cgst_paise, sgst_paise, igst_paise, total_tax_paise, grand_total_paise
  ) values (
    current_workshop, p_job_card_id, new_invoice_number, fy_label, next_serial,
    invoice_date, trim(p_supplier_name), trim(p_supplier_address), p_supplier_gstin,
    p_supplier_state_code, recipient_name, trim(p_recipient_address),
    nullif(trim(p_recipient_gstin), ''), p_place_of_supply_state_code,
    new_tax_type, taxable_total, cgst_total, sgst_total, igst_total,
    tax_total, taxable_total + tax_total
  ) returning id into new_invoice_id;

  insert into public.job_invoice_lines (
    workshop_id, invoice_id, source_line_item_id, item_type, description, code,
    quantity, unit_rate_paise, gst_rate_percent, taxable_paise,
    cgst_paise, sgst_paise, igst_paise, total_paise
  )
  with line_tax as (
    select
      li.id, li.item_type, li.description, li.code, li.quantity,
      li.unit_rate_paise, li.gst_rate_percent,
      round(li.quantity * li.unit_rate_paise)::bigint as taxable,
      round(round(li.quantity * li.unit_rate_paise) * li.gst_rate_percent / 100)::bigint as tax
    from public.job_line_items li
    where li.job_card_id = p_job_card_id
      and li.workshop_id = current_workshop
      and li.approval_status = 'APPROVED'
  )
  select current_workshop, new_invoice_id, id, item_type, description, code,
    quantity, unit_rate_paise, gst_rate_percent, taxable,
    case when new_tax_type = 'INTRA_STATE' then round(tax / 2.0)::bigint else 0 end,
    case when new_tax_type = 'INTRA_STATE' then tax - round(tax / 2.0)::bigint else 0 end,
    case when new_tax_type = 'INTER_STATE' then tax else 0 end,
    taxable + tax
  from line_tax;

  update public.job_cards
     set status = 'READY_FOR_PICKUP', updated_at = now()
   where id = p_job_card_id and workshop_id = current_workshop;

  return jsonb_build_object(
    'invoice_id', new_invoice_id,
    'invoice_number', new_invoice_number,
    'grand_total_paise', taxable_total + tax_total,
    'tax_type', new_tax_type
  );
end;
$$;

revoke all on function public.issue_job_invoice(
  uuid, text, text, text, text, text, text, text
) from public, anon;
grant execute on function public.issue_job_invoice(
  uuid, text, text, text, text, text, text, text
) to authenticated;
