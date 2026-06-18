# Volume Screen Rewrite

## Goal
Replace the old frame-based input system (PDInputControlFrame, PDCalculatorSelectorRow, etc.) with lean M3-native primitives (PKField, SwitchField, SelectorRow) and rebuild the volume screen layout with a fixed-bottom input panel (mobile) / RHS side sheet (tablet/desktop).

## Requirements

### Layout
- **Mobile**: Fixed-bottom input panel pinned to bottom. Results scroll above. Result label + arrow pinned just above input panel border. Data table expands between label and input via `AnimatedSize` (300ms `fastOutSlowIn`).
- **Tablet/Desktop**: RHS fixed side panel (393px wide, matching iPhone 17 viewport). Results on left with result label at top (60px, no shrink), table fills remaining height. No arrow — table always visible. `SafeArea` wrapping.
- **Landscape only** for tablet/desktop layouts.

### Input Panel
- Always visible (no collapse/expand).
- Error text consolidated at top of panel in a fixed 48px reserved-height container (no layout shift when errors appear/disappear).
- Fields show red border on error (via PKField's `hasError` param).
- All inter-field gaps: `kSp12` (12px).
- Content padding: 16px horizontal, 12px vertical.

### Row Structure (Model Selector + Adult/Paed Switch + Reset Button)
```
Row
├── Expanded
│   └── Container
│       └── Row
│           ├── Expanded → SelectorRow (DropdownMenu)
│           ├── SizedBox(width: 4)
│           └── Container(48px, bordered, surfaceContainerHighest bg)
│               └── Row(mainAxisSize: min)
│                   ├── Icon(face/child, 18px)
│                   ├── SizedBox(width: 6)
│                   ├── Text("Adult"/"Paed")
│                   ├── SizedBox(width: 2)
│                   └── Switch
├── SizedBox(width: 12)
└── SizedBox(48×48) → ElevatedButton(reset icon)
```

- Selector-to-switch gap: **4px** (closer than switch-to-reset gap of 12px).
- Switch must be tappable on mobile (not covered by DropdownMenu overflow).
- Adult/paed toggle saves current view's values to Settings, switches `inAdultView`, restores other view's values, and recalculates.

### Widgets
- **PKField**: M3 TextField + ± pill-stepper buttons inside border. Long press repeats at 80ms. Tap triggers 200ms highlight flash on field border. `hasError` param for external error styling.
- **SwitchField**: M3 TextField + Switch. Toggle triggers 200ms highlight flash. Switch nudged 2px down to align with PKField pill icons.
- **SelectorRow**: DropdownMenu only (no reset button). No leading icon. Dense padding on mobile.

### Navigation
- Mobile: M3 NavigationBar.
- Tablet/Desktop: M3 NavigationRail with `selectedIcon`, `indicatorColor`, leading app icon, trailing settings button.
- Version display (`v3.0.8+130`) at bottom-right of status bar.

### Deletions
- Remove: PDInputControlFrame, PDCalculatorSelectorRow, PDLabel, PDStyledLabel, PDAdvancedSegmentedControl, AdaptiveTextField, AdaptiveDropdown, M3TextField, AdaptiveLayout, CollapsibleInputCard, InputSummaryDisplay.
- Remove: `UIConfig.useInputControlFrame` and related feature flags.

## Adult/Paed Switch Issue

### Problem
The adult/paed Switch is not tappable on mobile because the DropdownMenu overflows its `Expanded` constraint and paints over the switch.

### Root Cause
`DropdownMenu` has a minimum intrinsic width (~192px) that exceeds the available space on mobile (~157px after accounting for the switch container + reset button + gaps). The `Expanded` widget constrains the DropdownMenu's layout width, but the DropdownMenu ignores this and paints at its natural width, covering the switch.

### Approaches Tried

| # | Approach | Result |
|---|----------|--------|
| 1 | `Expanded` wrapping SelectorRow | Switch not visible (covered by DropdownMenu) |
| 2 | `ClipRect` around SelectorRow | No change — ClipRect clips paint but DropdownMenu still takes layout space |
| 3 | `Flexible(fit: FlexFit.loose)` | DropdownMenu takes natural width, pushes switch off-screen |
| 4 | `OverflowBox(maxWidth: constraints.maxWidth)` | Input panel blank (brackets broken) |
| 5 | `SizedBox(width: constraints.maxWidth) + ClipRect` | Input panel blank (brackets broken) |
| 6 | `FittedBox(fit: BoxFit.scaleDown)` | Scales DropdownMenu to fit — switch visible and tappable |
| 7 | Remove leading icon from SelectorRow | Reduced minimum width but still overflows |
| 8 | `isDense: true` + reduced padding (8px) | Reduced minimum width but still overflows |
| 9 | Swap order (switch first, DropdownMenu after) | Works but order is wrong (user wants dropdown first) |

### Current Solution
`FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` wrapping the `SelectorRow` inside `Expanded`. This scales the DropdownMenu down to fit the available width on narrow screens while keeping it left-aligned.

### Remaining Issues
- `FittedBox` scales the entire DropdownMenu including text, which may make model names hard to read on very narrow screens.
- A better long-term solution would be to use a compact dropdown widget that respects tight width constraints natively.

### Recommended Fix
Use `DropdownMenu.expandedInsets: EdgeInsets.zero` in `SelectorRow`, then remove the `FittedBox` wrapper from the model selector in `volume_screen.dart`.

This is the smallest clean fix because Flutter's `DropdownMenu` documents that `expandedInsets: EdgeInsets.zero` makes the text field match its parent width instead of sizing from the widest menu item. That addresses the root cause directly: the dropdown should stop painting over the adult/paed switch, while preserving normal text size and the requested dropdown-first row order.

Implementation shape:

```dart
return DropdownMenu<Model>(
  expandedInsets: EdgeInsets.zero,
  initialSelection: selectedModel,
  ...
);
```

Then replace the `FittedBox`-wrapped `SelectorRow` in `volume_screen.dart` with the plain `SelectorRow` inside the existing `Expanded`.

Verification required:
- Run `flutter analyze`.
- Test the narrow mobile layout and confirm the adult/paed switch is visible and tappable.
- Confirm the selected model text remains readable without scaling.

Fallback if target SDK does not support `expandedInsets` or the behavior still overflows: replace `SelectorRow` with a compact `MenuAnchor`-based selector that uses the parent's tight width natively. Do not keep `FittedBox` as the long-term solution.

Related cleanup, separate from the switch bug: `SelectorRow` currently creates a `TextEditingController` during every build. Avoid bundling that cleanup into this patch unless selector behavior is being refactored more broadly.

Open compatibility check: local Flutter reports `3.44.2`, while project docs mention `3.32.7`. Confirm the actual release/CI SDK supports `DropdownMenu.expandedInsets` before landing this as the primary fix.

## Version History
- v3.0.8+128: Initial volume screen rewrite
- v3.0.8+129: Error panel fix, SwitchField alignment, SelectorRow cleanup
- v3.0.8+130: Adult/paed toggle, result label layout, tablet/desktop layouts, version display
