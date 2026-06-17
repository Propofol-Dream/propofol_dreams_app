# PD Input Control Frame Design

## Purpose

Create a rollback-safe PD input layout system that keeps controls aligned when validation or status messages appear.

This design addresses the current selector/reset alignment problems, inconsistent `helperText` behavior, and future status-message consistency for text fields, switch fields, and selector rows.

## Scope

This spec covers:

- `PDInputControlFrame`: shared fixed-height control area plus fixed-height compact status lane.
- `PDCalculatorSelectorRow`: shared selector plus reset row using `PDInputControlFrame`.
- Internal redesign of `PDTextField` and `PDSwitchField` to use the frame while preserving their existing public APIs and behavior.
- A rollback path through `UIConfig`.
- Follow-up cleanup after the migration is stable.

This spec does not cover:

- Changing clinical calculation logic.
- Changing pharmacokinetic model validation rules.
- Replacing `PDTextField` or `PDSwitchField` with new public widget names.
- Migrating the full app to Material 3.
- Redesigning result tables or calculator pane layout.

## Current Problems

The app currently uses a mix of helper/error rendering approaches:

- Some fields use `InputDecoration.helperText` or `errorText` directly.
- Some components pass `helperText: null`.
- Some call sites still pass `helperText: ''`.
- Empty helper text can alter field height and make reset buttons difficult to align with selectors.
- Selectors, text fields, and switches do not share one geometry contract.

The desired behavior is zero layout shift when selector-level, field-level, or switch-level status text appears.

## Design Principles

- Keep controls stable: selector, reset button, text field, and switch positions must not move when status text appears.
- Reserve status space intentionally outside the input decoration, not through `helperText: ''`.
- Constrain status width to the relevant control only.
- Preserve existing calculation timing, controller ownership, and haptic behavior.
- Keep rollback simple through a central feature flag.
- Keep the first implementation behavior-preserving; cleanup old code after stabilization.

## Component: PDInputControlFrame

`PDInputControlFrame` provides the shared geometry contract for input-like controls.

File path:

- `lib/components/PDInputControlFrame.dart`

It renders:

```text
[ fixed-height control area ]
[ fixed-height status lane  ]
```

Responsibilities:

- Reserve `controlHeight` for the actual control.
- Reserve `statusHeight` for compact status text.
- Expose a total frame height of `controlHeight + statusHeight`.
- Render status text with consistent styling.
- Truncate long status text with ellipsis.
- Keep status width constrained to the frame width.
- Provide semantics for visible status text.

Non-responsibilities:

- Validation logic.
- Text editing behavior.
- Controller lifecycle.
- Modal behavior.
- Clinical/model/drug rules.

Proposed API shape:

```dart
enum PDInputStatusType { none, error, warning, info }

class PDInputControlFrame extends StatelessWidget {
  const PDInputControlFrame({
    super.key,
    required this.child,
    this.statusText,
    this.statusType = PDInputStatusType.none,
    this.controlHeight = 56,
    this.statusHeight = 24,
    this.statusIcon,
  });

  final Widget child;
  final String? statusText;
  final PDInputStatusType statusType;
  final double controlHeight;
  final double statusHeight;
  final IconData? statusIcon;
}
```

Status lane behavior:

- The lane is always reserved.
- If `statusText` is `null`, empty, or `statusType == PDInputStatusType.none`, the lane is visually empty.
- If `statusText` is non-empty and `statusType != PDInputStatusType.none`, the lane shows an icon plus one-line text.
- Text uses `TextOverflow.ellipsis`.
- Status lane height remains fixed.
- The default `statusHeight` is `24` to match the existing `UIHeight + 24` row pattern used around PD input fields.
- Parent rows must allocate `controlHeight + statusHeight` for framed inputs instead of relying on `InputDecoration` helper/error height.
- Default status icons are `Icons.error_outline` for `error`, `Icons.warning_amber_outlined` for `warning`, and `Icons.info_outline` for `info`. A supplied `statusIcon` overrides the default icon.
- Status colors come from the active theme: `colorScheme.error` for `error`, `colorScheme.tertiary` for `warning`, and `colorScheme.primary` for `info`.

