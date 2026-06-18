# PKField Design

## Purpose

Replace the frame-based input layout system (`PDInputControlFrame` + `PDCalculatorSelectorRow` + flags) with lean M3-native widgets. The new architecture has three primitives — `PKField`, `SwitchField`, `SelectorRow` — and no frame, no status lanes, no rollback flags, no dead PD widgets.

## Design Principles

- Use native M3 components directly; no wrapper frames.
- Reserve space for error text once (2px gap, 11px font) so it never shifts layout.
- ± buttons are secondary input; tap-to-type is primary.
- No scrub/drag/wheel gestures — unsuitable for medical/glove use.
- No `useInputControlFrame`, `m3Style`, `height`, `statusText`/`statusType` parameters.
- Dead PD widgets are removed, not deprecated.

## Component: PKField

M3 `TextField` with ± pill-stepper buttons inside the border, right-aligned. Replaces `PDTextField`.

```
┌──────────────────────────────────────┐
│  [📅]  Age                   35 − +  │
└──────────────────────────────────────┘
                                 ↑ error 2px gap
```

### API

```dart
class PKField extends StatelessWidget {
  const PKField({
    super.key,
    this.prefixIcon,
    required this.labelText,
    required this.controller,
    required this.interval,
    required this.fractionDigits,
    required this.range,  // [min, max]
    this.onChanged,
    this.enabled = true,
  });
}
```

### Parameters

| Param | Type | Notes |
|-------|------|-------|
| `prefixIcon` | `IconData?` | Optional icon before label |
| `labelText` | `String` | Floating label |
| `controller` | `TextEditingController` | Value binding |
| `interval` | `double` | ± step size (0.5, 1, 5, 10) |
| `fractionDigits` | `int` | Decimal places for display |
| `range` | `List<num>` | `[min, max]` inclusive |
| `onChanged` | `VoidCallback?` | Called on ± tap or text submit |
| `enabled` | `bool` | Default `true` |

### Structure

```
SizedBox(height: responsive56/60/64)
  Stack
    ├── M3 TextField (fill: surfaceContainerHighest)
    │     └── OutlineInputBorder(radius: 8)
    │     └── prefixIcon → prefixIcon
    │     └── label → labelText
    │     └── floatingLabelBehavior → always
    └── Positioned(right: 0, top: 4, bottom: 4)
          └── Row
                ├── − button (44×44, radius: 6)
                └── + button (44×44, radius: 6)
```

### Button layout

- ± buttons inside the TextField border on the right edge.
- Each button: 44×44, radius 6px, hover highlight.
- + enabled only when `value + interval <= range[1]`.
- − enabled only when `value - interval >= range[0]`.
- Buttons are inert (no `onPressed` callback from the text field — tap-to-type is primary).
- On ± tap: read current value → clamp → set formatted text → call `onChanged`.

### Error rendering

Reserved error space 2px below field, 11px `labelSmall` weight 500. Reserved unconditionally at 16px height (below `SizedBox`). When no error, slot is empty and height is 0 (or 16px with no visible content — need to decide). Use `SizedBox(height: 0)` when no error, `SizedBox(height: 16)` when error; parent must allocate space statically if we want zero layout shift. Since we want zero layout shift, the parent `Column` should use a fixed gap between fields, and each field renders its error text inside a `SizedBox(height: 16)` whether visible or empty — this is how the "reserved space" works without a frame.

### States

- **Normal**: Fill `surfaceContainerHighest`, border `outline` (1px).
- **Focused**: Border `primary` (2px), label `primary` color.
- **Error**: Border `error` (1px), icon/label/text `error` color, error text below.
- **Disabled**: Fill `surfaceContainerHigh` (lower), border `outline` (0.5px), buttons disabled.

### Removed from PDTextField

`helperText`, `m3Style`, `useInputControlFrame`, `height`, `timer`, `onLongPressStart`/`onLongPressEnd`, `hideButtons`.

## Component: SwitchField

M3 `TextField`-themed container with `Switch` on the right. Replaces `PDSwitchField`.

```
┌──────────────────────────────────────┐
│  [♀]  Sex              Female    🔘  │
└──────────────────────────────────────┘
```

### API

```dart
class SwitchField extends StatelessWidget {
  const SwitchField({
    super.key,
    this.prefixIcon,
    required this.labelText,
    required this.controller,
    required this.switchLabels,  // [labelFalse, labelTrue]
    this.onChanged,
    this.enabled = true,
  });
}
```

### Structure

```
SizedBox(height: responsive56/60/64)
  Stack
    ├── M3 TextField (fill: surfaceContainerHighest, readOnly)
    │     └── OutlineInputBorder(radius: 8)
    │     └── prefixIcon
    │     └── label → labelText
    │     └── text → switchLabels[value]
    └── Positioned(right: 12, top: 0, bottom: 0, centerY)
          └── Switch(value, onChanged)
```

### Removed from PDSwitchField

`useInputControlFrame`, `height`, `helperText`.

## Component: SelectorRow

