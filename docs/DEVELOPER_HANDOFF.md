# Workshop DMS developer handoff

**Status date:** 21 November 2026  
**Current state:** Active prototype with Supabase-backed intake and condition-report code. A read-only probe found the configured live project's original intake/report tables, but later workflow tables are missing. This is not yet a complete workshop management system or a production release.

## What is implemented

- Flutter app shell with Home, Applications, and Vehicles navigation.
- Supabase email authentication, workshop setup, workshop-scoped records, and an empty setup state when configuration or data is missing.
- Customer/vehicle intake and application creation backed by Supabase. Intake retries reuse a request ID; migration `202611200011_idempotent_application_intake.sql` enforces the key in the database and restricts job-card creation to the RPC.
- Application list and dashboard reads from workshop records.
- Bay check-in photo capture, private Storage uploads, and manager override records.
- Vehicle condition findings and sign-off, including optional private finding photos. Photos are stored in the `workshop-checkin` bucket.
- Mechanical inspection with brake, tyre, and battery readings, explicit not-applicable choices, odometer validation, and Supabase persistence. Application cards route to inspection after the signed condition report and to the estimate after inspection.
- Job card page with persisted line-item creation, estimate-sent state, and revision editing. WhatsApp launch requires customer consent; the customer response screen captures per-item approval, decline, or revision requests. A server RPC writes audit snapshots and advances only unanimous approval to work in progress. Database grants and row policies prevent direct lifecycle changes or estimate edits after dispatch.
- Vehicle history/passport view and GST helpers exist. Reminder calculations use recorded odometer history only, but the reminders route and reminder persistence/dispatch are not complete.
- Fourteen SQL migrations in this repository define authentication/workshop, customer, vehicle, job-card, line-item, bay-photo, condition-report, access hardening, check-in photo-gate behavior, mechanical inspection records, estimate dispatch, audited customer responses, restricted estimate editing, work-progress history, quality sign-off, persisted GST invoices, payment ledger, audited delivery, inventory, and idempotent application intake. The target project's confirmed schema gaps are listed under P0; other migration/RPC state remains unverified.
- Work-in-progress page shows approved estimate scope and appends technician progress, parts-delay, and customer-update notes through an audited RPC. It does not change job lifecycle status; QC is a separate sign-off gate.
- QC screen captures completed-work confirmation, four vehicle checks, and road-test result. A failed check remains in service; only an audited pass advances to `QC_PASSED`.
- Invoice screen issues one immutable tax invoice per QC-passed job for a GST-registered supplier, snapshots the approved estimate and billing identities, allocates a per-workshop financial-year number, calculates paise totals in a database RPC, and generates a printable PDF. State codes determine the intra-state or inter-state tax split. Rates and place-of-supply classification need review by the workshop's tax adviser; unregistered bill-of-supply documents and IRN/e-invoice submission are not implemented. Invoice fields follow the [CBIC tax invoice rules](https://cbic-gst.gov.in/gst-invoice-rules.html).
- Payment and handover screen records append-only payments against an issued invoice, reconciles the balance, and allows delivery after full payment. Payment requests carry idempotency IDs to avoid duplicate entries after a lost response. A workshop owner can approve outstanding credit with a required recorded reason. Both operations are validated in database RPCs; apply migration `202611200009_payment_delivery.sql` before live use.
- Inventory screen keeps parts, supplier records, on-hand quantities, low-stock thresholds, and append-only stock movement history scoped to the workshop. Receipt and count adjustment flows are available from the home shortcut. Work-in-progress exposes issue/return controls limited to parts and quantities on the approved estimate. Apply migration `202611200010_inventory.sql` before live use.

## Remaining work, in priority order

### P0: Apply and verify the real application path against the target Supabase project

