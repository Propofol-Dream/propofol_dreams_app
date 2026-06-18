# AGENTS.md — Propofol Dreams

## Current State (v3.0.8+131)

### Widgets
- `PKField` (`lib/components/pk_field.dart`) — M3 TextField + ± pill-steppers, long press repeat, highlight flash, `hasError` param
- `SwitchField` (`lib/components/switch_field.dart`) — M3 TextField + Switch, toggle highlight flash
- `Selector<T>` (`lib/components/selector.dart`) — generic `TextField` + `showModalBottomSheet` (not `DropdownMenu` — overflows on mobile). Replaces old `SelectorRow`.
- `InfusionRateChart` (`lib/components/infusion_rate_chart.dart`) — extracted StatefulWidget with hover state, tooltip, wall-clock time support

### Screens
- **Volume** (`lib/screens/volume_screen.dart`): PKField/SwitchField/Selector<Model>, ~650 lines calculation logic preserved. Mobile: fixed-bottom input panel. Desktop: RHS 393px panel.
- **TCI** (`lib/screens/tci_screen.dart`): PKField (age/height/weight/target), SwitchField (sex), Selector<Drug> (deduplicated by displayName, concentration resolved from Settings). Start time in target row. Chart, dashboard cards, patient chips. 240 min duration. Debounced auto-calculation.
- **Home** (`lib/screens/home_screen.dart`): Custom 72px Column-based nav rail (no logo icon, no trailing, no divider). Mobile: NavigationBar. AppBar removed.
- **EleMarsh** (`lib/screens/elemarsh_screen.dart`): Not yet migrated to new widgets.

### Nav Rail (Desktop)
- Custom Column-based, 72px wide, flush with screen edge (outside max-width constraint)
- `CrossAxisAlignment.stretch` with `horizontal: 8` padding on items
- Selected item: `secondaryContainer` background, `BorderRadius.circular(16)`
- No logo icon, no trailing settings icon, no divider

### Colors
- Theme via `ThemeData(colorScheme: MaterialTheme.{light,darkScheme}())` (no `useMaterial3: true`)
- PKField/SwitchField/Selector fill: `onPrimary` (white, not `surfaceContainerHighest`)

### Drug Handling (TCI)
- `Selector<Drug>` shows unique drug names only (deduplicated by `displayName`)
- Concentration resolved via `settings.getCurrentDrugVariant(displayName)` before calculation
- `_selectedDrug` is display-only; `resolvedDrug` used for calculation and chip display

## Key Gotchas
- `DropdownMenu` has ~192px minimum width, overflows on mobile. Use `TextField` + `showModalBottomSheet` instead
- `readOnly` TextField mutes colors — use explicit `style: TextStyle(color: theme.colorScheme.onSurface)`
- `useMaterial3: true` changes color scheme — don't set it without updating all token references
- `Spacer` competes with `Expanded` for flex space — use only one per flex direction
- NavigationRail has hardcoded 12px internal padding — use custom Column-based rail for full control
- `_wrapWithWebMaxWidth` centers content in 1440px — nav rail must be outside this wrapper to sit at screen edge
- `Selector<T>` conflicts with provider's `Selector` — use `hide Selector` on `import 'package:provider/provider.dart'`
- `Drug.toString()` returns `displayName` — use `displayWithConcentration` to distinguish variants

## Pushed Commits
- `04f9580` — replace DropdownMenu with TextField+ModalBottomSheet, fix gap 12px
- `eea8e34` — fix selector_row colors/height/width match PKField, Spacer for reset button