`M3DropdownMenu` + reset button in a Row. Uses the existing `M3DropdownMenu` (already M3-native wrapper around Flutter's `DropdownMenu<Model>`).

```
┌────────────────────────────────────┬───┐
│  [◉]  Model: Schnider          ﹀  │ ↺ │
└────────────────────────────────────┴───┘
```

### API

```dart
class SelectorRow extends StatelessWidget {
  const SelectorRow({
    super.key,
    this.prefixIcon,
    required this.labelText,
    required this.selectedModel,
    required this.models,
    required this.onModelSelected,
    required this.onReset,
    this.enabled = true,
  });
}
```

### Structure

```
Row(spacing: 8)
  ├── Expanded
  │     └── M3DropdownMenu (responsiveHeight, maxWidth: selectorMaxWidth)
  └── SizedBox(width: responsiveHeight, height: responsiveHeight)
        └── IconButton(reset)
```

No frame. No status lane. No `PDInputControlFrame`. Errors related to model/drug selection are surfaced via PKField error texts on the relevant input fields (since those are the actionable fields for the user). If no field is relevant, they appear as a static `Text` row below the form.

### Removed from PDCalculatorSelectorRow

Everything — this component replaces it.

## Input Form Layout

The form layout on Volume and TCI screens uses a `Column` with fixed 12px gaps. Fields are paired in `Row(spacing: 8)`.

```
Column(gap: 12)
  ├── SelectorRow (model)
  ├── FieldRow(SwitchField, PKField)       ← Sex + Age
  ├── FieldRow(PKField, PKField)            ← Height + Weight
  └── FieldRow(PKField, PKField)            ← Target + Duration
```

Fields in a row share remaining width equally after spacing. Each field is `Expanded`.

The error text 2px below each field is inside a `SizedBox(height: 16)` (reserved, empty when no error). This guarantees zero layout shift when errors appear.

## Screens Impacted

### volume_screen.dart

Current state: uses `PDInputControlFrame`, `PDCalculatorSelectorRow`, `PDTextField`, `PDSwitchField`, `UIConfig.useInputControlFrame` flag.

Target:
- Remove `PDCalculatorSelectorRow` → `SelectorRow`.
- Remove `PDTextField` → `PKField`.
- Remove `PDSwitchField` → `SwitchField`.
- Remove `UIConfig.shouldUseInputControlFrame` and all frame/status wiring.
- Remove all `statusText`/`statusType`/`useInputControlFrame` props.
- Keep the existing form field layout (model row, then 4 input rows) with the new widgets.
- Temporary error samples removed.

### tci_screen.dart

Current state: uses `PDCalculatorSelectorRow`, `PDTextField`, `PDSwitchField`, `UIConfig.useInputControlFrame` flag.

Target: same migration as volume.

### home_screen.dart

No changes (bottom nav, not an input form).

### elemarsh_screen.dart

Check if it uses any of the removed widgets.

### settings_screen.dart

Check if it uses any of the removed widgets.

## Dead Code Removal

### Files to delete

- `lib/components/PDInputControlFrame.dart`
- `lib/components/PDCalculatorSelectorRow.dart`
- `lib/components/adaptive_dropdown.dart`
- `lib/components/adaptive_text_field.dart`
- `lib/components/adaptive_layout.dart`
- `lib/components/material3/m3_text_field.dart`
- `lib/components/legacy/PDLabel.dart`
- `lib/components/legacy/PDStyledLabel.dart`
- `lib/components/legacy/PDAdvancedSegmentedControl.dart`

### Files to replace

- `lib/components/legacy/PDTextField.dart` → new `lib/components/pk_field.dart`
- `lib/components/legacy/PDSwitchField.dart` → new `lib/components/switch_field.dart`

### Config changes

- `lib/config/ui_config.dart`: remove `useInputControlFrame`, `shouldUseInputControlFrame()`, `getMigrationStatus()`. The `components` map and `_emergencyFallback` can be removed entirely unless used for other flags.

### Test files

- `test/pd_input_control_frame_test.dart` → delete

### Widgets to keep

- `lib/components/material3/m3_dropdown_menu.dart` — still used by SelectorRow.
- `lib/components/adaptive_dropdown.dart` — delete if the only consumer was `PDCalculatorSelectorRow`.
- `lib/widgets/` — review for any dead PDLabel/PDStyledLabel refs.

## Removed Parameters Summary

Removed from every input widget:

| Removed | Reason |
|---------|--------|
| `useInputControlFrame` | No frame system |
| `m3Style` | Only M3 path now |
| `height` | Responsive is built-in |
| `statusText`/`statusType` | No status lane |
| `hideButtons` | PKField always shows buttons |
| `timer`/`onLongPressStart`/`onLongPressEnd` | No long-press repeat |
| `helperText` | Use error slot or clear |

## Verification Plan

```
flutter test test/pk_field_test.dart   # proposed
flutter analyze
```

Manual:
- Volume form: tap ± on each field, verify value changes, range clamping, error display.
- TCI form: same.
- Paired fields: two PKFields in a Row align at same height.
- Error text: appears/disappears without shifting layout.
- SwitchField: tap toggles value, label updates.
- SelectorRow: dropdown opens, model selection triggers calculation, reset works.
- Disabled state: fields + buttons respect `enabled = false`.

No `RenderFlex overflowed`, no disposed-controller errors, no assertion failures.

## Rollout Plan

1. Build `PKField`, `SwitchField`, `SelectorRow` as new widgets (parallel to old).
2. Rewrite Volume screen input form using new widgets.
3. Rewrite TCI screen input form using new widgets.
4. Delete dead PD files.
5. Run `flutter analyze` and `flutter test`.
6. Manual QA on Volume and TCI screens.

No rollback flag. The old widgets are deleted, not deprecated. If a regression surfaces, fix forward.
