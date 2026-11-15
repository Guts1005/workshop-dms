# BUILD_PROGRESS.md

## Master Project Governance & Sign-off Register
*Automotive Workshop Management System (DMS)*

> **GOVERNANCE RULES:**
> 1. Never work on a page's functionality and visual design in the same pass. Functionality first, design second.
> 2. Never move to the next page until the current page's checklist is 100% verified and checked below.
> 3. Resume at the first unchecked box on every new session. Do not skip ahead.

---

### Project Execution Register

| Phase / Page | Name | Functionality (Stage A) | Design (Stage B) | Tests & Quality (Stage C) | Notes / Blockers |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Phase 0** | **Foundation & UI Kit** | [x] | [x] | [x] | Riverpod state, go_router shell, tokens, primitive widgets + tests, Drift outbox, camera capture module |
| **Page 1** | **Vehicle & Customer Intake** | [ ] | [ ] | [ ] | Plate/VIN entry, customer lookup/create, odometer, fuel, consent & WhatsApp opt-in |
| **Page 2** | **Bay Check-in Capture** | [ ] | [ ] | [ ] | 4-corner 45° + plate + odometer, manager override, SHA-256 hashes, Job Card lock |
| **Page 3** | **360° Condition Map** | [ ] | [ ] | [ ] | 4-view CustomPainter, numbered pin drops, photo per pin, swipe-to-confirm sign-off |
| **Page 4** | **Mechanical Inspection** | [ ] | [ ] | [ ] | Traffic-light checklist, real measurements, passport wear estimates |
| **Page 5** | **Job Card & Estimate** | [ ] | [ ] | [ ] | Labour SAC 998714, effective-dated GST table, voice notes, per-line approval structure |
| **Page 6** | **WhatsApp Dispatch** | [ ] | [ ] | [ ] | Per-line approval, decline persistence, expiration timer, wa.me utility links |
| **Page 7** | **Work in Progress Board** | [ ] | [ ] | [ ] | Technician grid, time clock, auto-deduct stock, old vs new part photos, change orders |
| **Page 8** | **QC & Road-Test Gate** | [ ] | [ ] | [ ] | Strict gate before invoicing, road-test sign-off checklist |
| **Page 9** | **GST Invoicing** | [ ] | [ ] | [ ] | Data-driven effective-dated rate table, CGST/SGST/IGST, integer paise calculation |
| **Page 10** | **Payment Gate & Release** | [ ] | [ ] | [ ] | Swipe-to-confirm delivery, zero balance lock, credit override audit, debtors ledger |
| **Page 11** | **Digital Health Passport** | [ ] | [ ] | [ ] | Customer-facing web/QR view, blurred plate, wear estimates, hash-signed PDF export |
| **Page 12** | **Service Reminders** | [ ] | [ ] | [ ] | Guarded daily KM formula (rollback/same-day checks), WhatsApp utility template |
| **Page 13** | **Home Dashboard** | [ ] | [ ] | [ ] | (Optional, last) Shop overview, active bay metrics, urgent actions |

---

### Per-Page Sign-Off Checklist Template
Every page must satisfy all 4 criteria before its row is checked off:
- [ ] **Functionality:** Drift/Outbox wired, all states handled (loading, empty, error, offline-queued, success), unit tests green, `flutter analyze` 0 issues.
- [ ] **Design:** Sharp corners (0px radius), established theme palette, swipe-to-confirm on irreversible actions, contrast verified (WCAG AAA/AA).
- [ ] **Tests:** Unit tests for validators/formatters, widget tests for each state, golden test added.
- [ ] **Manual QA:** Verified on real physical target hardware; offline/airplane mode transition verified.
