-- Workshop-scoped parts, suppliers, and audited stock movement ledger.

create table public.inventory_suppliers (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  name text not null check (length(trim(name)) between 2 and 160),
  phone text not null default '' check (length(phone) <= 30),
  gstin text check (gstin is null or gstin ~ '^[A-Z0-9]{15}$'),
  address text not null default '' check (length(address) <= 500),
  created_at timestamptz not null default now(),
  unique (workshop_id, id),
  unique (workshop_id, name)
);

create table public.inventory_parts (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  sku text not null check (length(trim(sku)) between 1 and 48),
  name text not null check (length(trim(name)) between 2 and 160),
  category text not null default '',
  unit text not null default 'piece' check (unit in ('piece', 'set', 'litre', 'ml', 'kg', 'gram', 'metre', 'pack')),
  gst_rate_percent numeric(5,2) not null default 0 check (gst_rate_percent between 0 and 100),
  unit_cost_paise bigint not null default 0 check (unit_cost_paise >= 0),
  unit_price_paise bigint not null default 0 check (unit_price_paise >= 0),
  reorder_quantity numeric(10,2) not null default 0 check (reorder_quantity >= 0),
  on_hand_quantity numeric(10,2) not null default 0 check (on_hand_quantity >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workshop_id, id),
  unique (workshop_id, sku)
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  workshop_id uuid not null references public.workshops(id) on delete cascade,
  part_id uuid not null,
  supplier_id uuid,
  job_card_id uuid,
  movement_type text not null check (movement_type in ('RECEIPT', 'ISSUE', 'RETURN', 'ADJUSTMENT')),
  quantity numeric(10,2) not null check (quantity > 0),
  quantity_delta numeric(10,2) not null,
  stock_before numeric(10,2) not null check (stock_before >= 0),
  stock_after numeric(10,2) not null check (stock_after >= 0),
  unit_cost_paise bigint not null check (unit_cost_paise >= 0),
  note text not null default '' check (length(note) <= 500),
  recorded_by uuid not null default auth.uid() references auth.users(id),
  recorded_by_label text not null,
  created_at timestamptz not null default now(),
  foreign key (part_id, workshop_id)
    references public.inventory_parts(id, workshop_id) on delete cascade,
  foreign key (supplier_id, workshop_id)
    references public.inventory_suppliers(id, workshop_id),
  foreign key (job_card_id, workshop_id)
    references public.job_cards(id, workshop_id),
  check (stock_after = stock_before + quantity_delta),
  check (
    (movement_type in ('RECEIPT', 'RETURN') and quantity_delta = quantity)
    or (movement_type = 'ISSUE' and quantity_delta = -quantity)
    or (movement_type = 'ADJUSTMENT' and abs(quantity_delta) = quantity)
  )
);

create index inventory_parts_workshop_active_idx
  on public.inventory_parts(workshop_id, active, name);
create index inventory_movements_part_created_idx
  on public.inventory_movements(workshop_id, part_id, created_at desc);
create index inventory_movements_job_idx
  on public.inventory_movements(job_card_id, part_id)
  where job_card_id is not null;

alter table public.inventory_suppliers enable row level security;
alter table public.inventory_parts enable row level security;
alter table public.inventory_movements enable row level security;

create policy inventory_suppliers_member_read on public.inventory_suppliers
  for select to authenticated using (public.is_workshop_member(workshop_id));
create policy inventory_parts_member_read on public.inventory_parts
  for select to authenticated using (public.is_workshop_member(workshop_id));
create policy inventory_movements_member_read on public.inventory_movements
  for select to authenticated using (public.is_workshop_member(workshop_id));
grant select on public.inventory_suppliers, public.inventory_parts,
  public.inventory_movements to authenticated;
revoke insert, update, delete on public.inventory_suppliers,
  public.inventory_parts, public.inventory_movements from authenticated;

create or replace function public.save_inventory_supplier(
  p_name text,
  p_phone text,
  p_gstin text,
  p_address text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  new_supplier_id uuid;
  clean_gstin text := nullif(upper(trim(coalesce(p_gstin, ''))), '');
begin
  select wm.workshop_id into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid()) and wm.role in ('owner', 'advisor');
  if current_workshop is null then
    raise exception 'Only workshop owners and advisors can manage suppliers';
  end if;
  if length(trim(coalesce(p_name, ''))) not between 2 and 160
     or length(coalesce(p_phone, '')) > 30
     or length(coalesce(p_address, '')) > 500
     or (clean_gstin is not null and clean_gstin !~ '^[A-Z0-9]{15}$') then
    raise exception 'Check the supplier details and try again';
  end if;
  insert into public.inventory_suppliers(workshop_id, name, phone, gstin, address)
  values (
    current_workshop, trim(p_name), trim(coalesce(p_phone, '')),
    clean_gstin, trim(coalesce(p_address, ''))
  ) returning id into new_supplier_id;
  return new_supplier_id;
