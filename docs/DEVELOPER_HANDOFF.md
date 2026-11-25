# Workshop DMS developer handoff

**Status date:** 25 November 2026

**Current state:** Active prototype with Supabase-backed workflows. The 17 migrations present at the last live inspection are applied; reminder migration `202611210002_service_reminder_settings.sql` was added afterward and remains unapplied/unverified. No Supabase MCP connector or CLI is available in this session, so I could not resume the live QA record or apply that migration. The workshop-checkin bucket is private with workshop-scoped Storage policies. A labeled synthetic QA application reached the condition report; finding/photo save and sign-off need a live retest. Six-photo camera capture, second-workshop isolation, and device camera/gallery testing remain. This is not yet a production release.

## What is implemented

- Flutter app shell with Home, Jobs, Vehicles, and Reminders navigation.
- Supabase email authentication, workshop setup, workshop-scoped records, and an empty setup state when configuration or data is missing.
- Customer/vehicle intake and application creation backed by Supabase. Retries reuse a request ID only while submitted details are unchanged; editing after a failed attempt starts a new request. Migration `202611200011_idempotent_application_intake.sql` enforces the key in the database and restricts job-card creation to the RPC.
- Application list and dashboard reads from workshop records.
- Bay check-in photo capture, private Storage uploads, and manager override records.
- Vehicle condition findings and sign-off, including optional private finding photos. Photos are stored in the `workshop-checkin` bucket. A finding retry reuses its record ID and content-addressed storage path; failed replacement uploads keep the previous photo reference intact. Signed photo URLs refresh before expiry, and failed thumbnail or full-size loads offer a retry.
- Mechanical inspection with brake, tyre, and battery readings, explicit not-applicable choices, odometer validation, and Supabase persistence. Application cards route to inspection after the signed condition report and to the estimate after inspection.
- Job card page with persisted line-item creation, estimate-sent state, and revision editing. WhatsApp launch requires customer consent; the customer response screen captures per-item approval, decline, or revision requests. A server RPC writes audit snapshots and advances only unanimous approval to work in progress. After an uncertain response, the app confirms the persisted decisions before reporting failure. Database grants and row policies prevent direct lifecycle changes or estimate edits after dispatch.
- Vehicle history/passport view and GST helpers exist. The Reminders route is implemented with recorded delivery history, manager-configured intervals, heads-up timing, and a live WhatsApp-consent recheck. The new settings migration still needs to be applied to the configured Supabase project before this route can load/save settings there.
- The 17 previously applied migrations define authentication/workshop, customer, vehicle, job-card, line-item, bay-photo, condition-report, access hardening, check-in photo-gate behavior, mechanical inspection records, estimate dispatch, audited customer responses, restricted estimate editing, work-progress history, quality sign-off, persisted GST invoices, payment ledger, audited delivery, inventory, idempotent application intake and condition signoff, restricted trigger-function access, and idempotent delivery retries. The newer reminder settings migration is not yet confirmed applied.
- Work-in-progress page shows approved estimate scope and appends technician progress, parts-delay, and customer-update notes through an audited RPC. It does not change job lifecycle status; QC is a separate sign-off gate.
- QC screen captures completed-work confirmation, four vehicle checks, and road-test result. A failed check remains in service; only an audited pass advances to `QC_PASSED`.
- Invoice screen issues one immutable tax invoice per QC-passed job for a GST-registered supplier, snapshots the approved estimate and billing identities, allocates a per-workshop financial-year number, calculates paise totals in a database RPC, and generates a printable PDF. State codes determine the intra-state or inter-state tax split. Rates and place-of-supply classification need review by the workshop's tax adviser; unregistered bill-of-supply documents and IRN/e-invoice submission are not implemented. Invoice fields follow the [CBIC tax invoice rules](https://cbic-gst.gov.in/gst-invoice-rules.html).
- Payment and handover screen records append-only payments against an issued invoice, reconciles the balance, and allows delivery after full payment. Payment requests carry idempotency IDs to avoid duplicate entries after a lost response. Invoice and delivery screens confirm commits after a lost RPC response; the delivery RPC returns the original timestamp for a repeated request. A workshop owner can approve outstanding credit with a required recorded reason.
- Inventory screen keeps parts, supplier records, on-hand quantities, low-stock thresholds, and append-only stock movement history scoped to the workshop. Receipt and count adjustment flows are available from the home shortcut. Work-in-progress exposes issue/return controls limited to parts and quantities on the approved estimate.

