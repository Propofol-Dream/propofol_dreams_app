# Mobile Workflow & Real-Time Infusion Table Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve mobile UX with collapsible input panels, EleMarsh result hierarchy, TCI mobile optimizations, and a real-time infusion table sync feature.

**Architecture:** Four independent workstreams building on existing PKField/SwitchField/widget infrastructure. No new state management — collapsible panels use local `State`, sync state lives in `_TCIScreenState`.

**Tech Stack:** Flutter (Dart), Material 3 via `MaterialTheme` color schemes

---

### Task 1: Create CollapsibleInputSection widget

**Files:**
- Create: `lib/components/collapsible_input_section.dart`
- Test: (no widget tests — verified visually)

- [ ] **Write the widget**

```dart
import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class CollapsibleInputSection extends StatefulWidget {
  final Widget summary;
  final Widget child;

  const CollapsibleInputSection({
    super.key,
    required this.summary,
    required this.child,
  });

  @override
  State<CollapsibleInputSection> createState() => _CollapsibleInputSectionState();
}

class _CollapsibleInputSectionState extends State<CollapsibleInputSection>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(kRadius),
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSp16, vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: kSp8),
                  Expanded(child: widget.summary),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: widget.child,
            crossFadeState: _isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.fastOutSlowIn,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Verify it compiles**

Run: `flutter analyze lib/components/collapsible_input_section.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/components/collapsible_input_section.dart
git commit -m "feat: add CollapsibleInputSection widget"
```

---

### Task 2: Add collapsible input to EleMarsh screen

**Files:**
- Modify: `lib/screens/elemarsh_screen.dart`

- [ ] **Add `_buildSummary` method**

```dart
Widget _buildSummary() {
  final age = int.tryParse(ageController.text) ?? 0;
  final weight = int.tryParse(weightController.text) ?? 0;
  final height = int.tryParse(heightController.text) ?? 0;
  final target = double.tryParse(targetController.text) ?? 0;
  final flow = _isWakeFlow ? 'Wake' : 'Induce';
  final sex = _sexValue ? 'F' : 'M';
  final theme = Theme.of(context);
  return Text(
    '$flow · $sex · ${age}y · ${weight}kg · ${height}cm · CeT ${target.toStringAsFixed(1)}',
    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
```

- [ ] **Wrap `_buildInputPanel` with `CollapsibleInputSection` on mobile**

Change `_buildInputPanel`:
```dart
Widget _buildInputPanel(Settings settings) {
  final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);
  final panel = Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
    ),
    child: _buildInputFields(settings),
  );
  if (!useMobile) return panel;
  return CollapsibleInputSection(
    summary: _buildSummary(),
    child: panel,
  );
}
```

Remove unused `body: Scaffold` wrapping in `_buildMobileLayout` if present (the mobile layout already returns a Scaffold).

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/elemarsh_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/elemarsh_screen.dart
git commit -m "feat: add collapsible input panel to EleMarsh screen"
```

---

### Task 3: Add collapsible input to TCI screen

**Files:**
- Modify: `lib/screens/tci_screen.dart`

- [ ] **Add `_buildSummary` method**

```dart
Widget _buildSummary() {
  final age = int.tryParse(ageController.text) ?? 0;
  final weight = int.tryParse(weightController.text) ?? 0;
  final height = int.tryParse(heightController.text) ?? 0;
  final target = double.tryParse(targetController.text) ?? 0;
  final drug = _selectedDrug?.displayName ?? 'Drug';
  final sex = _sexValue ? 'F' : 'M';
  final theme = Theme.of(context);
  return Text(
    '$drug · $sex · ${age}y · ${weight}kg · ${height}cm · CeT ${target.toStringAsFixed(1)}',
    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
```

- [ ] **Wrap `_buildInputPanel` with `CollapsibleInputSection` on mobile**

