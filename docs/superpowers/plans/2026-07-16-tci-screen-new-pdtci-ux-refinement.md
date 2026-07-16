# TCIScreenNew PDTci UX Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine `TCIScreenNew` to match pdtci's target-first inputs, table-driven clock sync, and CeT/eBIS result hierarchy.

**Architecture:** Keep changes isolated to `lib/screens/tci_screen_new.dart` and `test/tci_screen_new_test.dart`, plus this spec/plan. Store Ce/eBIS sampled values as TCI-only state in `TCIScreenNew`; do not change shared table data APIs or the old `TCIScreen`.

**Tech Stack:** Flutter, Provider `Settings`, existing `PKField`/`SwitchField`/`Selector`, existing `DosageDataTable`, Flutter widget tests.

---

## Tasks

### Task 1: Add Focused Widget Tests

**Files:**
- Modify: `test/tci_screen_new_test.dart`

- [ ] Add tests for target-before-drug input ordering, table-row tap revealing `Set Clock Time`, time panel actions, and CeT/eBIS labels.
- [ ] Run `flutter test test/tci_screen_new_test.dart` and verify the new tests fail before implementation.

### Task 2: Add TCI-Only Ce/eBIS Display State

**Files:**
- Modify: `lib/screens/tci_screen_new.dart`

- [ ] Add `_effectSiteConcentrationsByRow` and `_bisEstimatesByRow` state lists.
- [ ] Populate them during `calculate()` from `simulation.estimate.times`, `concentrationsEffect`, and `BISEstimates` by sampling each displayed 15-minute row time.
- [ ] Reset them when calculation fails or data is cleared.

### Task 3: Rework Input Panel And Time Sync

**Files:**
- Modify: `lib/screens/tci_screen_new.dart`

- [ ] Reorder `_buildInputFields` to target row, drug/reset row, sync panel when selected, sex/age row, weight/height row.
- [ ] Remove `_buildStartTimeField` from the normal input layout.
- [ ] Replace `_buildSyncSection` with pdtci-style `Set Clock Time` panel containing hour/minute numeric fields and `Sync Time` / `Clear Sync` buttons.
- [ ] Compute `_startTime` from chosen clock time minus selected row duration, wrapping across midnight.

### Task 4: Rework Results Hierarchy

**Files:**
- Modify: `lib/screens/tci_screen_new.dart`

- [ ] Remove `_buildDashboardCards` calls from desktop and mobile result layouts.
- [ ] Remove chart from desktop primary layout for this iteration.
- [ ] Add a CeT context row above the table and an eBIS footer below the table.
- [ ] Keep table dominant on mobile and desktop/tablet.

### Task 5: Verify And Polish

**Files:**
- Modify only files needed to fix verification failures.

- [ ] Run `dart format lib/screens/tci_screen_new.dart test/tci_screen_new_test.dart`.
- [ ] Run `flutter test test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart test/tci_screen_drug_model_test.dart`.
- [ ] Run `flutter test`.
- [ ] Run `scripts/build_pdtci_web.sh`.
- [ ] Run `flutter analyze --no-fatal-infos --no-fatal-warnings`.

## Self-Review

- Spec coverage: all approved UX changes map to Tasks 1-5.
- Placeholder scan: no TBD/TODO placeholders.
- Type consistency: all referenced state/method names are scoped to `TCIScreenNew`.
