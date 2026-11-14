# Automotive Workshop Management System (DMS)
## Master System Specification & Architecture

**Document Version:** 1.0.0  
**Target Platform:** Flutter (Windows, Android, iOS)  
**Database:** Drift (Local SQLite) + Supabase PostgreSQL (Mumbai `ap-south-1`)  
**Media Storage:** Cloudflare R2 via Presigned URLs  
**Design System:** Digital Health Passport (Sharp Industrial Brutalism)

---

## 1. System Capability Map & Module Boundaries

```
[M01: CORE & THEME] ──────────→ Design tokens, custom flat widgets, focus & touch engine
       │
[M02: DATABASE & DRIFT] ──────→ Local SQLite schema, DAOs, migrations, client UUIDs
       │
[M03: SYNC & OUTBOX] ─────────→ Outbox table, SHA-256 queue, Supabase PostgreSQL, R2 upload
       │
[M04: VEHICLE & MAKE] ────────→ 6 SVG silhouettes, uppercase wordmarks, registration logic
       │
[M05: BAY CHECK-IN] ──────────→ 6 mandatory shots, 45° guides, camera overlay, tamper-proof hashes
       │
[M06: CONDITION MAP] ─────────→ CustomPainter 4-view line art, 48px hit zones, #DB4A2B pin drops
       │
[M07: JOB CARD ENGINE] ───────→ 5-stage status machine, labour & parts items, voice notes
       │
[M08: INVENTORY & PARTS] ─────→ SKU, cost vs. selling, HSN codes, low-stock reorder triggers
       │
[M09: GST & BILLING] ─────────→ SAC 998729 (18%) + HSN (18%/28%), CGST/SGST vs IGST engine
       │
[M10: STRICT PAYMENT GATE] ───→ Balance == 0 verification, credit override ledger, audit log
       │
[M11: WHATSAPP DISPATCH] ─────→ wa.me URL builder, PDF estimate/invoice sharing, ack tracker
       │
[M12: DIGITAL PASSPORT] ──────→ QR code, public web view, blurred plates, component wear history
       │
[M13: DUAL-TRIGGER REMINDERS] ─→ Time (180d) + Odometer daily-rate projection engine
```

---

## 2. Tokenized Design System Specification

### 2.1 Palette Tokens
* **Base (Background):** `#E4E2DD`
* **Surface (Panels, Header Rows, Groups):** `#D9D6D0`
* **Inverse (Top Bar, Footers, Selection):** `#1E1E1E`
* **Raised (Inputs, Pressed Buttons):** `#FFFFFF`

