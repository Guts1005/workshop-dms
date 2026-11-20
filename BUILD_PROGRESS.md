# Build progress

**Updated:** 20 November 2026

Workshop DMS is an active prototype. Intake, application listing, bay check-in, and condition reporting are implemented against Supabase, but the end-to-end live-project flow and device QA still need verification. Several downstream workflow pages are placeholders.

## Current snapshot

| Area | Status | Notes |
| --- | --- | --- |
| App shell and authentication | Implemented | Supabase setup, sign-in, and workshop setup screens exist. |
| Intake and applications | Implemented; live QA pending | Writes and reads are Supabase-backed. Application cards now route to the next incomplete task. Verify against the intended project. |
| Bay check-in | Implemented; migration/device QA pending | Six-photo gate is enforced in the client and in migration `202611200001`; manager overrides require a workshop owner. Private Storage upload and retake-safe replacement are present. Apply the migration to the target project before live use. |
| Condition report | Implemented; live QA pending | Findings, optional photos, review areas, and sign-off exist. |
| Job card / estimate | Partial | Line items persist; sent estimates lock. Per-item approval, decline, revision response, audit history, and unanimous-approval transition are implemented. Vehicle passport history and live Supabase verification remain. |
| Mechanical inspection | Implemented; migration/live QA pending | Records brake, tyre, and battery readings or explicit not-applicable choices; validates odometer and persists completion. Application cards route to inspection before the estimate. Apply migration `202611200002` before live use. |
| Customer approvals / WhatsApp | Implemented; migration/live QA pending | WhatsApp launch requires recorded consent; responses are captured per item and recorded through an audited RPC. Migration `202611200005` locks status and approval fields behind validated database functions. Apply migrations `202611200004` and `202611200005` before live use. Delivery receipts are not tracked. |
| Work in progress / inventory | Not implemented | No complete persisted workflow. |
| QC / road test | Not implemented | Route is a placeholder. |
| GST invoice / payment / delivery | Not implemented | Routes are placeholders; corresponding durable tables and gates are missing. |
| Vehicle passport / reminders | Partial | Internal history and calculation helpers exist; public QR/passport and reminders are incomplete. |
| Offline-first sync | Not implemented | Current outbox service is in-memory and is not wired as a durable background worker. |

## Next work

1. Apply all eight migrations, then verify RLS, auth, photos, and the complete intake-to-workflow flow against the target Supabase project.
2. Add customer decision history to vehicle history; implement QC and road-test gates.
3. Add inventory, GST invoice, payment, and delivery persistence and gates.
4. Complete passport and service reminders, then durable offline sync.
5. Add CI and finish platform, security, accessibility, and release QA.

See [docs/DEVELOPER_HANDOFF.md](docs/DEVELOPER_HANDOFF.md) for detailed priorities, architecture notes, setup, and verification limits. The older `tasks/` documents are historical specifications and do not represent current completion status.
