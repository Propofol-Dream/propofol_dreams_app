# M3 UI Migration Spec — Screen by Screen

**Principle:** Replace legacy PD components with Flutter-native Material 3 widgets.
Zero changes to calculation logic, settings persistence, or screen interaction behavior.
Each screen is migrated independently with the old version kept as fallback.

---

## Component Replacement Map

| Legacy Component | M3 Replacement | Flutter Widget | Preserves +/- steppers? |
|---|---|---|---|
| `PDTextField` | M3 TextField | `TextField` with M3 decoration | **No** — steppers removed |
| `PDTextField` (with steppers needed) | `M3TextField` wrapper | Wraps PDTextField with M3 Theme | **Yes** — keeps PDTextField base |
| `PDSegmentedControl` | M3 SegmentedButton | `SegmentedButton<T>` | N/A |
| `PDSwitchField` | M3 Switch | `Switch.adaptive` with theming | N/A |
| `PDModelSelectorModal` | M3 DropdownMenu | `DropdownMenu<Model>` | N/A |
| `PDLabel` / `PDStyledLabel` | M3 Typography | `Text` with `textTheme` styles | N/A |
| Manual `UIHeight` calc | M3 intrinsic sizing | Removed — M3 self-sizes | N/A |

### Key Decision: PDTextField ↔ M3TextField vs plain TextField

**Use `M3TextField` wrapper** (preserves PDTextField base with M3 Theme wrapping) for inputs that currently have +/- stepper buttons. **Use native `TextField`** for inputs that don't need steppers.

For Phase 1 (Settings) and Phase 2 (Duration), the pump rate, weight, and infusion rate fields currently use `PDTextField` with steppers. However, these fields are typically typed manually. **Decision required:** Keep steppers via `M3TextField` or drop them with native `TextField`?

---

## Screen-by-Screen Migration Order

```
Phase 0: Theme Foundation (M3 theme additions only)
Phase 1: Settings Screen    ← SIMPLEST, isolated logic
Phase 2: Duration Screen    ← SMALL, table + inputs
Phase 3: Volume Screen      ← MEDIUM, model selector + table
Phase 4: TCI Screen         ← LARGE, multi-drug TCI
Phase 5: EleMarsh Screen    ← LARGEST, dual-mode
Phase 6: Volume Plus/RT     ← NEWER, already partial M3
```

---

## Phase 0: Theme Foundation

