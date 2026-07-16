# TCIScreenNew PDTci-Inspired Responsive Layout Design

## Goal

Redesign `TCIScreenNew` to mimic the flow and layout of the standalone `pdtci` calculator while continuing to use Propofol Dreams Flutter widgets, state, calculation behavior, and current Material color scheme.

This is a visual and layout refinement for the parallel `TCIScreenNew` only. The existing in-app `TCIScreen` remains unchanged until the new screen is explicitly approved.

## Approved Direction

- Use the `pdtci` flow: results first, table-focused, input controls gathered into a bottom sheet on mobile.
- Do not include a top identity/header bar.
- Keep the current Propofol Dreams Material color scheme rather than copying `pdtci` warm static-site colors.
- Preserve existing Flutter widgets where possible: `PKField`, `SwitchField`, `Selector<Drug>`, `InfusionRateChart`, `DosageDataTable`, and existing dashboard/stat components.
- Keep current behavior and calculation state, including debounced calculation, drug concentration resolution from `Settings`, wall-clock sync, and legacy pdtci drug-to-model mapping in `TCIScreenNew`.

## Responsive Layout

### Mobile

Mobile should follow the pdtci interaction model:

- Main content starts immediately with results, not app identity chrome.
- Top of content shows compact dosing summary cards, prioritizing bolus, total volume/dose, and max rate.
- Hide the chart on mobile by default to preserve the pdtci table-first flow and avoid crowding the bottom input sheet.
- The infusion table is the dominant central object and should be vertically scrollable.
- Inputs live in a bottom `CollapsibleInputSection` sheet.
- Collapsed input state shows compact patient/drug/target chips using the current two-row `collapsedChipRows` API.

Mobile keeps the current fixed-bottom input behavior but changes visual ordering so the result/table area feels like pdtci.

### Desktop And Tablet

Desktop and tablet should use a custom clinical workstation layout, not a direct scale-up of the mobile bottom-sheet layout:

- No top identity/header bar.
- Page content is a max-width centered workspace using the current screen background and card colors.
- Left/main area contains dosing summary cards, chart/context, and the infusion table.
- The infusion table should remain visually dominant and occupy the largest continuous area.
- Patient/drug/model context appears near the chart or above the table instead of in an app header.
- Right rail contains input controls in a persistent card, similar to the current desktop `TCIScreen` editing affordance.
- Error/status/sync hints live near the input rail or below controls.

Desktop/tablet intentionally differs from mobile because it has enough width to keep controls visible without obscuring results.

## Architecture

Implement the redesign surgically inside `lib/screens/tci_screen_new.dart`.

- Do not modify `lib/screens/tci_screen.dart`.
- Do not wire `TCIScreenNew` into `HomeScreen` as part of this work.
- Keep `lib/main_tci_standalone.dart` and `lib/screens/tci_standalone_shell.dart` rendering `TCIScreenNew`.
- Reuse existing state variables, controllers, validation, calculation methods, and model mapping.
- Prefer reorganizing existing builder methods over introducing a new state-management layer.
- Add small private builder methods only where they clarify layout sections, such as summary, context, table, and input rail sections.

## Components

The implementation should compose existing UI pieces into new layout sections:

- Summary cards: reuse or lightly adapt `_buildDashboardCards` / `_buildStatCard`.
- Patient context: reuse `_buildPatientChips` or a compact variant.
- Chart: show `InfusionRateChart` in the desktop/tablet context section; keep it hidden in the mobile layout.
- Table: reuse `DosageDataTable` and current sync callbacks.
- Inputs: reuse `_buildInputFields`, `_buildInputPanel`, and `CollapsibleInputSection`.

Avoid extracting shared widgets with the existing `TCIScreen` until `TCIScreenNew` is approved. Copying/refactoring within `TCIScreenNew` is acceptable if it keeps the old screen stable.

## Data Flow And Behavior

- User edits inputs through existing controllers and widgets.
- Debounced calculation updates `infusionRegimeData` exactly as it does now.
- Drug selection remains display-name deduplicated and concentration is resolved from `Settings` before calculation.
- `TCIScreenNew.modelForDrug` continues to preserve pdtci mapping:
  - Propofol -> `Model.Eleveld`
  - Remifentanil -> `Model.Eleveld`
  - Dexmedetomidine -> `Model.Hannivoort`
  - Remimazolam -> `Model.Schnider`
- Table row selection and wall-clock sync behavior remain intact.
- The standalone build continues to use `scripts/build_pdtci_web.sh`.

## Error Handling

- Validation errors continue to use `_validate` and `_buildErrorPanel`.
- Mobile errors should remain visible inside or just above the bottom input sheet.
- Desktop/tablet errors should appear in the right input rail so users can correct fields without scanning the results area.
- Empty/no-result state should remain simple and centered in the result/table area.

## Testing

Update or add tests for:

- `TCIScreenNew` renders on desktop/tablet width without `HomeScreen` navigation.
- `TCIScreenNew` renders on mobile width with the bottom input sheet and no navigation chrome.
- `TciStandaloneShell` still renders `TCIScreenNew` directly.
- Drug-model mapping test continues to lock Remimazolam -> Schnider.

Run these verifications after implementation:

- `flutter test test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart test/tci_screen_drug_model_test.dart`
- `flutter test`
- `scripts/build_pdtci_web.sh`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`

Plain `flutter analyze` is not a completion gate for this work because the repo has existing historical warnings/infos unrelated to the screen redesign.

## Out Of Scope

- Replacing the current app `TCIScreen` route.
- Publishing to the external `pdtci` repository.
- Changing calculation behavior or pharmacokinetic models.
- Changing the global app color scheme.
- Adding top identity/header chrome.
- Large shared-widget extraction between old and new TCI screens.