## Component: PDCalculatorSelectorRow

`PDCalculatorSelectorRow` provides the shared selector plus reset row.

File path:

- `lib/components/PDCalculatorSelectorRow.dart`

It renders:

```text
[ selector field........................ ] [ reset ]
[ selector status lane.................. ] [ spacer ]
```

Responsibilities:

- Place selector inside `Expanded` so it only uses the width available after reset button and spacing.
- Treat `selector` as a control-only widget. The selector child must not include its own status/helper/error lane.
- Keep reset button fixed square: `height x height`.
- Keep reset button top-aligned with the selector control area.
- Put selector status text under the selector only.
- Keep selector status width maxed to selector width, not the full row width.
- Add tooltip and semantics for reset.

Non-responsibilities:

- Building the selector widget.
- Opening model/drug/concentration modals.
- Computing validation text.
- Deciding reset semantics.

Proposed API shape:

```dart
class PDCalculatorSelectorRow extends StatelessWidget {
  const PDCalculatorSelectorRow({
    super.key,
    required this.selector,
    required this.onReset,
    required this.resetTooltip,
    this.selectorStatusText,
    this.selectorStatusType = PDInputStatusType.none,
    this.height = 56,
    this.spacing = 8,
  });

  final Widget selector;
  final VoidCallback onReset;
  final String resetTooltip;
  final String? selectorStatusText;
  final PDInputStatusType selectorStatusType;
  final double height;
  final double spacing;
}
```

The row uses `PDInputControlFrame` internally for the selector side. The reset side uses a fixed-width spacer below the reset button so the status lane under the selector never extends under the reset button.

## Error And Status Routing

Errors are routed by ownership:

- Field-specific errors stay with the field.
- Switch-specific status stays with the switch.
- Selector errors stay under `PDCalculatorSelectorRow`.
- Cross-field model, drug, or concentration compatibility errors stay under `PDCalculatorSelectorRow`.
- Ambiguous compatibility errors, such as BMI/model compatibility, default to the selector row.

Examples:

- Age field is empty: show on age field status lane.
- Weight is outside the current model's absolute range: show on weight field status lane.
- BMI makes the current model unavailable: show under selector row as `BMI outside model range`.
- Drug concentration selection is incompatible: show under selector row.

Status text rules:

- Use short messages in status lanes.
- Use one line only.
- Truncate with ellipsis.
- Keep full explanations in model/drug/concentration selector modals or details when the compact status text cannot fully identify the cause.
- Do not rely on color alone; include an icon for error/warning states.

## PDTextField Redesign

`PDTextField` keeps its existing public name and current constructor parameters. The only permitted public API change is adding optional parameters that preserve every existing call site without modification.

Required behavior to preserve:

- Numeric text editing.
- Plus/minus step buttons.
- Long-press repeat behavior.
- Configurable interval.
- Configurable fraction digits.
- Range validation.
- Prefix icon and label.
- Enabled/disabled state.
- Existing controller ownership behavior.
- Existing `onPressed` callback timing.
- Existing haptic behavior.
- Existing responsive control height behavior, with the existing `height` parameter continuing to override the control height.

Layout change:

- The visible text-field control is rendered in the `controlHeight` area.
- Field error/status text moves to `PDInputControlFrame`'s status lane.
- The framed implementation must not use `InputDecoration.helperText` or `InputDecoration.errorText` to create vertical space.
- The framed implementation must keep any `InputDecoration.helperText` and `InputDecoration.errorText` values `null`; status text is rendered only by `PDInputControlFrame`.
- Existing `helperText` values are mapped to `PDInputControlFrame.statusText` with `PDInputStatusType.info` when there is no validation error.
- Existing validation errors are mapped to `PDInputControlFrame.statusText` with `PDInputStatusType.error`.

