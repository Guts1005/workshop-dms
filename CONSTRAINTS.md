# Technical & Visual Constraints Contract (CONSTRAINTS.md)

This contract defines non-negotiable architectural, visual, and operational rules for the Automotive Workshop Management System. Any automated code or pull request that violates these constraints will be rejected.

---

## 1. Visual & Accessibility Invariants

1. **Strict 90° Geometry:**
   * `BorderRadius.circular` is **forbidden**. All borders must have zero radius (`BorderRadius.zero`).
   * No box shadows (`BoxShadow` is forbidden).
   * No linear or radial gradients (`LinearGradient` is forbidden).

2. **Contrast & Color Constraints:**
   * Text on `#DB4A2B` must be `#FFFFFF`, bold, minimum 18px (4.2:1 contrast minimum).
   * `#DB4A2B` as text color is allowed only at 24px or larger on `#E4E2DD` (3.2:1 ratio).
   * `#F8A348` is strictly forbidden as text or icon color. It may only be used as a background fill with `#1E1E1E` text (8:1 ratio).
   * `#FF89A9` is strictly forbidden as a border, focus ring, or text color. It can only be used as a pressed background tint on rows/cards with `#1E1E1E` text.

3. **Touch Targets:**
   * Every interactive element (buttons, tabs, inputs, table rows) must have a minimum hit test area of `48px x 48px`.
   * Minimum gap between tappable targets is `8px`.
   * Minimum table row height is `56px`.
   * Minimum body text size is `16px`.

4. **Focus Rings (Keyboard & Hybrid Input):**
   * Every interactive element must render a `3px solid #1E1E1E` outline with a `2px offset`.
   * On dark `#1E1E1E` surfaces, the focus ring must render as `3px solid #E4E2DD` with a `2px offset`.

---

## 2. Operational & Data Invariants

1. **Check-in Gating Rule:**
   * No Job Card can transition to `INSPECTION_PENDING`, `ESTIMATE_SENT`, or `WORK_IN_PROGRESS` without all 6 required camera shots:
     - `CORNER_FL`
     - `CORNER_FR`
     - `CORNER_RL`
     - `CORNER_RR`
     - `PLATE_CLOSEUP`
     - `ODOMETER`
   * Gallery uploads are strictly prohibited for these 6 shots. The camera API must directly produce the byte buffer.

2. **Photo Integrity & Immutability:**
   * A SHA-256 hash must be generated on-device immediately upon photo capture and stored with the metadata.
   * Original captured photos cannot be edited, cropped, or overwritten.

3. **Financial Precision:**
   * All currency amounts (Rates, Totals, Taxes, Discounts) must be calculated and stored as integer **paise** (1 Rupee = 100 paise) to prevent IEEE-754 floating-point rounding errors.
   * GST must calculate CGST and SGST separately at exact integer paise.

4. **Strict Payment Gate:**
   * Transition to `DELIVERED` status requires `balance == 0`, OR an explicit Credit Override containing:
     - `authorized_by` (non-empty string)
     - `promised_due_date` (valid future timestamp)
     - `reason` (non-empty string)

5. **Offline-First Resilience:**
   * All read operations must query the local Drift SQLite database. No screen may show a blocking network loader when reading local data.
   * Mutations write to Drift and insert a sync record in `sync_queue`. Sync occurs asynchronously in the background.
