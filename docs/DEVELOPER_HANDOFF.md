# Workshop DMS developer handoff

**Status date:** 21 November 2026  
**Current state:** Active prototype with Supabase-backed workflows. All 17 repository migrations are applied to the configured project; the workshop-checkin bucket is private and its workshop-scoped Storage policies are present. A labeled synthetic QA application was created and advanced through intake to the condition report. Finding/photo save and sign-off still need a live retest. Six-photo camera capture, second-workshop isolation testing, and device camera/gallery testing remain. This is not yet a production release.

## What is implemented

- Flutter app shell with Home, Applications, and Vehicles navigation.
- Supabase email authentication, workshop setup, workshop-scoped records, and an empty setup state when configuration or data is missing.
- Customer/vehicle intake and application creation backed by Supabase. Retries reuse a request ID only while submitted details are unchanged; editing after a failed attempt starts a new request. Migration `202611200011_idempotent_application_intake.sql` enforces the key in the database and restricts job-card creation to the RPC.
- Application list and dashboard reads from workshop records.
- Bay check-in photo capture, private Storage uploads, and manager override records.
- Vehicle condition findings and sign-off, including optional private finding photos. Photos are stored in the `workshop-checkin` bucket. A finding retry reuses its record ID and content-addressed storage path; failed replacement uploads keep the previous photo reference intact.
- Mechanical inspection with brake, tyre, and battery readings, explicit not-applicable choices, odometer validation, and Supabase persistence. Application cards route to inspection after the signed condition report and to the estimate after inspection.
- Job card page with persisted line-item creation, estimate-sent state, and revision editing. WhatsApp launch requires customer consent; the customer response screen captures per-item approval, decline, or revision requests. A server RPC writes audit snapshots and advances only unanimous approval to work in progress. After an uncertain response, the app confirms the persisted decisions before reporting failure. Database grants and row policies prevent direct lifecycle changes or estimate edits after dispatch.
- Vehicle history/passport view and GST helpers exist. Reminder calculations use recorded odometer history only, but the reminders route and reminder persistence/dispatch are not complete.
- Seventeen SQL migrations define authentication/workshop, customer, vehicle, job-card, line-item, bay-photo, condition-report, access hardening, check-in photo-gate behavior, mechanical inspection records, estimate dispatch, audited customer responses, restricted estimate editing, work-progress history, quality sign-off, persisted GST invoices, payment ledger, audited delivery, inventory, idempotent application intake and condition signoff, restricted trigger-function access, and idempotent delivery retries. All are applied to the configured Supabase project.
- Work-in-progress page shows approved estimate scope and appends technician progress, parts-delay, and customer-update notes through an audited RPC. It does not change job lifecycle status; QC is a separate sign-off gate.
- QC screen captures completed-work confirmation, four vehicle checks, and road-test result. A failed check remains in service; only an audited pass advances to `QC_PASSED`.
- Invoice screen issues one immutable tax invoice per QC-passed job for a GST-registered supplier, snapshots the approved estimate and billing identities, allocates a per-workshop financial-year number, calculates paise totals in a database RPC, and generates a printable PDF. State codes determine the intra-state or inter-state tax split. Rates and place-of-supply classification need review by the workshop's tax adviser; unregistered bill-of-supply documents and IRN/e-invoice submission are not implemented. Invoice fields follow the [CBIC tax invoice rules](https://cbic-gst.gov.in/gst-invoice-rules.html).
- Payment and handover screen records append-only payments against an issued invoice, reconciles the balance, and allows delivery after full payment. Payment requests carry idempotency IDs to avoid duplicate entries after a lost response. Invoice and delivery screens confirm commits after a lost RPC response; the delivery RPC returns the original timestamp for a repeated request. A workshop owner can approve outstanding credit with a required recorded reason.
- Inventory screen keeps parts, supplier records, on-hand quantities, low-stock thresholds, and append-only stock movement history scoped to the workshop. Receipt and count adjustment flows are available from the home shortcut. Work-in-progress exposes issue/return controls limited to parts and quantities on the approved estimate.

## Remaining work, in priority order

### P0: Run authenticated end-to-end and isolation checks