exception when unique_violation then
  raise exception 'A supplier with this name already exists';
end;
$$;

create or replace function public.save_inventory_part(
  p_sku text,
  p_name text,
  p_category text,
  p_unit text,
  p_gst_rate_percent numeric,
  p_unit_cost_paise bigint,
  p_unit_price_paise bigint,
  p_reorder_quantity numeric
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  new_part_id uuid;
begin
  select wm.workshop_id into current_workshop
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid()) and wm.role in ('owner', 'advisor');
  if current_workshop is null then
    raise exception 'Only workshop owners and advisors can manage the parts catalog';
  end if;
  if length(trim(coalesce(p_sku, ''))) not between 1 and 48
     or length(trim(coalesce(p_name, ''))) not between 2 and 160
     or length(coalesce(p_category, '')) > 80
     or coalesce(p_unit, '') not in ('piece', 'set', 'litre', 'ml', 'kg', 'gram', 'metre', 'pack')
     or p_gst_rate_percent is null or p_gst_rate_percent not between 0 and 100
     or p_unit_cost_paise is null or p_unit_cost_paise < 0
     or p_unit_price_paise is null or p_unit_price_paise < 0
     or p_reorder_quantity is null or p_reorder_quantity < 0 then
    raise exception 'Check the part details and try again';
  end if;
  insert into public.inventory_parts (
    workshop_id, sku, name, category, unit, gst_rate_percent,
    unit_cost_paise, unit_price_paise, reorder_quantity
  ) values (
    current_workshop, upper(trim(p_sku)), trim(p_name),
    trim(coalesce(p_category, '')), p_unit, p_gst_rate_percent,
    p_unit_cost_paise, p_unit_price_paise, p_reorder_quantity
  ) returning id into new_part_id;
  return new_part_id;
exception when unique_violation then
  raise exception 'A part with this SKU already exists';
end;
$$;

