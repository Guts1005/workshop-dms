# Master Task Checklist (tasks/todo.md)

## Phase 1: Environment & Project Scaffold
- [ ] Install/Verify Flutter SDK & dependencies <!-- id: p1_01 -->
- [ ] Create base Flutter project structure <!-- id: p1_02 -->
- [ ] Configure `pubspec.yaml` with Drift, Camera, Supabase, Crypto, Record <!-- id: p1_03 -->

## Phase 2: Theme Engine & Flat Design System
- [ ] Implement `AppColors` token contract (Base #E4E2DD, Surface #D9D6D0, Inverse #1E1E1E) <!-- id: p2_01 -->
- [ ] Implement `SharpButton` (Zero border-radius, 48px hit area, pressed state) <!-- id: p2_02 -->
- [ ] Implement `SharpCard` & `SharpPanel` with 1px solid #1E1E1E borders <!-- id: p2_03 -->
- [ ] Implement `StatusChip` with icon + text label <!-- id: p2_04 -->
- [ ] Implement `SharpFocusRing` (3px outline with 2px offset) <!-- id: p2_05 -->

## Phase 3: Drift Database & Local Domain Layer
- [ ] Write Drift schema tables for Vehicles, Customers, JobCards, Photos, Invoices <!-- id: p3_01 -->
- [ ] Run Drift code generation for type-safe DAOs <!-- id: p3_02 -->
- [ ] Implement local file sandbox and SHA-256 hash generator <!-- id: p3_03 -->

## Phase 4: Bay Check-in Camera Engine
- [ ] Implement 45° angle wireframe overlay guides <!-- id: p4_01 -->
- [ ] Build 6 mandatory sequential check-in capture workflow <!-- id: p4_02 -->
- [ ] Implement Job Card check-in gate <!-- id: p4_03 -->

## Phase 5: Condition Map & Damage Annotation
- [ ] Build 4-view line art CustomPainter <!-- id: p5_01 -->
- [ ] Implement 48px polygon hit zones and #DB4A2B numbered pin drops <!-- id: p5_02 -->
- [ ] Build 6 vehicle silhouette icons and uppercase monospace wordmarks <!-- id: p5_03 -->

## Phase 6: Job Card Engine & Live Status Pipeline
- [ ] Build 5-stage status workflow manager <!-- id: p6_01 -->
- [ ] Build line item editor for Labour and Parts with voice notes <!-- id: p6_02 -->

## Phase 7: Spare Parts Inventory Management
- [ ] Implement Parts Catalog with SKU, cost vs. selling, and HSN codes <!-- id: p7_01 -->
- [ ] Implement stock deduction and low-inventory alerts <!-- id: p7_02 -->

## Phase 8: Automotive GST Invoicing & WhatsApp
- [ ] Build dual GST calculation engine (SAC 998729 @ 18%, HSN @ 18/28%) <!-- id: p8_01 -->
- [ ] Build high-density PDF invoice generator <!-- id: p8_02 -->
- [ ] Build WhatsApp wa.me direct URL template generator <!-- id: p8_03 -->

## Phase 9: Strict Payment Gate & Debtors Ledger
- [ ] Implement Payment Reconciliation modal (Cash, UPI, Card) <!-- id: p9_01 -->
- [ ] Implement delivery blocker and Credit Override ledger <!-- id: p9_02 -->

## Phase 10: Digital Health Passport & Service Reminders
- [ ] Build vehicle Health Passport screen with blurred plates & wear metrics <!-- id: p10_01 -->
- [ ] Build dual-trigger (Time + Odometer) reminder calculation engine <!-- id: p10_02 -->
- [ ] Build Service Reminders dashboard tab with 1-click WhatsApp buttons <!-- id: p10_03 -->

## Phase 11: Supabase & Cloudflare R2 Sync Engine
- [ ] Define Supabase PostgreSQL schema with RLS <!-- id: p11_01 -->
- [ ] Implement background Outbox sync worker <!-- id: p11_02 -->