### 2.2 Text & Typography
* **Font Family:** `JetBrains Mono` / `Geist Mono` for VINs, Numbers, Dates, Currency, HSN; `Inter` for prose.
* **Primary Text:** `#1E1E1E`
* **Secondary Text:** `#444444` (Labels, metadata, units)
* **On Dark Text:** `#E4E2DD`
* **Minimum Body Size:** `16px` (arm's length readability on garage floor)

### 2.3 Borders & Dividers
* **Interactive Elements:** `1px solid #1E1E1E` (Inputs, buttons, cards, tappable rows)
* **Tappable Table Rows:** `1px solid #1E1E1E` bottom border
* **Passive Read-Only Dividers:** `1px rgba(30, 30, 30, 0.3)`

### 2.4 Accents & Status Chips
* **Red-Orange (`#DB4A2B`):** Active tab bar, critical/overdue chip (`#FFFFFF` text), damage markers.
* **Orange (`#F8A348`):** Due-soon status, progress fills (`#1E1E1E` text).
* **Green (`#2E6B3F`):** Paid, passed, healthy status (`#FFFFFF` text).
* **Pink (`#FF89A9`):** Pressed row/card background tint ONLY with `#1E1E1E` text (7.5:1). Never a border, ring, or text color.
* **Focus Ring:** `3px solid #1E1E1E` with `2px offset`. On `#1E1E1E` surfaces: `3px solid #E4E2DD` with `2px offset`.

### 2.5 Touch Ergonomics
* Minimum tap target size: `48px x 48px`
* Minimum gap between targets: `8px`
* Table row height: `56px`
* Border radius: `0px` (Strict 90° sharp corners everywhere)
* Hover states: Disabled. Every interaction maps to immediate pressed feedback.

---

## 3. Bay Check-in Capture Protocol (The Operational Evidence Gate)

### 3.1 The 6 Mandatory Shots
A Job Card **cannot be opened or created** until all 6 shots are captured:
1. `CORNER_FL`: Front-Left corner at 45° (Also acts as the Digital Passport Hero Image)
2. `CORNER_FR`: Front-Right corner at 45°
3. `CORNER_RL`: Rear-Left corner at 45°
4. `CORNER_RR`: Rear-Right corner at 45°
5. `PLATE_CLOSEUP`: High-resolution registration plate close-up
6. `ODOMETER`: Odometer and instrument cluster reading

*Optional Shots:* Dashboard with ignition on (warning lights check), Paint code / VIN B-pillar sticker.

### 3.2 Capture Constraints
* Device: Android or iOS rear camera primary. Windows USB camera as fallback. (Laptop webcam disabled for 6-shot set).
* Overlay: Native 1px `#1E1E1E` wireframe alignment guides indicating 45° corner perspective.
* Gallery upload: Strictly **disabled** for check-in shots (prevents pre-damage fraud).
* Integrity: SHA-256 computed on device immediately after shutter press.
* Offline Queue: Local file sandbox storage → background sync to Cloudflare R2 when network is detected.

---

## 4. Vehicle Identity & 360° Condition Map

### 4.1 Silhouette Library
Six standardized 1px line-art SVG profiles with identical ground lines, wheel proportions, and viewBox:
1. `HATCHBACK`
2. `SEDAN`
3. `SUB_4M_SUV`
4. `MID_FULL_SUV`
5. `MPV`
6. `PICKUP_VAN`
7. `GENERIC_FALLBACK`

### 4.2 Make Wordmark
* Uppercase monospace outlined chip: `[MARUTI SUZUKI]`, `[HYUNDAI]`, `[TATA]`, `[MAHINDRA]`, `[TOYOTA]`, etc.
* Zero OEM logos, zero brand colors. Searchable dropdown with custom free-text fallback.

### 4.3 Interactive Condition Map
* Drawn via Flutter `CustomPainter`.
* 4 views: Side Profile, Front Profile, Rear Profile, Top/Roof View.
* Tappable polygon zones (Bumper, Fender, Door Front-Left, Door Rear-Left, Quarter Panel, Roof, Bonnet, Windshield, Boot).
* Damage marker: `#DB4A2B` circle with sequential number (`1`, `2`, `3...`), minimum 24px diameter.
* Defect classification: `DENT`, `DEEP_SCRATCH`, `SURFACE_SCUFF`, `PAINT_CHIP`, `GLASS_CRACK`, `RUST`.
* Severity: `LEVEL_1_MINOR`, `LEVEL_2_MODERATE`, `LEVEL_3_SEVERE`.

---

## 5. Billing, GST Engine & Strict Payment Gate

### 5.1 Real-World Automotive GST Calculation
* **Labour & Services:** SAC `998729` @ **18% GST**
* **Parts & Spares:** Itemized with HSN code @ **18% or 28% GST**
* **Tax Splitting:**
  * If Customer State == Workshop State: `CGST = Tax / 2`, `SGST = Tax / 2`
  * If Customer State != Workshop State: `IGST = Tax`

### 5.2 Strict Payment Gate Workflow
```
[Mark as Delivered Triggered]
          │
    Balance == 0?
       ├── YES ──→ [STATUS: DELIVERED] → Final Invoice Issued → Key Handover
       └── NO  ──→ [MODAL: UNPAID BALANCE DETECTED]
                     ├── Record Payment (Cash, UPI, Card, NetBanking)
                     └── OR Credit Override:
                           • Authorized By: [Manager / Owner]
                           • Promised Due Date: [Mandatory Date]
                           • Reason: [Fleet / VIP / Delayed]
                           • Action: Moves to Debtors Ledger with auto-reminders
```

---

## 6. Data Architecture & Sync Protocol

### 6.1 Local Layer (Drift / SQLite)
* Zero cloud dependency for daily operations. Every query, write, and report runs against local SQLite.
* Outbox pattern table: `sync_queue` stores pending mutations with client-generated UUIDv4.

### 6.2 Cloud Layer (Supabase PostgreSQL + R2)
* Supabase Mumbai region (`ap-south-1`) with Row-Level Security enforced by `workshop_id`.
* Presigned Cloudflare R2 URLs generated via Supabase Edge Functions for fast, zero-egress-fee media uploads.
* Client-side SHA-256 hash sent with upload request; server validates hash before saving record.
