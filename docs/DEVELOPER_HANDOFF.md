# Workshop DMS developer handoff

**Status date:** 20 November 2026  
**Current state:** Active prototype with a real Supabase-backed intake and inspection path. This is not yet a complete workshop management system or a production release.

## What is implemented

- Flutter app shell with Home, Applications, and Vehicles navigation.
- Supabase email authentication, workshop setup, workshop-scoped records, and an empty setup state when configuration or data is missing.
- Customer/vehicle intake and application creation backed by Supabase.
- Application list and dashboard reads from workshop records.
- Bay check-in photo capture, private Storage uploads, and manager override records.
- Vehicle condition findings and sign-off, including optional private finding photos. Photos are stored in the `workshop-checkin` bucket.
- Mechanical inspection with brake, tyre, and battery readings, explicit not-applicable choices, odometer validation, and Supabase persistence. Application cards route to inspection after the signed condition report and to the estimate after inspection.
- Job card page with persisted line-item creation, estimate-sent state, and revision editing. WhatsApp launch requires customer consent; the customer response screen captures per-item approval, decline, or revision requests. A server RPC writes audit snapshots and advances only unanimous approval to work in progress. Database grants and row policies prevent direct lifecycle changes or estimate edits after dispatch.
- Vehicle history/passport view and GST/reminder calculation helpers exist, but the linked routes and persistence are not complete.
- Eleven SQL migrations define authentication/workshop, customer, vehicle, job-card, line-item, bay-photo, condition-report, access hardening, check-in photo-gate behavior, mechanical inspection records, estimate dispatch, audited customer responses, restricted estimate editing, work-progress history, quality sign-off, and persisted GST invoices. Migrations `202611200001` through `202611200008` are local and have not been applied to Supabase.
- Work-in-progress page shows approved estimate scope and appends technician progress, parts-delay, and customer-update notes through an audited RPC. It does not change job lifecycle status; QC is a separate sign-off gate.
- QC screen captures completed-work confirmation, four vehicle checks, and road-test result. A failed check remains in service; only an audited pass advances to `QC_PASSED`.
- Invoice screen issues one immutable tax invoice per QC-passed job for a GST-registered supplier, snapshots the approved estimate and billing identities, allocates a per-workshop financial-year number, calculates paise totals in a database RPC, and generates a printable PDF. State codes determine the intra-state or inter-state tax split. Rates and place-of-supply classification need review by the workshop's tax adviser; unregistered bill-of-supply documents and IRN/e-invoice submission are not implemented. Invoice fields follow the [CBIC tax invoice rules](https://cbic-gst.gov.in/gst-invoice-rules.html).

## Remaining work, in priority order

### P0: Apply and verify the real application path against the target Supabase project

- Apply all eleven migrations to the intended project and confirm that Storage bucket `workshop-checkin` is private with the expected policies. The eight latest migrations add the photo gate, mechanical inspection records, estimate-dispatch state, audited customer responses, restricted estimate updates, work-progress history, quality sign-off, and GST invoices.
- Configure a local `env.json` from `env.example.json`; never commit `env.json`, a service-role key, user credentials, or real customer data.
- Exercise signup/sign-in, workshop creation, customer/vehicle creation, application creation, six mandatory check-in photos, optional photo selection, finding save/reload, report sign-off, and application progress from a clean account.
- Verify upload, signed-photo viewing, deletion cleanup, email-confirmation settings, and RLS behavior for a second workshop account.
- Resolve any migration/client mismatches found during that exercise. The live project's migration state was not checked for this handoff.

### P1: Finish the core service workflow

- Finish job-card and estimate lifecycle, including editing/removing line items, robust loading/error states, customer approval/decline persistence, and transitions to work in progress.
- Add declined and revision-request history to vehicle history so prior customer decisions inform future recommendations. WhatsApp launch is consent-gated, but delivery/read receipts are not tracked.
- Implement payment reconciliation, outstanding balances, and a server-enforced delivery gate after invoice issue.
- Add bill-of-supply support for suppliers who should not issue a GST tax invoice, plus GSTN/IRP e-invoice integration where applicable.

