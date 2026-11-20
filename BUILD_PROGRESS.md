# Build progress

**Updated:** 21 November 2026

Workshop DMS is an active prototype. All 17 repository migrations are now applied to the configured Supabase project. A synthetic QA application was created and advanced to the condition report; the first finding save exposed an ID-range bug that is now fixed locally. Live finding/photo save and sign-off retesting, device camera/gallery behavior, reminders, and durable offline sync remain incomplete.

## Current snapshot

| Area | Status | Notes |
| --- | --- | --- |
| App shell and authentication | Implemented | Supabase setup, sign-in, and workshop setup screens exist. |
| Intake and applications | Implemented; authenticated live QA pending | Reads and RPC-backed writes are Supabase-backed. Unchanged retries reuse the request ID; edited submissions receive a new one. Migrations are applied. Application cards route to the next incomplete task. |
| Bay check-in | Implemented; device QA pending | Six-photo gate is enforced in the client and database; manager overrides require a workshop owner. Private Storage bucket and workshop-scoped policies are present. |
| Condition report | Implemented; authenticated live QA in progress | A live synthetic QA job reached condition report. Photo preview works; save exposed IDs exceeding PostgreSQL `integer` range. The client now generates positive 32-bit IDs, retries uncertain writes safely, and preserves uploaded photos when a failed row commit cannot be confirmed; live save/sign-off retest remains. |
| Job card / estimate | Partial | Estimate item add/edit/remove, sent locking, per-item approve/decline/revision responses, audit history, and unanimous-approval transition are implemented. The vehicle record now shows customer decisions; authenticated live verification remains. |
| Mechanical inspection | Implemented; authenticated live QA pending | Records brake, tyre, and battery readings or explicit not-applicable choices; validates odometer and persists completion. Application cards route to inspection before the estimate. |
| Customer approvals / WhatsApp | Implemented; authenticated live QA pending | WhatsApp launch requires recorded consent; responses are captured per item and recorded through an audited RPC. Delivery receipts are not tracked. |
| Work in progress | Implemented; authenticated live QA pending | Shows approved estimate scope and an immutable, audited log for technician notes, parts delays, and customer updates. QC/road test is the next workflow gate. |
| Inventory | Implemented; authenticated live QA pending | Workshop-scoped parts, suppliers, low-stock thresholds, stock receipt and adjustment history are implemented. Approved-job issue/return RPCs enforce estimate quantity limits. |
| QC / road test | Implemented; authenticated live QA pending | Requires repair-complete confirmation, four explicit checks, and a road-test result or reason. Failed QC keeps work in progress; audited pass moves to `QC_PASSED`. |
| GST invoice | Implemented; authenticated live QA pending | For GST-registered suppliers, uses approved-estimate rates, creates an immutable snapshot and FY serial in a database RPC, computes state-based tax split, and prints a PDF. Bill-of-supply and IRN submission are not implemented; tax classification needs accountant verification. |
| Payment / delivery | Implemented; authenticated live QA pending | Payment ledger, balance checks, owner-only audited credit override, and server-enforced handover are implemented. Invoice, payment, and delivery flows recover safely from lost RPC responses; delivery retries are idempotent in the database. |
| Vehicle passport / reminders | Partial | Internal history now expands saved mechanical measurements, customer estimate decisions, not-applicable values, and inspection notes. Live query verification, reminder routing/persistence/dispatch, and a public QR/passport remain incomplete. |
| Offline-first sync | Not implemented | Current outbox service is in-memory and is not wired as a durable background worker. |

## Next work

1. Resume the synthetic QA job at condition report; save and reload a finding/photo, complete sign-off, verify private photo access, then test six-photo capture and workshop isolation with a second account.
2. Walk the remaining estimate, approval, work, QC, invoice, and payment/delivery lifecycle with a clean, authorized test account.
3. Add customer decision history to vehicle history, finish passport and service reminders, then implement durable offline sync.
4. Add golden tests and finish device, platform, accessibility, and release QA. GitHub Actions runs formatting, analysis, tests, and a web release build for `master` pushes and pull requests.

See [docs/DEVELOPER_HANDOFF.md](docs/DEVELOPER_HANDOFF.md) for detailed priorities, architecture notes, setup, and verification limits. The older `tasks/` documents are historical specifications and do not represent current completion status.
