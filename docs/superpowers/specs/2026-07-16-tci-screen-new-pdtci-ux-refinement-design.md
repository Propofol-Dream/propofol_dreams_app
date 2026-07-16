# TCIScreenNew PDTci UX Refinement Design

## Goal

Refine `TCIScreenNew` to more closely match the live `https://pdtci.netlify.app/` workflow while preserving Propofol Dreams Flutter widgets, current color scheme, and existing pharmacokinetic behavior.

This iteration focuses on time-sync UX, input ordering, and result/table hierarchy. It does not replace the existing app `TCIScreen` route.

## Reference Behavior

The pdtci reference app uses these relevant interaction patterns:

- The table is the main interaction surface.
- Time cells are clickable and drive clock-time sync.
- Clock sync is configured through a compact `Set Clock Time` panel with hour/minute fields and `Sync Time` / `Clear Sync` actions.
- The target stepper is the most prominent input and appears before patient demographics.
- Patient input is compact and grouped rather than split across unrelated card areas.

## Approved Changes

### Time Sync UX

- Remove the current start-time field from the main input row in `TCIScreenNew`.
- Keep row tapping as the way to select a table time anchor.
- When a table row is selected, show a compact time-sync panel modeled on pdtci:
  - title: `Set Clock Time`
  - hour numeric field
  - minute numeric field
  - `Sync Time` action
  - `Clear Sync` action
- `Sync Time` maps the selected table row to the chosen clock time by computing `_startTime = chosenClockTime - selectedRow.time`, wrapping across midnight into a valid `TimeOfDay`.
- `Clear Sync` clears `_syncedRowIndex`, `_syncedClockTime`, and `_isTableSynced`.
- If no table row is selected, the panel is hidden.
- Existing row highlighting and table scrolling behavior remain intact.

### Input Panel Layout

The `TCIScreenNew` input panel should match pdtci / app-style flow more closely:

- First row: target stepper as the primary input.
- Second row: drug selector plus reset button.
- Third row: sex and age.
- Fourth row: weight and height.
- Time sync panel appears after the drug row when a table row is selected.
- Keep using current Flutter widgets: `PKField`, `SwitchField`, `Selector<Drug>`, and the existing reset button style.
- Keep current Material color scheme and field fill behavior.
- Keep validation behavior unchanged.

### Result Hierarchy

- Remove the top three summary cards from `TCIScreenNew` mobile and desktop/tablet result layouts.
- Preserve the table as the dominant result surface.
- Move target/effect-site context (`CeT`) into the result context area above the table.
- Show `eBIS` below the table as a compact footer/status row.
- On mobile, keep the chart hidden.
- On desktop/tablet, remove the chart from the primary layout for this iteration so the table remains dominant; the summary cards must not return.

### CeT And eBIS Data

- Use values already produced by the current simulation estimate.
- Do not change pharmacokinetic calculations.
- Add TCI-only display fields in `TCIScreenNew`; do not change shared `InfusionRegimeRow`, `InfusionRegimeData`, or old `TCIScreen` APIs for this iteration.
- Store sampled display values alongside `infusionRegimeData` in `TCIScreenNew`:
  - `_effectSiteConcentrationsByRow`: one nullable value per displayed 15-minute table row
  - `_bisEstimatesByRow`: one nullable value per displayed 15-minute table row
- Build those lists from `simulation.estimate.concentrationsEffect` and `simulation.estimate.BISEstimates` by sampling the first simulation index whose `simulation.estimate.times[index] >= displayedRow.time`, clamped to the available list range. This works when `settings.time_step` is not one second.
- `TCIScreenNew` displays:
  - current/target effect-site concentration label (`CeT`) above the table
  - estimated BIS (`eBIS`) below the table
- If `_syncedRowIndex` is available, display Ce/eBIS for that row.
- If `_syncedRowIndex` is not available, display the first generated row's Ce/eBIS values so the initial table state has stable values.
- If values are unavailable for a drug/model combination, show `--` rather than hiding the footer.

## Architecture

- Keep implementation isolated to `TCIScreenNew` and the minimum table/data support needed for Ce/eBIS display.
- Do not modify `lib/screens/tci_screen.dart`.
- Do not wire `TCIScreenNew` into `HomeScreen`.
- Keep `lib/main_tci_standalone.dart` and `lib/screens/tci_standalone_shell.dart` unchanged unless tests reveal a direct standalone breakage.
- Prefer small private builders in `TCIScreenNew`:
  - target-first input section
  - pdtci time-sync panel
  - CeT context row
  - eBIS footer row
- Avoid broad refactors of shared screens or global table components unless needed to pass existing callers.

## Data Flow

1. User edits target/drug/patient inputs through existing controllers.
2. Existing debounced `calculate()` runs and produces simulation output.
3. The simulation output is converted into display data, including table rows and Ce/eBIS values.
4. User taps a table row.
5. `TCIScreenNew` records the selected row and shows the pdtci-style time-sync panel.
6. User enters hour/minute and taps `Sync Time`.
7. `_startTime` is recalculated from the chosen clock time and selected row duration; sync-state behavior updates the table clock-time display.
8. `CeT` and `eBIS` reflect `_syncedRowIndex` when it is available; otherwise they use row `0`.

## Error Handling

- Validation errors continue to use the existing `_validate` and `_buildErrorPanel` behavior.
- Time-sync hour input accepts `0-23`.
- Time-sync minute input accepts `0-59`.
- Invalid time-sync values disable `Sync Time`; do not route time-entry validation through the patient-input error panel.
- If no row is selected, `Sync Time` is unavailable and the time-sync panel is hidden.
- If Ce/eBIS values are unavailable, render `--`.

## Testing

Add or update tests for:

- `TCIScreenNew` no longer calls `_buildDashboardCards` from mobile or desktop result layouts. Tests should assert by layout keys or widget structure, not by absence of text such as `Bolus`, because the table still contains a bolus row.
- `TCIScreenNew` input panel renders target before drug/patient fields.
- Selecting a table row reveals the `Set Clock Time` panel.
- `Set Clock Time` panel includes hour/minute fields plus `Sync Time` and `Clear Sync` actions.
- `TCIScreenNew` renders `CeT` above the table and `eBIS` below the table.
- Existing standalone shell and drug-model mapping tests still pass.
- Existing old `TCIScreen` tests and behavior remain unchanged.

Verification commands:

- `flutter test test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart test/tci_screen_drug_model_test.dart`
- `flutter test`
- `scripts/build_pdtci_web.sh`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`

Plain `flutter analyze` remains outside the completion gate because the repository has historical warning/info debt.

## Out Of Scope

- Publishing to the external `pdtci` repo.
- Changing pharmacokinetic models or simulation math.
- Changing global app color scheme.
- Replacing the current app `TCIScreen` route.
- Adding top identity/header chrome.
- Reintroducing top summary cards in `TCIScreenNew`.