### 0.1 Update M3 theme with component themes
- Current `theme.dart` has `useMaterial3: true` and generated `ColorScheme` but no component-specific themes.
- Add `SegmentedButtonThemeData` and `DropdownMenuThemeData` to `ThemeData`:
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: colorScheme,
  // ... existing
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
)
```

### 0.2 Remove junk files
- Delete `lib/screens/test_screen_label.dart.bakcup`
- Delete `test/trial_test.dart.backup`

### 0.3 (Deferred) Risky items moved to later phases
The following were considered for Phase 0 but deferred to avoid touching unmigrated screens:
- ❌ **Breakpoint unification** — affects all screens. Do per-screen during migration.
- ❌ **PDSwitchField controller lifecycle fix** — only used by unmigrated screens (TCI, EleMarsh, VolumePlus, Realtime). Fix during those phases.
- ❌ **UIConfig dead code removal** — inert, not blocking. Clean up after all screens migrated.

---

## Phase 1: Settings Screen (`settings_screen.dart`)

### Current Components
- `PDSegmentedControl` × 5 (theme, propofol conc, remifentanil conc, remimazolam conc, volume mode)
- `PDTextField` × 1 (pump rate, has +/- buttons)
- `_buildDrugConcentrationSection()` custom helper
- `PDSegmentedController` × 5
- `UIHeight` calculation based on aspect ratio + screen height

### M3 Replacement Plan

#### 1.1 Theme selector
**Before:**
```dart
PDSegmentedControl(
  fitWidth: true, fitHeight: true, fontSize: 16,
  defaultColor: Theme.of(context).colorScheme.primary,
  defaultOnColor: Theme.of(context).colorScheme.onPrimary,
  labels: ['Light', 'Dark', 'Auto'],
  segmentedController: themeController,
  onPressed: [() => settings.themeModeSelection = ThemeMode.light, ...],
)
```

**After:**
```dart
SegmentedButton<ThemeMode>(
  segments: const [
    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_brightness)),
  ],
  selected: {settings.themeModeSelection},
  onSelectionChanged: (Set<ThemeMode> selected) {
    if (selected.length == 1) {  // Guard: tap on selected item sends empty set
      settings.themeModeSelection = selected.first;
    }
  },
)
```

**⚠️ Edge case:** `SegmentedButton` fires `onSelectionChanged` with an **empty set** when the user taps an already-selected segment. Must guard with `if (selected.length == 1)`.

**Visual difference:** `PDSegmentedControl` uses custom 5px border radius per-corner. `SegmentedButton` uses M3 default border radius (~12px outer, 8px inner). The appearance will differ — this is expected.

#### 1.2 Drug concentration selectors
**Current behavior (must preserve):**
- Propofol: 2 options (`10 mg/mL`, `20 mg/mL`) → segmented control
- Remifentanil: 3 options (`20 mcg/mL`, `40 mcg/mL`, `50 mcg/mL`) → segmented control
- Dexmedetomidine: 1 option (`4 mcg/mL`) → display-only container with primary color background
- Remimazolam: 2 options (`1 mg/mL`, `2 mg/mL`) → segmented control

**M3 approach:**
```dart
// Format helper — matches current code: "10 mg/mL" (no decimal for round numbers)
String _fmt(double c, Drug d) =>
    '${c.toStringAsFixed(c == c.roundToDouble() ? 0 : 1)} ${d.concentrationUnit.displayName}';

// For multi-option drugs (Propofol, Remifentanil, Remimazolam):
SegmentedButton<String>(
  segments: availableVariants.map((v) =>
    ButtonSegment(
      value: v.concentration.toString(),
      label: Text(_fmt(v.concentration, drug)),
    ),
  ).toList(),
  selected: {currentConcentration.toString()},
  onSelectionChanged: (Set<String> selected) {
    if (selected.length == 1) {
      final conc = double.parse(selected.first);
      settings.setDrugConcentration(drug, conc);
      setState(() {});
    }
  },
)

