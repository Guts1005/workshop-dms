# Build progress

**Updated:** 20 November 2026

Workshop DMS is an active prototype. Intake, application listing, bay check-in, and condition reporting are implemented against Supabase, but the end-to-end live-project flow and device QA still need verification. Several downstream workflow pages are placeholders.

## Current snapshot

| Area | Status | Notes |
| --- | --- | --- |
| App shell and authentication | Implemented | Supabase setup, sign-in, and workshop setup screens exist. |
| Intake and applications | Implemented; live QA pending | Writes and reads are Supabase-backed. Verify against the intended project. |
| Bay check-in | Implemented; device QA pending | Required photo capture and private Storage upload are present. |
| Condition report | Implemented; live QA pending | Findings, optional photos, review areas, and sign-off exist. |
| Job card / estimate | Partial | Line item creation exists; approval and lifecycle need validation/completion. |
| Mechanical inspection | Not implemented | Route is a placeholder. |
| Customer approvals / WhatsApp | Not implemented | Route is a placeholder. |
| Work in progress / inventory | Not implemented | No complete persisted workflow. |
| QC / road test | Not implemented | Route is a placeholder. |
| GST invoice / payment / delivery | Not implemented | Routes are placeholders; corresponding durable tables and gates are missing. |
| Vehicle passport / reminders | Partial | Internal history and calculation helpers exist; public QR/passport and reminders are incomplete. |
| Offline-first sync | Not implemented | Current outbox service is in-memory and is not wired as a durable background worker. |

## Next work

1. Verify migrations, RLS, auth, photos, and the complete intake-to-condition-report flow against the target Supabase project.
2. Implement mechanical inspection and connect findings to durable vehicle/job history.
3. Complete estimate approval and workflow state transitions.
4. Add inventory, QC, GST invoice, payment, and delivery persistence and gates.
5. Complete passport and service reminders, then durable offline sync.
6. Add CI and finish platform, security, accessibility, and release QA.

See [docs/DEVELOPER_HANDOFF.md](docs/DEVELOPER_HANDOFF.md) for detailed priorities, architecture notes, setup, and verification limits. The older `tasks/` documents are historical specifications and do not represent current completion status.