### P1: Build inventory, billing, and delivery records

- Add database migrations and workshop-scoped repositories for parts and inventory. Stock and supplier records are not present in the current migration set.
- Implement stock deduction/reversal and low-stock reporting.
- Connect GST calculations to persisted invoice line items; verify effective rates, CGST/SGST versus IGST, rounding in paise, PDF output, and invoice numbering with an accountant.
- Implement payment reconciliation, outstanding balances/debtors, and a server-enforced delivery gate with an audited credit override.

### P2: Complete vehicle history and reminders

- Persist mechanical measurements and service events to the vehicle history/passport.
- Complete customer-facing passport/QR access with plate privacy and explicit public-data rules.
- Connect reminder calculations to real odometer/service history and implement the reminders route and consent-aware dispatch.

### P1: Replace the demo outbox with reliable offline sync

- `OutboxSyncService` currently holds its queue in memory and its `RemoteSyncClient` is an interface used by tests; it is not a durable background sync worker.
- Persist pending mutations locally, add idempotent Supabase mutation handling, retries/backoff, connectivity recovery, conflict behavior, and observable sync status.
- Define which flows must work offline, store captured media safely, and verify restart/offline/reconnect behavior on target hardware.

### P1: Release quality and operational readiness

- Expand coverage for data repositories, Supabase/RLS integration, upload failures, and all workflow states. The current local suite passes, but it does not exercise a live Supabase project.
- Add CI for formatting, analysis, tests, and web build; add golden tests and accessibility checks for the high-use screens.
- Manually validate responsive web, Windows, Android, and iOS behavior, especially camera/gallery permissions, upload failure recovery, and authentication return paths.
- Set up deployment, environment configuration, backups, monitoring, data retention, and a privacy policy before real customer records are used.

## Routes that are still placeholders

`lib/routing/app_router.dart` currently routes these pages to `PhasePlaceholderScreen`:

- `/payment-gate`
- `/reminders`

Inventory, technician work-in-progress, and debtors are not complete modules. The passport route currently shows an internal vehicle history view; it is not a secured customer-facing QR product.

## Data and architecture notes

- Supabase is the live repository path for the current intake, applications, bay capture, and condition map modules.
- `env.json` is intentionally ignored. `env.example.json` contains placeholders and is safe to share.
- `supabase/migrations/` is the source of truth for the database schema in this repo. Apply with the Supabase CLI only after linking the intended project and reviewing the target.
- Do not use real customer information in screenshots, fixtures, or test data.
- `tasks/plan.md` and the original task checklist were written before the current implementation and are historical requirements, not reliable completion tracking. Use this handoff and `BUILD_PROGRESS.md` for current status.

## Verification already completed

- Local Flutter verification: all 111 tests passed and `flutter analyze` completed with no issues after invoice changes. The release build is being rerun.
- `git diff --check` completed cleanly after the latest changes.
- Live Supabase migration state, live Storage policies, the newer workflow migrations, and physical-device camera flow were not verified. This environment has no Supabase CLI/MCP, `psql`, or running Docker daemon, so database execution remains the key verification gap. Apply migrations four through eleven before exercising check-in, inspection, estimate dispatch, customer responses, technician updates, QC, and invoice issue against the live project.

## First recommended developer session

1. Read `README.md`, this handoff, `supabase/migrations/`, and the intake, capture, condition, and mechanical-inspection repositories.
2. Set up Flutter and the target Supabase project using `README.md`; verify migrations before running the app.
3. Run the full suite and `flutter analyze`; record baseline failures before changing implementation.
4. Walk the P0 real-account flow and fix the first persistence, RLS, or media issue found.
5. Verify per-item customer responses, then continue through QC, invoice, and payment gates.