## PDSwitchField Redesign

`PDSwitchField` keeps its existing public name and current constructor parameters. The only permitted public API change is adding optional parameters that preserve every existing call site without modification.

Required behavior to preserve:

- Two-state toggle.
- Custom labels for each state.
- Prefix icon changes.
- Enabled/disabled state.
- Existing controller integration.
- Existing callback timing.
- Existing haptic behavior.
- Existing control height behavior, with the existing `height` parameter continuing to override the control height.

Layout change:

- The visible switch field is rendered in the `controlHeight` area.
- Switch status text uses `PDInputControlFrame`'s status lane.
- The framed implementation must not use helper text for geometry.
- New optional switch status/helper parameters are mapped to `PDInputControlFrame.statusText` instead of `InputDecoration.helperText`.

## Rollback Strategy

Add this centralized migration flag to `UIConfig`:

```dart
static const bool useInputControlFrame = true;
```

The implementation slice starts with this flag set to `true` while testing the migrated screens. Rolling back means changing this flag to `false`, which must restore the old rendering paths without changing screen logic.

When enabled:

- `PDTextField` renders through `PDInputControlFrame`.
- `PDSwitchField` renders through `PDInputControlFrame`.
- `PDCalculatorSelectorRow` uses `PDInputControlFrame` for selector status.

When disabled:

- Old widget rendering paths remain available.
- Existing `helperText`, `errorText`, field height, and selector/reset row behavior must match the current implementation exactly in the old rendering path.

Rollback constraints:

- No calculation logic moves.
- No controller ownership changes.
- No callback timing changes.
- No clinical behavior changes.

## Rollout Plan

1. Add `PDInputControlFrame`.
2. Add `PDCalculatorSelectorRow`.
3. Add the `UIConfig.useInputControlFrame` rollback flag.
4. Adapt `PDTextField` and `PDSwitchField` internally behind the flag.
5. Migrate the Volume selector/reset row first.
6. Migrate the TCI selector/reset row second.
7. Verify screenshots and runtime logs.
8. Migrate remaining screens after Volume and TCI are stable.
9. Remove old rendering branches and helper-text workarounds only after all calculator screens are stable.

## Verification Plan

Run targeted analyzer checks for changed files.

Verify these screen sizes:

- 375x812
- 430x932
- 768x1024
- 1024x768
- 1280x720

Manual checks:

- Selector error appears without moving selector, reset button, or rows below.
- Text-field error appears without moving the text field, adjacent controls, or rows below.
- Switch status appears without moving the switch, adjacent controls, or rows below.
- Reset button remains square and aligned with selector control area.
- Plus/minus tap behavior is unchanged.
- Long-press repeat behavior is unchanged.
- Switch toggle behavior is unchanged.
- Calculate/reset callbacks are unchanged.

Runtime log checks:

- No `RenderFlex overflowed` errors.
- No assertion failures.
- No disposed-controller errors.
- No Flutter compile errors.

## Cleanup Phase

Cleanup happens after the migration is stable.

Cleanup tasks:

- Remove obsolete old rendering branches.
- Remove `helperText: ''` geometry workarounds.
- Remove unused helper/error styling that moved into `PDInputControlFrame`.
- After all calculator screens are migrated and verified, remove `UIConfig.useInputControlFrame` and the old rendering branches in the same cleanup phase.
- Update docs to mark `PDInputControlFrame` as the canonical input geometry system.

## Success Criteria

- `PDInputControlFrame` is the single geometry contract for PD input controls.
- `PDCalculatorSelectorRow` prevents selector/reset overflow and alignment drift.
- Errors/status text do not move controls or downstream rows.
- Status text is relevant, compact, and constrained to the owning control.
- Volume and TCI keep existing calculation behavior.
- The migration can be rolled back by changing a `UIConfig` flag.