create or replace function public.record_inventory_movement(
  p_part_id uuid,
  p_movement_type text,
  p_quantity numeric,
  p_supplier_id uuid,
  p_job_card_id uuid,
  p_note text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_workshop uuid;
  current_role text;
  linked_job_status text;
  part_row record;
  movement_delta numeric(10,2);
  stock_after numeric(10,2);
  unit_cost bigint;
  movement_id uuid;
  approved_quantity numeric(10,2);
  already_issued numeric(10,2);
begin
  select wm.workshop_id, wm.role into current_workshop, current_role
    from public.workshop_memberships wm
   where wm.user_id = (select auth.uid());
  if current_workshop is null then
    raise exception 'Your account is not linked to a workshop';
  end if;
  if coalesce(p_movement_type, '') not in ('RECEIPT', 'ISSUE', 'RETURN', 'ADJUSTMENT')
     or p_quantity is null or p_quantity <= 0
     or length(coalesce(p_note, '')) > 500 then
    raise exception 'Check the stock movement details and try again';
  end if;
  if current_role = 'technician' and p_movement_type not in ('ISSUE', 'RETURN') then
    raise exception 'Technicians can only issue or return parts for approved work';
  end if;
  if current_role not in ('owner', 'advisor', 'technician') then
    raise exception 'Your workshop role cannot record stock movements';
  end if;
  if p_movement_type = 'RECEIPT' and p_supplier_id is null then
    raise exception 'Select the supplier for this stock receipt';
  end if;
  if p_movement_type = 'ADJUSTMENT'
     and length(trim(coalesce(p_note, ''))) < 5 then
    raise exception 'Add a reason for the stock adjustment';
  end if;
  if p_movement_type in ('ISSUE', 'RETURN') and p_job_card_id is null then
    raise exception 'Select the job that uses these parts';
  end if;
  if p_movement_type in ('ISSUE', 'RETURN') then
    select jc.status into linked_job_status
      from public.job_cards jc
     where jc.id = p_job_card_id and jc.workshop_id = current_workshop
     for update;
    if not found or linked_job_status <> 'WORK_IN_PROGRESS' then
      raise exception 'Parts can only be issued or returned while work is in progress';
    end if;
  end if;

  select ip.id, ip.sku, ip.unit_cost_paise, ip.on_hand_quantity
    into part_row
    from public.inventory_parts ip
   where ip.id = p_part_id and ip.workshop_id = current_workshop and ip.active
   for update;
  if not found then
    raise exception 'Active part not found in your workshop';
  end if;
  if p_supplier_id is not null and not exists (
    select 1 from public.inventory_suppliers s
     where s.id = p_supplier_id and s.workshop_id = current_workshop
  ) then
    raise exception 'Supplier not found in your workshop';
  end if;

  movement_delta := case
    when p_movement_type in ('RECEIPT', 'RETURN') then p_quantity
    when p_movement_type = 'ISSUE' then -p_quantity
    else case when left(trim(coalesce(p_note, '')), 1) = '+' then p_quantity else -p_quantity end
  end;
  if p_movement_type = 'ADJUSTMENT'
     and left(trim(coalesce(p_note, '')), 1) not in ('+', '-') then
    raise exception 'Start the adjustment reason with + or - to set the stock direction';
  end if;
  stock_after := part_row.on_hand_quantity + movement_delta;
  if stock_after < 0 then
    raise exception 'There is not enough stock for this movement';
  end if;

  if p_movement_type in ('ISSUE', 'RETURN') then
    if p_movement_type = 'ISSUE' then
      select coalesce(sum(li.quantity), 0)::numeric(10,2)
        into approved_quantity
        from public.job_line_items li
        join public.job_cards jc
          on jc.id = li.job_card_id and jc.workshop_id = li.workshop_id
       where li.job_card_id = p_job_card_id
         and li.workshop_id = current_workshop
         and li.item_type = 'part'
         and li.code = part_row.sku
         and li.approval_status = 'APPROVED'
         and jc.status = 'WORK_IN_PROGRESS';
      if approved_quantity = 0 then
        raise exception 'This part is not on the approved estimate for active work';
      end if;
      select coalesce(sum(im.quantity_delta), 0)::numeric(10,2)
        into already_issued
        from public.inventory_movements im
       where im.job_card_id = p_job_card_id
         and im.part_id = p_part_id
         and im.workshop_id = current_workshop;
      if already_issued + p_quantity > approved_quantity then
        raise exception 'Issue quantity exceeds the approved estimate quantity';
      end if;
    else
      select coalesce(sum(-im.quantity_delta), 0)::numeric(10,2)
        into already_issued
        from public.inventory_movements im
       where im.job_card_id = p_job_card_id
         and im.part_id = p_part_id
         and im.workshop_id = current_workshop
         and im.movement_type in ('ISSUE', 'RETURN');
      if p_quantity > already_issued then
        raise exception 'Return quantity exceeds the parts issued to this job';
      end if;
    end if;
  end if;

  insert into public.inventory_movements (
    workshop_id, part_id, supplier_id, job_card_id, movement_type,
    quantity, quantity_delta, stock_before, stock_after,
    unit_cost_paise, note, recorded_by_label
  ) values (
    current_workshop, p_part_id, p_supplier_id, p_job_card_id, p_movement_type,
    p_quantity, movement_delta, part_row.on_hand_quantity, stock_after,
    part_row.unit_cost_paise, trim(coalesce(p_note, '')),
    coalesce((select auth.jwt() ->> 'email'), (select auth.uid())::text)
  ) returning id into movement_id;
  update public.inventory_parts
     set on_hand_quantity = stock_after, updated_at = now()
   where id = p_part_id and workshop_id = current_workshop;
  return jsonb_build_object(
    'movement_id', movement_id,
    'stock_before', part_row.on_hand_quantity,
    'stock_after', stock_after
  );
end;
$$;

revoke all on function public.save_inventory_supplier(text, text, text, text) from public, anon;
grant execute on function public.save_inventory_supplier(text, text, text, text) to authenticated;
revoke all on function public.save_inventory_part(text, text, text, text, numeric, bigint, bigint, numeric) from public, anon;
grant execute on function public.save_inventory_part(text, text, text, text, numeric, bigint, bigint, numeric) to authenticated;
revoke all on function public.record_inventory_movement(uuid, text, numeric, uuid, uuid, text) from public, anon;
grant execute on function public.record_inventory_movement(uuid, text, numeric, uuid, uuid, text) to authenticated;