## Remaining work, in priority order

### P0: Run authenticated end-to-end and isolation checks

- The 17 earlier migrations were confirmed applied to the configured project. Live schema inspection confirmed the later workflow tables exist, RLS is enabled, `workshop-checkin` is private, and the bucket has authenticated select/insert/update/delete policies. Duplicate-safe intake, signoff, and delivery RPCs are installed.
- Configure a local `env.json` from `env.example.json`; never commit `env.json`, a service-role key, user credentials, or real customer data.
- The labeled MG MOTOR QA TEST SUV job has advanced through a saved condition report and mechanical inspection to a draft estimate. The finding/photo reference and private image retrieval were not inspected, so verify those before considering condition-media QA complete. Do not send the draft estimate to the synthetic customer.
- New live QA record `RJ14QZ0026` (`a02d2750-724d-444c-8df2-73d4d136bd9f`) was created with synthetic details and advanced through condition report, mechanical inspection, and estimate draft. The condition report has a `Surface Scuff / Minor` finding with a `SYNTHETIC QA ONLY` note, four other exterior areas marked no findings, and a manager override because no physical vehicle photos were available. The review checkbox was confirmed for this synthetic record. The mechanical inspection saved synthetic readings and a synthetic-only observation. The estimate has clearly labeled synthetic labour and part lines and remains unsent. The test reused phone `9999999999`, which matched the earlier synthetic `QA Test Owner` customer. The intake upsert changed that shared QA profile to `Synthetic QA Owner` and messaging consent false. Restore the original QA name/consent when Supabase admin access is available; no direct customer-edit screen or Supabase MCP/CLI is available in this session. Do not treat this placeholder contact or its condition result as real customer/vehicle data.
- Exercise signup/sign-in and workshop creation from a clean account, then capture the six mandatory check-in photos and test application progress.
- Verify upload, signed-photo viewing, deletion cleanup, email-confirmation settings, and RLS behavior for a second workshop account. Do not use the synthetic QA run as proof of full authentication, storage retrieval, or isolation behavior.
- Resolve any client/RPC mismatches found in that run. The synthetic QA job is explicitly labeled and has not been deleted; do not use it as real workshop/customer data.

### P1: Finish the core service workflow

- Verify the implemented estimate add/edit/remove, loading/error, sent-lock, per-item customer decision, and work-start lifecycle in an authenticated end-to-end run. The UI and audited response RPC are present; live Supabase verification remains.
- Vehicle history now shows audited declined and revision-request decisions alongside prior estimate item descriptions and customer notes. Verify the joined Supabase history in an authenticated run. WhatsApp launch is consent-gated, but delivery/read receipts are not tracked.
- Verify payment reconciliation, outstanding balances, owner credit override, and server-enforced delivery in a signed-in test account.
- Add bill-of-supply support for suppliers who should not issue a GST tax invoice, plus GSTN/IRP e-invoice integration where applicable.

### P1: Build inventory, billing, and delivery records

- Verify workshop isolation, stock receipts, adjustments, estimate-limited issue/return, and low-stock reporting in a signed-in test account.
- Connect validated part issue/return functions to the technician work screen and confirm deduction/reversal against approved quantities.
- Connect GST calculations to persisted invoice line items; verify effective rates, CGST/SGST versus IGST, rounding in paise, PDF output, and invoice numbering with an accountant.
- Add debtor reporting and credit follow-up for owner-approved outstanding balances.

### P2: Complete vehicle history and reminders