Change `_buildInputPanel`:
```dart
Widget _buildInputPanel(Settings settings) {
  final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);
  final panel = Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
    ),
    child: _buildInputFields(settings),
  );
  if (!useMobile) return panel;
  return CollapsibleInputSection(
    summary: _buildSummary(),
    child: panel,
  );
}
```

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/tci_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/tci_screen.dart
git commit -m "feat: add collapsible input panel to TCI screen"
```

---

### Task 4: Add collapsible input to Volume screen

**Files:**
- Modify: `lib/screens/volume_screen.dart`

- [ ] **Read current `_buildInputCard` and `_buildInputPanel`** to understand the structure

The Volume screen currently uses `_buildInputCard` wrapping `_buildInputFields` with a `CollapsibleInputCard` legacy widget. Replace it with the new pattern.

- [ ] **Add `_buildSummary` method**

```dart
Widget _buildSummary() {
  final weight = int.tryParse(weightController.text) ?? 0;
  final rate = double.tryParse(rateController.text) ?? 0;
  final hours = double.tryParse(hoursController.text) ?? 0;
  final model = _selectedModel?.displayName ?? 'Model';
  final theme = Theme.of(context);
  return Text(
    '$model · ${weight}kg · ${rate.toStringAsFixed(1)} mL/hr · ${hours.toStringAsFixed(1)}h',
    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
```

- [ ] **Replace `_buildInputCard` with `_buildInputPanel` following new pattern**

If the Volume screen doesn't have a clean `_buildInputPanel`, create one:
```dart
Widget _buildInputPanel(Settings settings) {
  final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);
  final panel = Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
    ),
    child: _buildInputFields(settings),
  );
  if (!useMobile) return panel;
  return CollapsibleInputSection(
    summary: _buildSummary(),
    child: panel,
  );
}
```

Remove legacy `CollapsibleInputCard` controller and import.

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/volume_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/volume_screen.dart
git commit -m "feat: add collapsible input panel to Volume screen"
```

---

### Task 5: Add collapsible input to Duration screen

**Files:**
- Modify: `lib/screens/duration_screen.dart`

- [ ] **Add `_buildSummary` method**

```dart
Widget _buildSummary() {
  final weight = int.tryParse(weightController.text) ?? 0;
  final rate = double.tryParse(infusionRateController.text) ?? 0;
  final unit = infusionUnits[_selectedUnitIndex].toString();
  final theme = Theme.of(context);
  return Text(
    '${weight}kg · ${rate.toStringAsFixed(infusionRateDecimal)} $unit',
    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
```

- [ ] **Replace `_buildInputCard` with `_buildInputPanel` following new pattern**