// For single-option drugs (Dexmedetomidine): keep display-only container
Container(
  padding: ...,
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(_fmt(currentConcentration, drug), style: ...),
)
```

**⚠️ Edge case:** Match current concentration formatting — `toStringAsFixed(0)` for whole numbers ("10"), not plain `toString()` ("10.0"). Also preserve `availableConcentrations.length > 1` branching — don't show `SegmentedButton` with one segment.

#### 1.3 Pump rate field
**Option A — Keep steppers (safest, use M3TextField wrapper):**
```dart
M3TextField(
  prefixIcon: Icons.settings_input_component_outlined,
  labelText: 'Pump Rate (mL/hr)',
  interval: 50,
  fractionDigits: 0,
  controller: pumpController,
  onPressed: () { /* save */ },
  range: const [0, 1500],
)
```
This wraps `PDTextField` with M3 theme. Preserves all behavior including +/- buttons, long-press, validation text.

**Option B — Native TextField (steppers removed):**
```dart
TextField(
  controller: pumpController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    prefixIcon: Icon(Icons.settings_input_component_outlined),
    labelText: 'Pump Rate (mL/hr)',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
  ),
  onChanged: (_) { /* save */ },
)
```
Loses stepper buttons. Simpler but behavior change.

**Recommendation:** Use **Option A (M3TextField)** for Phase 1 to guarantee zero behavior change. Can simplify to native `TextField` later if desired.

#### 1.4 Volume mode selector
Same pattern as theme selector:
```dart
SegmentedButton<VolumeMode>(
  segments: const [
    ButtonSegment(value: VolumeMode.Volume, label: Text('Volume')),
    ButtonSegment(value: VolumeMode.VolumePlus, label: Text('Volume Plus')),
  ],
  selected: {settings.volumeMode},
  onSelectionChanged: (Set<VolumeMode> selected) {
    if (selected.length == 1) {
      settings.volumeMode = selected.first;
    }
  },
)
```

#### 1.5 Import changes
**Removed imports:**
```dart
import 'package:propofol_dreams_app/components/legacy/PDTextField.dart';
import 'package:propofol_dreams_app/components/legacy/PDSegmentedController.dart';
import 'package:propofol_dreams_app/components/legacy/PDSegmentedControl.dart';
```

**Added imports:**
```dart
import 'package:propofol_dreams_app/components/material3/m3_text_field.dart';
```

No new imports needed for `SegmentedButton` — it's part of `package:flutter/material.dart` (already imported).

#### 1.6 Structure changes
- Remove `PDSegmentedController` (5 instances) — `SegmentedButton` tracks its own selection via `selected` set
- Remove `PDSegmentedControl` imports
- Remove `UIHeight` local variable — M3 components self-size
- Remove `SizedBox(height: UIHeight)` wrappers around segmented controls
- Keep layout: `Column → AppBar → Expanded → ListView`
- Keep section spacing: `SizedBox(height: 24)` between sections
- Keep `horizontalSidesPaddingPixel` for ListView padding

### Verification Checklist
- [ ] Theme toggle cycles Light/Dark/System, immediate visual change
- [ ] Theme persisted across app restart
- [ ] Propofol concentration switch saves and affects Volume/TCI calculations
- [ ] Remifentanil concentration switch persists
- [ ] Remimazolam concentration switch persists
- [ ] Dexmedetomidine shows display-only container (primary color bg)
- [ ] Pump rate saves via onChanged (native) or onPressed (M3TextField)
- [ ] Volume Mode toggle switches between Volume/VolumePlus screens
- [ ] All SharedPreferences keys identical to before
- [ ] Dexmedetomidine container visual matches: primary color bg, white text, centered

---

## Phase 2: Duration Screen (`duration_screen.dart`)

### Current Components
- `PDTextField` × 2 (weight, infusion rate — both have +/- buttons)
- `PDSegmentedControl` × 1 (infusion unit selector)
- `DurationDataTable` from `infusion_regime_table.dart`
- `PDSegmentedController` × 1
- `UIHeight` calculation
- `LayoutBuilder` + `SingleChildScrollView` + `IntrinsicHeight`

### M3 Replacement Plan

#### ⚠️ Critical: PDSegmentedController removal impact

The Duration screen uses `infusionUnitController.val` in **6 locations**:
1. `_setControllersFromSettings()` — initial value
2. `updateInfusionUnit()` — read new unit + set decimal places
3. `build()` — `infusionRateDecimal` calculation
4. `build()` — `weightTextFieldEnabled` flag
5. `build()` — dynamic label text for infusion rate field
6. `run()` — `InfusionUnit infusionUnit = infusionUnits[infusionUnitController.val]`

**Solution:** Replace all `infusionUnitController.val` references with `settings.infusionUnit` (which is `context.watch<Settings>()`-ed in build). The `updateInfusionUnit()` method is inlined into the `SegmentedButton` callback — no more controller-based indirection.

**Before (PDSegmentedController):**
```dart
void updateInfusionUnit() {
    InfusionUnit previous = settings.infusionUnit;
    InfusionUnit current = infusionUnits[infusionUnitController.val];
    infusionRateDecimal = ...infusionUnitController.val...;
    // conversion logic...
    settings.infusionUnit = current;
    run();
}
```

**After (SegmentedButton):**
```dart
// In SegmentedButton.onSelectionChanged:
onSelectionChanged: (Set<InfusionUnit> selected) {
    if (selected.length == 1) {
        final newUnit = selected.first;
        final oldUnit = settings.infusionUnit;
        
        // Recalculate decimal place count
        infusionRateDecimal = newUnit == InfusionUnit.mg_kg_hr ? 1
            : newUnit == InfusionUnit.mcg_kg_min ? 0 : 1;
        
        // Convert value if units changed
        if (oldUnit != newUnit && weight != null && infusionRate != null) {
            settings.infusionRate = convertInfusionRate(
                weight: weight,
                infusionRate: infusionRate,
                previous: oldUnit,
                current: newUnit,
            );
            infusionRateController.text =
                settings.infusionRate!.toStringAsFixed(infusionRateDecimal);
        }
        
        settings.infusionUnit = newUnit;
        run();
    }
}
```

**All references replaced:**
| Location | Old Code | New Code |
|---|---|---|
| `build()` − `infusionRateDecimal` | `infusionUnits[infusionUnitController.val]` | `settings.infusionUnit` |
| `build()` − `weightTextFieldEnabled` | `infusionUnits[infusionUnitController.val]` | `settings.infusionUnit` |
| `build()` − dynamic label | `[mg/kg/h, mcg/kg/min, mL/hr][infusionUnitController.val]` | `settings.infusionUnit.toString()` |
| `build()` − interval | `infusionUnits[infusionUnitController.val]` | `settings.infusionUnit` |
| `run()` − unit param | `infusionUnits[infusionUnitController.val]` | `settings.infusionUnit` |
| `_setControllersFromSettings` | `infusionUnitController.val = ...` | **removed entirely** (SegmentedButton reads from settings) |
| Method call | `updateInfusionUnit()` | **inlined** into SegmentedButton callback |

#### 2.1 Weight field
**Recommendation:** Use `M3TextField` (preserves steppers).

```dart
M3TextField(
  prefixIcon: Icons.monitor_weight_outlined,
  labelText: '${AppLocalizations.of(context)!.weight} (kg)',
  controller: weightController,
  fractionDigits: 0,
  interval: 1,
  onPressed: updateWeight,
  enabled: settings.infusionUnit != InfusionUnit.mL_hr,
  range: const [0, 250],
)
```

#### 2.2 Infusion rate field
**Recommendation:** Use `M3TextField` (preserves steppers).

```dart
M3TextField(
  prefixIcon: Icons.water_drop_outlined,
  labelText: '${AppLocalizations.of(context)!.infusionRate} (${settings.infusionUnit.toString()})',
  controller: infusionRateController,
  fractionDigits: settings.infusionUnit == InfusionUnit.mg_kg_hr ? 1
      : settings.infusionUnit == InfusionUnit.mcg_kg_min ? 0 : 1,
  interval: settings.infusionUnit == InfusionUnit.mg_kg_hr ? 0.5
      : settings.infusionUnit == InfusionUnit.mcg_kg_min ? 10 : 1,
  onPressed: updateInfusionRate,
  range: const [1, 9999],
)
```

**Note:** The label and interval now update reactively because `settings` is obtained via `context.watch<Settings>()` in `build()`, triggering a rebuild when infusion unit changes.

#### 2.3 Infusion unit selector
```dart
SegmentedButton<InfusionUnit>(
  segments: const [
    ButtonSegment(value: InfusionUnit.mg_kg_hr, label: Text('mg/kg/h')),
    ButtonSegment(value: InfusionUnit.mcg_kg_min, label: Text('mcg/kg/min')),
    ButtonSegment(value: InfusionUnit.mL_hr, label: Text('mL/hr')),
  ],
  selected: {settings.infusionUnit},
  onSelectionChanged: (Set<InfusionUnit> selected) {
    if (selected.length == 1) {
      final newUnit = selected.first;
      final oldUnit = settings.infusionUnit;
      final int? weight = int.tryParse(weightController.text);
      final double? infusionRate = double.tryParse(infusionRateController.text);
      
      infusionRateDecimal = newUnit == InfusionUnit.mg_kg_hr ? 1
          : newUnit == InfusionUnit.mcg_kg_min ? 0 : 1;
      
      if (oldUnit != newUnit && weight != null && infusionRate != null) {
        settings.infusionRate = convertInfusionRate(
          weight: weight,
          infusionRate: infusionRate,
          previous: oldUnit,
          current: newUnit,
        );
        infusionRateController.text =
            settings.infusionRate!.toStringAsFixed(infusionRateDecimal);
      }
      
      settings.infusionUnit = newUnit;
      run();
    }
  },
)
```

**Critical:** The `updateInfusionUnit()` method is **deleted**. Its logic is now inside the `SegmentedButton` callback. All calculation logic (`convertInfusionRate()`, `calculate()`, `run()`) stays unchanged.

#### 2.4 M3TextField height behavior
The current code wraps `PDTextField` in `SizedBox(height: UIHeight + 24)`. The `+24` reserves space for helper/error text. `M3TextField` uses its own responsive height calculation (56-88px depending on screen width/text scale).

**Approach:** Remove `SizedBox(height: UIHeight + 24)` wrapper for M3TextField. Let it self-size via internal `_getResponsiveHeight()`. The `+24` error text space is handled by the `TextField` decoration internally. If visual height is noticeably different, revert to using `M3TextField(height: UIHeight + 24)` to match exactly.

#### 2.5 Table
Keep `DurationDataTable` as-is. It already uses `Theme.of(context).colorScheme` for theming.

### Verification Checklist
- [ ] Weight input enabled/disabled matches unit selection (disabled for mL/hr)
- [ ] Weight stepper (+/-) buttons work
- [ ] Infusion rate decimal places match unit (1dp for mg/kg/h, 0dp for mcg/kg/min, 1dp for mL/hr)
- [ ] Infusion rate stepper interval matches unit (0.5/10/1)
- [ ] Unit conversion: changing unit converts existing value
- [ ] Table populates with correct duration values
- [ ] 50mL/20mL rows highlighted
- [ ] Row tap toggles selection highlight
- [ ] Table row count responsive (6 vs 2 rows)
- [ ] Label text updates when unit changes

---

## Component Migration Patterns

### Pattern A: PDTextField → M3 TextField
```dart
// BEFORE
SizedBox(
  height: UIHeight + 24,
  child: PDTextField(
    prefixIcon: Icons.monitor_weight_outlined,
    labelText: 'Weight (kg)',
    controller: controller,
    fractionDigits: 0,
    interval: 1,
    onPressed: callback,
    range: const [0, 250],
  ),
)