- The internal vehicle history now expands saved mechanical readings, customer estimate decisions, not-applicable values, and inspection notes. Verify the joined Supabase history with a real saved inspection; then complete customer-facing passport/QR access with plate privacy and explicit public-data rules.
- Apply `202611210002_service_reminder_settings.sql` to the configured Supabase project, then verify settings persistence and completed-delivery queries in an authenticated session. Reminders derive from recorded visits and never infer mileage without two valid readings; WhatsApp opening rechecks current consent.

### P1: Replace the demo outbox with reliable offline sync

- `OutboxSyncService` currently holds its queue in memory and its `RemoteSyncClient` is an interface used by tests; it is not a durable background sync worker.
- Persist pending mutations locally, add idempotent Supabase mutation handling, retries/backoff, connectivity recovery, conflict behavior, and observable sync status.
- Define which flows must work offline, store captured media safely, and verify restart/offline/reconnect behavior on target hardware.

### P1: Release quality and operational readiness

- Expand coverage for data repositories, Supabase/RLS integration, upload failures, and all workflow states. The current local suite passes, but it does not exercise a live Supabase project.
- Add golden tests and accessibility checks for the high-use screens. GitHub Actions now runs formatting, analysis, tests, and a web release build on pushes and pull requests to `master`.
- Manually validate responsive web, Windows, Android, and iOS behavior, especially camera/gallery permissions, upload failure recovery, and authentication return paths.
- Set up deployment, environment configuration, backups, monitoring, data retention, and a privacy policy before real customer records are used.

## Routes that are still placeholders

`lib/routing/app_router.dart` no longer routes `/reminders` to `PhasePlaceholderScreen`. Other workflow routes have implemented screens; a customer-facing public vehicle passport/QR and debtor reporting are not complete product features.

Debtor reporting is not complete. The passport route currently shows an internal vehicle history view; it is not a secured customer-facing QR product.

## Data and architecture notes

- Supabase is the live repository path for the current intake, applications, bay capture, and condition map modules.
- `env.json` is intentionally ignored. `env.example.json` contains placeholders and is safe to share.
- `supabase/migrations/` is the source of truth for the database schema in this repo. The configured project had all seventeen earlier migrations applied as of 21 November 2026; migration `202611210002_service_reminder_settings.sql` was added afterward and is not yet confirmed applied. Check migration state before applying to any environment.
- Do not use real customer information in screenshots, fixtures, or test data.
- `tasks/plan.md` and the original task checklist were written before the current implementation and are historical requirements, not reliable completion tracking. Use this handoff and `BUILD_PROGRESS.md` for current status.
- The owner-provided `ai_agent_reels_complete_compendium.md` was reviewed as optional reference material. Useful project-fit ideas: add deterministic regression tests for workflow edge cases, keep visual hierarchy readable and motion restrained, and measure before optimizing. Its named libraries/tools and popularity/performance claims are not validated project requirements; check current official documentation before adopting a dependency, and do not impose its exact-opposite-hue palette rule on the existing design system.

## Verification already completed