```dart
Widget _buildInputPanel(Settings settings) {
  final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);
  final panel = Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
    ),
    child: _buildInputFields(settings),
  );
  if (!useMobile) return panel;
  return CollapsibleInputSection(
    summary: _buildSummary(),
    child: panel,
  );
}
```

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/duration_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/duration_screen.dart
git commit -m "feat: add collapsible input panel to Duration screen"
```

---

### Task 6: EleMarsh result hierarchy

**Files:**
- Modify: `lib/screens/elemarsh_screen.dart`

- [ ] **Add `fontSize` parameter to `_buildStatCard`**

Change the method signature and implementation:
```dart
Widget _buildStatCard(
  String label,
  String value,
  String subtitle,
  IconData icon,
  Color accentColor,
  ThemeData theme, {
  double valueFontSize = 24,
  bool prominent = false,
}) {
  return Card(
    elevation: 1,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadius),
      side: prominent
          ? BorderSide(color: accentColor, width: 2)
          : BorderSide.none,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: prominent ? 14 : 12,
        horizontal: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: kSp4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(width: kSp4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Update calls in `_buildResultsSection` to pass tier-appropriate sizes**

Replace ABW and CpT/Bolus calls:
```dart
Expanded(
  child: _buildStatCard(
    'EleMarsh ${AppLocalizations.of(context)!.abw}',
    '$weightBestGuess',
    'kg',
    Icons.monitor_weight,
    theme.colorScheme.primary,
    theme,
    valueFontSize: 32,
    prominent: true,
  ),
),
```

Replace CpT/Bolus similarly with `valueFontSize: 32, prominent: true`.

Replace eBIS call:
```dart
_buildStatCard(
  'eBIS',
  predictedBIS,
  '',
  Icons.monitor_heart_outlined,
  theme.colorScheme.onSurface,
  theme,
  valueFontSize: 18,
),
```

Replace BMI, 20 mL, 50 mL calls with `valueFontSize: 18`.

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/elemarsh_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/elemarsh_screen.dart
git commit -m "feat: add visual hierarchy to EleMarsh results"
```

---

### Task 7: TCI mobile optimization — compact dashboard cards

**Files:**
- Modify: `lib/screens/tci_screen.dart`

- [ ] **Add `compact` parameter to `_buildDashboardCards`**

Find `_buildDashboardCards` and add the parameter:
```dart
Widget _buildDashboardCards(InfusionRegimeData data, {bool compact = false}) {
  final theme = Theme.of(context);
  final cardPadding = compact
      ? const EdgeInsets.symmetric(vertical: 8, horizontal: 8)
      : const EdgeInsets.symmetric(vertical: 12, horizontal: 10);
  final valueSize = compact ? 16.0 : 24.0;
  final subtitleSize = compact ? 10.0 : 11.0;
  final iconSize = compact ? 14.0 : 16.0;
  // ... rest of method uses these variables instead of hardcoded values
}
```

Update the Card padding, Text font sizes, and Icon sizes inside to use these variables.

- [ ] **Pass `compact` in mobile layout**

In `_buildResults`, pass `compact` based on mobile:
```dart
_buildDashboardCards(data, compact: ResponsiveHelper.shouldUseMobileLayout(context)),
```

- [ ] **Pass `maxVisibleRows: 4` on mobile**

In `_buildResults`:
```dart
DosageDataTable(
  data: data,
  maxVisibleRows: ResponsiveHelper.shouldUseMobileLayout(context) ? 4 : 8,
  ...
)
```

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/tci_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/tci_screen.dart
git commit -m "feat: compact dashboard cards and fewer table rows on mobile TCI"
```

---

### Task 8: Real-time infusion table — DosageDataTable sync support

**Files:**
- Modify: `lib/components/infusion_regime_table.dart`

- [ ] **Add `syncedRowIndex` and `isSynced` parameters to `DosageDataTable`**

Find the `DosageDataTable` class and add these parameters:
```dart
class DosageDataTable extends StatefulWidget {
  // ... existing params
  final int? syncedRowIndex;
  final bool isSynced;

  const DosageDataTable({
    super.key,
    required this.data,
    this.maxVisibleRows = 8,
    this.selectedRowIndex,
    this.onRowTap,
    this.scrollController,
    this.startTime,
    this.syncedRowIndex,
    this.isSynced = false,
  });
}
```

- [ ] **Apply sync styling to rows**

Inside the row factory, find where each row is built and add:
```dart
final bool isPastRow = widget.isSynced && index < (widget.syncedRowIndex ?? 0);
final bool isNowRow = widget.isSynced && index == widget.syncedRowIndex;
final bool isSyncAnchor = !widget.isSynced && index == widget.syncedRowIndex;

// Wrap the row content:
Container(
  decoration: isNowRow || isSyncAnchor
      ? BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
        )
      : null,
  child: Opacity(
    opacity: isPastRow ? 0.3 : 1.0,
    child: // existing row content (time cell + rate cell)
  ),
)
```

- [ ] **Add "◀ (now)" suffix to the time cell for the now row**

Find the time cell text and append:
```dart
if (isNowRow) {
  timeText += ' ◀ (now)';
}
```

- [ ] **Add `syncedProgress` getter** (not needed — table doesn't render the progress bar, the TCI screen does)

- [ ] **Verify it compiles**

Run: `flutter analyze lib/components/infusion_regime_table.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/components/infusion_regime_table.dart
git commit -m "feat: add sync state support to DosageDataTable"
```

---

### Task 9: Real-time infusion table — TCI screen sync controls

**Files:**
- Modify: `lib/screens/tci_screen.dart`

- [ ] **Add sync state variables**

Add to `_TCIScreenState`:
```dart
int? _syncedRowIndex;
TimeOfDay? _syncedClockTime;
bool _isTableSynced = false;
```

Add `Timer? syncTimer;` and `Duration syncDebounce = const Duration(milliseconds: 500);` if not already present.

- [ ] **Add `_buildSyncSection` method**

```dart
Widget _buildSyncSection() {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: kSp16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(kRadius),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _syncedClockTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _syncedClockTime = picked);
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: theme.colorScheme.outline),
                    color: theme.colorScheme.onPrimary,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: kSp12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _syncedClockTime?.format(context) ?? 'Set clock time',
                    style: TextStyle(
                      fontSize: 16,
                      color: _syncedClockTime != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: kSp8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                ),
                onPressed: _syncedRowIndex != null && _syncedClockTime != null
                    ? () {
                        setState(() => _isTableSynced = true);
                      }
                    : null,
                child: const Text('Sync Time'),
              ),
            ),
            if (_isTableSynced) ...[
              const SizedBox(width: kSp8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isTableSynced = false;
                      _syncedRowIndex = null;
                      _syncedClockTime = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
```

- [ ] **Add sync section to input fields**

Inside `_buildInputFields`, add after the drug selector row and before Sex+Age:
```dart
// ... after drug selector
if (_syncedRowIndex != null) ...[
  const SizedBox(height: kSp12),
  _buildSyncSection(),
],
```

- [ ] **Pass sync state to DosageDataTable**

In `_buildResults`, update the `DosageDataTable` call:
```dart
DosageDataTable(
  data: data,
  maxVisibleRows: ResponsiveHelper.shouldUseMobileLayout(context) ? 4 : 8,
  selectedRowIndex: settings.selectedDosageTableRow,
  onRowTap: (index) {
    setState(() => _syncedRowIndex = index);
    // Don't change selectedDosageTableRow
  },
  scrollController: tableScrollController,
  startTime: _startTime,
  syncedRowIndex: _syncedRowIndex,
  isSynced: _isTableSynced,
),
```

- [ ] **Add progress bar above table when synced**

In `_buildResults`, above the `DosageDataTable`, add:
```dart
if (_isTableSynced && data.rows.isNotEmpty) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LinearProgressIndicator(
      value: ((_syncedRowIndex ?? 0) + 1) / data.rows.length,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    ),
  ),
],
```

- [ ] **Clear sync on recalculation**

In `calculate()`, merge sync clear into the existing `setState`:
```dart
setState(() {
  _isTableSynced = false;
  _syncedRowIndex = null;
  _syncedClockTime = null;
  infusionRegimeData = InfusionRegimeData.fromSimulation(...);
  // ... rest of existing setState content
});
```

- [ ] **Verify it compiles**

Run: `flutter analyze lib/screens/tci_screen.dart`
Expected: No issues found

- [ ] **Commit**

```bash
git add lib/screens/tci_screen.dart
git commit -m "feat: add real-time table sync controls to TCI screen"
```

---

### Task 10: Full build verification

- [ ] **Build web release**

Run: `flutter build web --release`
Expected: ✓ Built build/web

- [ ] **Restart dev server**

Run: `kill $(lsof -ti:8181) 2>/dev/null; python3 -m http.server 8181 --directory build/web &>/dev/null &`

- [ ] **Push to main**

```bash
git add -A && git commit -m "mobile workflow: collapsible inputs, EleMarsh hierarchy, TCI mobile optimizations, real-time sync" && git push origin main
```