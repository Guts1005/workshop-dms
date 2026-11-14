# Implementation Plan: Automotive Workshop Management System (Flutter)

## Phased Vertical Delivery Roadmap

### Phase 1: Environment & Core Scaffold
- [ ] Initialize Flutter project in `e:\Users\sharv\Downloads\Bhavy Project`
- [ ] Configure `pubspec.yaml` with required dependencies:
  - `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
  - `camera`, `camera_windows`, `record`, `permission_handler`
  - `supabase_flutter`, `crypto`, `uuid`, `intl`, `qr_flutter`, `pdf`, `printing`
- [ ] Set up clean modular directory structure (`lib/core`, `lib/features`, `lib/data`)

### Phase 2: Design Tokens & Custom Flat Widget System
- [ ] Implement `AppTheme` token contract (Base `#E4E2DD`, Surface `#D9D6D0`, Inverse `#1E1E1E`, Raised `#FFFFFF`)
- [ ] Build `SharpButton` (Primary `#1E1E1E`, Pressed `#FFFFFF` with `#DB4A2B`, Secondary 1px outline, 0px radius, 48px hit target)
- [ ] Build `SharpCard` & `SharpPanel` with strict `1px solid #1E1E1E` borders and sharp 90° corners
- [ ] Build `StatusChip` with icon + text label (`#DB4A2B`, `#F8A348`, `#2E6B3F`, neutral outline)
- [ ] Build `SharpFocusRing` (3px solid #1E1E1E with 2px offset; #E4E2DD on dark surfaces)
- [ ] Build `MonospaceText` and Indian Rupee / KM formatters

### Phase 3: Drift Database & Local Storage Layer
- [ ] Define Drift SQLite tables with integer paise financial types:
  - `Vehicles`, `Customers`, `JobCards`, `JobItems`, `BayPhotos`, `DamagePins`
  - `InventoryParts`, `Invoices`, `Payments`, `CreditOverrides`, `SyncQueue`
- [ ] Implement DAOs with reactive streams (`watchAll()`, `watchJobCard()`)
- [ ] Implement client-side UUIDv4 generators and offline sandbox file managers

### Phase 4: Bay Check-in Camera Engine (6 Mandatory Shots)
- [ ] Build `BayCameraOverlay` with 1px `#1E1E1E` wireframe guides for 45° corner alignment
- [ ] Implement sequential 6-shot state machine (`CORNER_FL` -> `CORNER_FR` -> `CORNER_RL` -> `CORNER_RR` -> `PLATE` -> `ODOMETER`)
- [ ] Compute client-side SHA-256 hash immediately on capture
- [ ] Implement Job Card check-in gate (cannot proceed without all 6 verified shots)

### Phase 5: Condition Map CustomPainter & Damage Annotation
- [ ] Build 4-view line art vector paths (Side, Front, Rear, Top) in `CustomPainter`
- [ ] Implement polygon hit-testing with 48px minimum touch zones
- [ ] Implement `#DB4A2B` numbered pin drops with defect classification dialog (Dent, Scratch, Chip, Crack)
- [ ] Build 6 vehicle silhouette icons (Hatchback, Sedan, Sub-4m SUV, Mid/Full SUV, MPV, Pickup)

### Phase 6: Job Card Engine & Live Status Workflow
- [ ] Implement 5-stage status pipeline:
  `Received` -> `Inspection Pending` -> `Estimate Sent` -> `Work in Progress` -> `Delivered`
- [ ] Build Labour and Parts line-item editor with voice-note recording attachment
- [ ] Build customer check-in WhatsApp link generator

### Phase 7: Spare Parts Inventory Management
- [ ] Build Parts Catalog (SKU, Part Name, Category, HSN Code, Cost Price, Selling Price, Stock Qty)
- [ ] Implement low-stock reorder alerts
- [ ] Deduct inventory quantities automatically when job card items are marked as used

### Phase 8: Automotive GST Invoicing Engine
- [ ] Implement dual GST engine:
  - Labour SAC `998729` @ 18%
  - Parts HSN @ 18% or 28%
- [ ] Implement auto-split for CGST + SGST vs. IGST
- [ ] Implement high-density PDF invoice generator styled in the "Digital Health Passport" theme

### Phase 9: Strict Payment Gate & Debtors Ledger
- [ ] Build Payment Reconciliation Modal (Cash, UPI, Card, NetBanking)
- [ ] Implement the Delivery Gate (blocks "Delivered" if balance > 0)
- [ ] Build Credit Override mechanism (`authorized_by`, `promised_due_date`, `reason`)
- [ ] Build Outstanding Debtors Ledger with aging metrics

### Phase 10: Digital Health Passport & QR Engine
- [ ] Generate vehicle QR codes on invoices linking to the public passport endpoint
- [ ] Build the Digital Health Passport screen:
  - Hero image (FL 45° shot)
  - Number plate blur filter for privacy
  - Historical service timeline (adapted from MG app with expandable parts/labour breakdown)
  - Component wear level tracking (Brake pad %, Battery voltage, Tyre tread mm)

### Phase 11: Dual-Trigger Service Reminders
- [ ] Implement daily average mileage projection engine:
  `daily_km = (odometer_current - odometer_previous) / days_between`
- [ ] Build Dual-Trigger evaluation: Alert when `projected_km_date` OR `calendar_interval_date` is reached
- [ ] Build Service Reminders Tab with one-click personalized WhatsApp dispatch

### Phase 12: Supabase PostgreSQL & Cloudflare R2 Sync Engine
- [ ] Set up Supabase schema migrations with `workshop_id` multi-tenancy and RLS policies
- [ ] Implement Edge Function for generating presigned R2 upload URLs
- [ ] Implement background sync worker processing the `SyncQueue` table
- [ ] Create automated GitHub Actions cron workflow for scheduled `pg_dump` backups to R2