- Local Flutter verification after intake, condition-report integrity, inspection load-recovery, estimate-dialog, and stock-movement dialog fixes: all 170 tests passed, `flutter analyze` reported no issues, and `flutter build web --release --dart-define-from-file=env.json` succeeded. Coverage includes intake match clearing and consent reset after changing a matched customer phone, plain desktop intake section labels, intake-to-check-in-to-condition routing, reminder interval and consent behavior, sign-off checks proving notes/photo paths change the checksum while finding order does not, mechanical-inspection load failure/retry, estimate-dialog and stock-movement dialog save/cancel lifecycle, stock quantity limits, plus earlier lost-invoice, payment, delivery, photo retry, phone-layout, and vehicle-history cases.
- GitHub Actions run [44819644659](https://github.com/Guts1005/workshop-dms/actions/runs/44819644659) passed for commit `e409005`.
- Bay check-in rendered without a `RenderFlex` overflow at a 390 x 844 phone viewport. The observed 183-pixel overflow was emitted while DevTools reported a 1 x 1-pixel app constraint; it was not reproduced at a usable mobile viewport. Physical-device and camera/gallery checks remain pending.
- Live Supabase inspection confirmed all seventeen migrations, all workflow tables with RLS enabled, the private photo bucket, and workshop-scoped Storage policies. The trigger-only approval guard cannot be called through RPC; the authenticated signoff RPC remains callable and anon cannot call it. Supabase's remaining security warnings are for intended authenticated, input-validating RPCs; leaked-password protection remains disabled in project Auth settings.
- An earlier synthetic owner-flow QA attempt created a labeled test job card, reached photo check-in, recorded a labeled QA manager override, and opened the condition report. A selected synthetic image previewed and uploaded, but that attempt's finding save failed because the client sent a timestamp-sized ID to a PostgreSQL 32-bit integer column; Storage logs showed the failed object's cleanup. The ID generator is now constrained to positive 32-bit values, with retry recovery for uncertain writes. The current `RJ14QA2026` record is confirmed past condition sign-off, but its finding/photo references were not inspected during this turn. Keep these clearly labeled records as QA data; they are not real customer/vehicle records.
- 25 November 2026 live QA: the labeled `RJ14QA2026` / `MG MOTOR QA TEST SUV` record loaded the mechanical-inspection form. Synthetic readings (odometer 35,025 km, front/rear pads 8.5/7.2 mm, tread 6.0 mm, battery 12.6 V and 520 A) and inspector `QA Workshop Owner` saved successfully, advancing to the job estimate. A synthetic labour line at ₹500/18% GST saved; editing it to ₹600 recalculated GST to ₹108 (₹54 CGST + ₹54 SGST), and its ₹708 total survived a hard reload and job reopen. A synthetic ₹100 part line then produced the expected ₹126 total GST and ₹826 estimate total. Both synthetic estimate lines were removed afterward, restoring the original empty draft; the empty estimate cannot be marked sent. The app requires confirmation that an estimate was actually shared, and that confirmation was canceled, so no customer message was sent and the draft remains unsent. This did not test the inspection values by reloading the inspection screen, camera/gallery capture, customer response, or downstream job lifecycle.
- 25 November 2026 live QA: the labeled `RJ14QZ0026` / `MARUTI SUZUKI Swift VXI (QA TEST)` record saved a synthetic mechanical inspection (odometer 42,015 km, front/rear pads 10/8 mm, tread 5 mm, battery 12.6 V and 480 A) with inspector and observation explicitly labeled synthetic. It advanced to estimate. Synthetic labour of INR 500 and a synthetic part of INR 100 at 18% GST were saved; the page showed INR 108 total GST and INR 708 total. The draft remains unsent and the app preview was left open on it. The condition finding photo picker now launches gallery/camera directly from the source tap, avoiding the extra awaited source sheet that can break browser file-picker activation. A widget regression test verifies both sources reach the picker and cancellation restores the button. The IAB browser file chooser could not be verified in this run, so confirm on a normal browser or physical device before closing photo QA. No real photo was uploaded and no customer communication was sent.
- Remaining authenticated QA: retry the synthetic condition finding/photo, verify private photo retrieval, complete condition sign-off, verify second-workshop isolation, and test camera/gallery permissions on a physical device.
- Photo replacement cleanup now removes a newly uploaded object only when a follow-up database read confirms the failed write did not reference it. If the reference check itself fails, the private upload is retained for safety; the unreferenced-object cleanup path remains a manual/live verification item.
- Reminder unit and widget tests cover recorded-visit calculations, interval configuration, updated UI, current-consent checks, and India phone formatting. Supabase integration tests remain pending until the new migration is applied and an authenticated session is available.

## First recommended developer session

1. Read `README.md`, this handoff, `supabase/migrations/`, and the intake, capture, condition, and mechanical-inspection repositories.
2. Set up Flutter and the configured Supabase project using `README.md`; confirm migration state and apply `202611210002_service_reminder_settings.sql` before testing reminders.
3. Run the full suite and `flutter analyze`.
4. Walk the P0 real-account flow and fix the first persistence, RLS, or media issue found.
5. Verify per-item customer responses, then continue through QC, invoice, and payment gates.