- All seventeen migrations are applied to the configured project. Live schema inspection confirms the later workflow tables exist, RLS is enabled, `workshop-checkin` is private, and the bucket has authenticated select/insert/update/delete policies. Duplicate-safe intake, signoff, and delivery RPCs are installed.
- Configure a local `env.json` from `env.example.json`; never commit `env.json`, a service-role key, user credentials, or real customer data.
- Resume the existing synthetic QA job at condition report; save/reload the finding and photo, complete report sign-off, and verify the application advances. The intake, job-card creation, manager override, and route to condition report already worked in this QA run.
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
- Persist odometer/service history for reminders, implement the reminders route, and add consent-aware dispatch. The current calculation helper does not infer mileage without two valid service readings.

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

`lib/routing/app_router.dart` currently routes these pages to `PhasePlaceholderScreen`:

- `/reminders`

Debtor reporting is not complete. The passport route currently shows an internal vehicle history view; it is not a secured customer-facing QR product.

## Data and architecture notes

- Supabase is the live repository path for the current intake, applications, bay capture, and condition map modules.
- `env.json` is intentionally ignored. `env.example.json` contains placeholders and is safe to share.
- `supabase/migrations/` is the source of truth for the database schema in this repo. The configured Supabase project has all seventeen migrations applied as of 21 November 2026; check migration state before applying to another environment.
- Do not use real customer information in screenshots, fixtures, or test data.
- `tasks/plan.md` and the original task checklist were written before the current implementation and are historical requirements, not reliable completion tracking. Use this handoff and `BUILD_PROGRESS.md` for current status.

## Verification already completed

- Local Flutter verification after the condition retry, photo cleanup, intake gauge, phone layout, and vehicle history changes: all 149 tests passed, `flutter analyze` reported no issues, and the release web build succeeded. Focused suites cover lost invoice, payment, refresh, delivery, customer-response, condition-finding retries, uncertain photo cleanup, unobserved fuel levels, bay check-in at phone size, and vehicle-history formatting and decision labels.
- Bay check-in rendered without a `RenderFlex` overflow at a 390 x 844 phone viewport. The observed 183-pixel overflow was emitted while DevTools reported a 1 x 1-pixel app constraint; it was not reproduced at a usable mobile viewport. Physical-device and camera/gallery checks remain pending.
- Live Supabase inspection confirmed all seventeen migrations, all workflow tables with RLS enabled, the private photo bucket, and workshop-scoped Storage policies. The trigger-only approval guard cannot be called through RPC; the authenticated signoff RPC remains callable and anon cannot call it. Supabase's remaining security warnings are for intended authenticated, input-validating RPCs; leaked-password protection remains disabled in project Auth settings.
- Live synthetic owner-flow QA created a labeled test job card, reached photo check-in, recorded a labeled QA manager override, and opened the condition report. Selecting a labeled synthetic image showed its preview and uploaded successfully, but saving the finding failed because the client sent a timestamp-sized ID to a PostgreSQL 32-bit integer column. Supabase Storage logs confirmed the uploaded object was removed after the row failed; no finding/photo remains saved. The ID generator is now constrained to positive 32-bit values, with retry recovery for uncertain writes. A live retry and condition sign-off remain unverified because the browser connection dropped. The synthetic QA job and override remain in the project; they are test data, not real customer/vehicle records.
- Remaining authenticated QA: retry the synthetic condition finding/photo, verify private photo retrieval, complete condition sign-off, verify second-workshop isolation, and test camera/gallery permissions on a physical device.
- Photo replacement cleanup now removes a newly uploaded object only when a follow-up database read confirms the failed write did not reference it. If the reference check itself fails, the private upload is retained for safety; the unreferenced-object cleanup path remains a manual/live verification item.

## First recommended developer session

1. Read `README.md`, this handoff, `supabase/migrations/`, and the intake, capture, condition, and mechanical-inspection repositories.
2. Set up Flutter and the configured Supabase project using `README.md`; migrations are already applied to that project.
3. Run the full suite and `flutter analyze`.
4. Walk the P0 real-account flow and fix the first persistence, RLS, or media issue found.
5. Verify per-item customer responses, then continue through QC, invoice, and payment gates.