// AFTER
TextField(
  controller: controller,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    prefixIcon: Icon(Icons.monitor_weight_outlined),
    labelText: 'Weight (kg)',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    ),
  ),
  onChanged: (_) => callback(),
)
```

**If +/- buttons are needed** (future screens like TCI), use `M3TextField` wrapper which keeps the `PDTextField` base with M3 theming.

### Pattern B: PDSegmentedControl → SegmentedButton
```dart
// BEFORE
PDSegmentedControl(
  fitWidth: true, fitHeight: true, fontSize: 14,
  defaultColor: theme.primary,
  defaultOnColor: theme.onPrimary,
  labels: ['A', 'B', 'C'],
  segmentedController: controller,
  onPressed: [onA, onB, onC],
)

// AFTER  
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'A', label: Text('A')),
    ButtonSegment(value: 'B', label: Text('B')),
    ButtonSegment(value: 'C', label: Text('C')),
  ],
  selected: {selectedValue},
  onSelectionChanged: (Set<String> selected) {
    if (selected.length != 1) return;  // ⚠️ Guard: empty set on re-tap
    if (selected.first == 'A') onA();
    else if (selected.first == 'B') onB();
    else onC();
  },
)
```

**Note:** `SegmentedButton` handles its own `showSelected` state. No need for `PDSegmentedController`.

---

## Rollback Strategy

Each migrated screen keeps its original file as a reference backup:
- `settings_screen.dart` → `settings_screen_m3.dart` (new file, imported conditionally)
- If issues found, switch import in `home_screen.dart` back to old screen

**Checking:** `home_screen.dart` has the screen list. After migrating Settings, the import changes from `settings_screen.dart` to `settings_screen_m3.dart`. The old file stays unchanged.

---

## Verification Protocol (for EVERY screen)

1. **Cold start:** Launch app, verify all settings load from SharedPreferences
2. **Theme:** Toggle light/dark/system, verify immediate change
3. **Input:** Type values, verify validation (range, type)
4. **Calculation:** Verify output matches expected values exactly
5. **Persistence:** Close app, reopen, verify all fields restored
6. **Navigation:** Switch tabs, come back, verify state preserved
7. **Localization:** Switch locale, verify labels update
8. **Responsive:** Test on mobile and tablet widths

---

## Self-Review: Identified Risks & Trade-offs

### Risk 1: PDTextField stepper removal
**Issue:** Spec says to use native `TextField` (no steppers) for Settings pump rate and Duration weight/infusion rate. But current code has steppers.
**Decision needed:** Keep steppers via `M3TextField` wrapper, or drop them for cleaner native M3 look?
**Recommendation:** Use `M3TextField` for safety. Steppers are harmless and users may rely on them.

### Risk 2: SegmentedButton empty-set edge case
**Issue:** `SegmentedButton.onSelectionChanged` fires with an empty `Set` when user taps the already-selected segment. Code must guard with `if (selected.length == 1)`.
**Fix:** Already accounted for in the spec above.

### Risk 3: Visual differences are unavoidable
**Issue:** `PDSegmentedControl` uses 5px corner radius. `SegmentedButton` uses M3 defaults (~12px outer radius, 8px inner). The visual WILL differ. This is expected for an M3 migration.
**Mitigation:** Accept as intentional M3 upgrade. Could customize via `SegmentedButtonTheme` to match 8px app default radius.

### Risk 4: Dexmedetomidine display-only container
**Issue:** Current code shows a container with `primary` color background when only one concentration exists. `SegmentedButton` with one segment would look different.
**Fix:** Keep the branching — if only one variant, show styled container; if multiple, show `SegmentedButton`.

### Risk 5: Dynamic label in Duration infusion rate
**Issue:** The label text includes the current unit, which changes when the user selects a different unit. The `M3TextField` is rebuilt on each `setState` via `updateInfusionUnit()`. This works but depends on the parent rebuilding.
**Fix:** Already works because `updateInfusionUnit` calls `run()` which calls `setState`. Verified.

### Risk 6: PDSwitchField controller lifecycle (deferred)
**Issue:** `PDSwitchField.dispose()` says `widget.controller.dispose()` — disposes an externally-owned controller. This is a bug but fixing it now affects screens not yet migrated.
**Decision:** Defer to Phase 4+ when those screens are migrated. Don't touch in Phase 0.

### Risk 7: PDSegmentedController replacement
**Issue:** Current code creates `PDSegmentedController` instances in `initState` and reads `.val` to know which segment is selected. `SegmentedButton` doesn't use controllers — it uses `Set<T>` for `selected`.
**Fix:** Remove `PDSegmentedController` instances. Track selection via local state or read directly from `Settings` provider.

### Risk 8: Localization strings
**Issue:** Settings screen uses `AppLocalizations.of(context)!.light`, `!.dark`, `!.auto`. These must be preserved.
**Fix:** Already in spec — same `AppLocalizations` calls, just passed as `ButtonSegment(label: Text(...))`.

### Risk 9: Empty error text for TextField
**Issue:** `PDTextField` shows "Please enter a value" when field is empty. Native `TextField` doesn't do this automatically.
**Decision:** For M3TextField wrapper, this is preserved. For native TextField, need to add explicit validation. Settings fields don't need this (pump rate defaults to current value). Duration fields are optional until calculation is run.

### Risk 10: Rollback approach
**Issue:** Spec says create `settings_screen_m3.dart` and switch import. This means two files exist.
**Decision:** After verification and sign-off, delete old file and rename M3 file to original name. Or keep both for one release cycle.

### Risk 11: Duration `updateInfusionUnit()` restructuring (CRITICAL)
**Issue:** Removing `PDSegmentedController` (infusionUnitController) requires restructuring `updateInfusionUnit()`. The method reads `infusionUnitController.val` in 6+ places. All must be migrated to `settings.infusionUnit`.
**Fix:** Inline the method into the `SegmentedButton` callback. All references replaced with `settings.infusionUnit` (watched via Provider). The `updateInfusionUnit()` method is deleted — its logic lives in the callback. All calculation methods (`convertInfusionRate`, `calculate`, `run`) stay untouched.
**Verified:** The callback correctly handles: decimal places, enabled/disabled state, label text, interval, unit conversion, and recalculation.

### Risk 12: `_buildDrugConcentrationSection` signature change
**Issue:** The method passes `UIHeight` and `screenWidth` for `SizedBox` sizing. With `SegmentedButton`, these params are unused.
**Fix:** Remove both params. `SegmentedButton` self-sizes. The display-only container (Dexmedetomidine) uses fixed styling.

### Risk 13: Phase 0 scope creep
**Issue:** Original spec included breakpoint unification and PDSwitchField lifecycle fix in Phase 0 — both risky because they affect screens not yet migrated.
**Fix:** Removed from Phase 0. Phase 0 is now only: (0.1) theme component additions, (0.2) junk removal. Everything else happens per-screen during migration.

### Risk 14: Pattern B missing empty-set guard (found 3rd review)
**Issue:** The Pattern B example in Component Migration Patterns section had `if (selected.first == 'A')` without guarding against empty set. All other examples in the spec correctly used `if (selected.length == 1)`.
**Fix:** Added `if (selected.length != 1) return;` guard. Verified consistent across all SegmentedButton examples.

### Risk 15: Section numbering gap (found 3rd review)
**Issue:** Duration section jumps from 2.3 to 2.5 (2.4 was removed during restructure but numbering wasn't updated).
**Fix:** Renamed to 2.4 (M3TextField height behavior) and 2.5 (Table).

### Risk 16: Import changes undocumented (found 3rd review)
**Issue:** Spec didn't specify import changes needed for Settings screen migration (remove legacy PD*, add M3TextField).
**Fix:** Added section 1.5 documenting exactly which imports to remove and add.

### Risk 17: M3TextField height discrepancy (found 3rd review)
**Issue:** Current code wraps PDTextField in `SizedBox(height: UIHeight + 24)`. M3TextField uses internal `_getResponsiveHeight()` (56-88px). The `+24` error text space is handled differently.
**Fix:** Documented approach: remove Sized box wrapper, verify visual height, adjust if needed.

### Risk 18: Drug concentration label formatting (found 4th review)
**Issue:** My spec example used `${variant.concentration}` (Dart string interpolation) which calls `.toString()` on a double, producing "10.0 mg/mL". The current code uses `toStringAsFixed(0)` producing "10 mg/mL".
**Fix:** Added `_fmt()` helper matching the current `toStringAsFixed(c == c.roundToDouble() ? 0 : 1)` pattern. All concentrations are whole numbers so this always drops the decimal. Also applied same formatting to the Dexmedetomidine display-only container.

---

## Files Not Touched (Safety Boundary)

These files contain calculation logic and must NEVER be modified during UI migration:
- `lib/models/calculator.dart`
- `lib/models/parameters.dart`
- `lib/models/simulation.dart`
- `lib/models/elemarsh.dart`
- `lib/models/patient.dart`
- `lib/models/pump.dart`
- `lib/models/operation.dart`
- `lib/providers/settings.dart` (only UI property reads, no logic changes)
- `lib/components/infusion_regime_table.dart` (already M3-compatible)