- Apply all fourteen migrations to the intended project and confirm that Storage bucket `workshop-checkin` is private with the expected policies. A read-only API probe on 21 November returned the original `customers`, `vehicles`, `job_cards`, `bay_photos`, `condition_reports`, `condition_findings`, `condition_review_areas`, and `manager_overrides` tables, but returned 404 for `mechanical_inspections`, `job_item_approval_events`, `job_work_updates`, `job_quality_checks`, invoice, payment, delivery, and inventory tables. The `job_cards.intake_request_id` column probe returned 400. The target schema is behind this repository; the `202611200001` check-in gate and the `202611200003` dispatch columns/RPC state were not established.
- Configure a local `env.json` from `env.example.json`; never commit `env.json`, a service-role key, user credentials, or real customer data.
- Exercise signup/sign-in, workshop creation, customer/vehicle creation, application creation, six mandatory check-in photos, optional photo selection, finding save/reload, report sign-off, and application progress from a clean account.
- Verify upload, signed-photo viewing, deletion cleanup, email-confirmation settings, and RLS behavior for a second workshop account.
- Resolve any migration/client mismatches found during that exercise. The endpoint probe did not retrieve customer rows and does not verify authenticated RLS, RPC execution, the Storage bucket, or a complete application flow.

### P1: Finish the core service workflow

- Finish job-card and estimate lifecycle, including editing/removing line items, robust loading/error states, customer approval/decline persistence, and transitions to work in progress.
- Add declined and revision-request history to vehicle history so prior customer decisions inform future recommendations. WhatsApp launch is consent-gated, but delivery/read receipts are not tracked.
- Verify payment reconciliation, outstanding balances, owner credit override, and server-enforced delivery after migration application.
- Add bill-of-supply support for suppliers who should not issue a GST tax invoice, plus GSTN/IRP e-invoice integration where applicable.

### P1: Build inventory, billing, and delivery records

- Verify inventory migrations, workshop isolation, stock receipts, adjustments, estimate-limited issue/return, and low-stock reporting after applying the migration.
- Connect validated part issue/return functions to the technician work screen and confirm deduction/reversal against approved quantities.
- Connect GST calculations to persisted invoice line items; verify effective rates, CGST/SGST versus IGST, rounding in paise, PDF output, and invoice numbering with an accountant.
- Add debtor reporting and credit follow-up for owner-approved outstanding balances.

### P2: Complete vehicle history and reminders

- Persist mechanical measurements and service events to the vehicle history/passport.
- Complete customer-facing passport/QR access with plate privacy and explicit public-data rules.
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
- `supabase/migrations/` is the source of truth for the database schema in this repo. Apply with the Supabase CLI only after linking the intended project and reviewing the target.
- Do not use real customer information in screenshots, fixtures, or test data.
- `tasks/plan.md` and the original task checklist were written before the current implementation and are historical requirements, not reliable completion tracking. Use this handoff and `BUILD_PROGRESS.md` for current status.

## Verification already completed

- Local Flutter verification: all 132 tests passed, `flutter analyze` completed with no issues, and the web release build succeeded after the intake idempotency fix. GitHub Actions run [#1](https://github.com/Guts1005/workshop-dms/actions/runs/44792984354) passed formatting, analysis, tests, and the web release build for the preceding commit.
- `git diff --check` completed cleanly after the latest changes.
- The configured project's REST endpoint was reachable with its publishable key. The environment has no Supabase MCP or CLI, no `psql`, no Supabase access token, and no running Docker daemon, so migrations could not be applied. Authenticated RLS, RPC behavior, live Storage policies, and physical-device camera flow remain unverified. Apply all fourteen migrations before exercising intake, inspections, customer responses, work progress, QC, invoice, payment, delivery, and inventory against the live project.

## First recommended developer session

1. Read `README.md`, this handoff, `supabase/migrations/`, and the intake, capture, condition, and mechanical-inspection repositories.
2. Set up Flutter and the target Supabase project using `README.md`; verify migrations before running the app.
3. Run the full suite and `flutter analyze`; record baseline failures before changing implementation.
4. Walk the P0 real-account flow and fix the first persistence, RLS, or media issue found.
5. Verify per-item customer responses, then continue through QC, invoice, and payment gates.
