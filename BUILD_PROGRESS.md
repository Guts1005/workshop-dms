# Build progress

**Updated:** 21 November 2026

Workshop DMS is an active prototype. The configured Supabase project currently exposes the original intake, vehicle, job-card, photo, and condition-report tables, but a read-only schema probe found the newer inspection, approval, work-progress, QC, billing, payment, delivery, and inventory tables missing. Reminders remain incomplete, and the full live-project flow still needs verification.

## Current snapshot

| Area | Status | Notes |
| --- | --- | --- |
| App shell and authentication | Implemented | Supabase setup, sign-in, and workshop setup screens exist. |
| Intake and applications | Implemented; live QA pending | Reads and RPC-backed writes are Supabase-backed. Retries reuse a request ID to avoid duplicate applications; migration `202611200011` must be applied. Application cards route to the next incomplete task. |
| Bay check-in | Implemented; migration/device QA pending | Six-photo gate is enforced in the client and in migration `202611200001`; manager overrides require a workshop owner. Private Storage upload and retake-safe replacement are present. Apply the migration to the target project before live use. |
| Condition report | Implemented; live QA pending | Findings, optional photos, review areas, and sign-off exist. |
| Job card / estimate | Partial | Line items persist; sent estimates lock. Per-item approval, decline, revision response, audit history, and unanimous-approval transition are implemented. Vehicle passport history and live Supabase verification remain. |
| Mechanical inspection | Implemented; migration/live QA pending | Records brake, tyre, and battery readings or explicit not-applicable choices; validates odometer and persists completion. Application cards route to inspection before the estimate. Apply migration `202611200002` before live use. |
| Customer approvals / WhatsApp | Implemented; migration/live QA pending | WhatsApp launch requires recorded consent; responses are captured per item and recorded through an audited RPC. Migration `202611200005` locks status and approval fields behind validated database functions. Apply migrations `202611200004` and `202611200005` before live use. Delivery receipts are not tracked. |
| Work in progress | Initial workflow implemented; migration/live QA pending | Shows approved estimate scope and an immutable, audited log for technician notes, parts delays, and customer updates. Migration `202611200006` adds the update table and RPC. QC/road test is still the next workflow gate. |
| Inventory | Initial workflow implemented; migration/live QA pending | Workshop-scoped parts, suppliers, low-stock thresholds, stock receipt and adjustment history are implemented. Approved-job issue/return RPCs enforce estimate quantity limits. Apply migration `202611200010` before live use. |
| QC / road test | Initial workflow implemented; migration/live QA pending | Requires repair-complete confirmation, four explicit checks, and a road-test result or reason. Failed QC keeps work in progress; audited pass moves to `QC_PASSED`. Apply migration `202611200007` before live use. |
| GST invoice | Initial workflow implemented; migration/live QA pending | For GST-registered suppliers, uses explicitly entered approved-estimate rates, creates an immutable snapshot and FY serial in a database RPC, computes state-based tax split, and prints a PDF. Bill-of-supply and IRN submission are not implemented; rate and place-of-supply classification need accountant verification. Apply migration `202611200008` before live use. |
| Payment / delivery | Initial workflow implemented; migration/live QA pending | Payment ledger, balance checks, owner-only audited credit override, and server-enforced handover are implemented. Apply migration `202611200009` before live use. |
| Vehicle passport / reminders | Partial | Internal history exists. Reminder mileage projections require two valid readings and customer messages avoid unsupported repair suggestions; reminders route, persistence, and dispatch remain incomplete. Public QR/passport is also incomplete. |
| Offline-first sync | Not implemented | Current outbox service is in-memory and is not wired as a durable background worker. |

## Next work

1. Apply and verify all fourteen migrations against the target Supabase project. A read-only API probe on 21 November found the original customer, vehicle, job-card, check-in-photo, and condition-report tables, while tables from later workflow migrations returned 404. RLS, auth, RPC behavior, and Storage policies remain unverified.
2. Add customer decision history to vehicle history and connect inventory issue/return controls to active work.
3. Complete passport and service reminders, then durable offline sync.
4. Add golden tests and finish platform, security, accessibility, and release QA. GitHub Actions now runs formatting, analysis, tests, and a web release build for `master` pushes and pull requests.

See [docs/DEVELOPER_HANDOFF.md](docs/DEVELOPER_HANDOFF.md) for detailed priorities, architecture notes, setup, and verification limits. The older `tasks/` documents are historical specifications and do not represent current completion status.
