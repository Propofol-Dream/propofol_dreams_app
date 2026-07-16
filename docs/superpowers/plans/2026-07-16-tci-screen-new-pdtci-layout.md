# TCIScreenNew PDTci Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign `TCIScreenNew` to use a pdtci-inspired result-first mobile flow and a custom desktop/tablet workstation layout while keeping current Propofol Dreams colors and behavior.

**Architecture:** Keep all changes isolated to `lib/screens/tci_screen_new.dart` plus focused tests. Reuse existing calculation state, input widgets, table, chart, and sync callbacks; only reorganize layout composition and add small private builders. Do not modify `lib/screens/tci_screen.dart` or wire `TCIScreenNew` into `HomeScreen`.

**Tech Stack:** Flutter, Provider `Settings`, existing `PKField`/`SwitchField`/`Selector`, `InfusionRateChart`, `DosageDataTable`, Flutter widget tests.

---

## File Structure

- Modify: `lib/screens/tci_screen_new.dart`
  - Add layout keys for tests.
  - Add private builders for empty state, result summary, desktop/tablet context section, table section, desktop/tablet workstation layout, and mobile pdtci flow.
  - Keep controllers, calculation, validation, and drug-model mapping unchanged.
- Modify: `test/tci_screen_new_test.dart`
  - Add desktop/tablet layout assertions.
  - Add mobile layout assertions.
  - Keep independent render assertions and no-navigation checks.
- Existing unchanged by this plan: `lib/screens/tci_screen.dart`, `lib/screens/home_screen.dart`, `lib/main_tci_standalone.dart`, `lib/screens/tci_standalone_shell.dart`, `test/tci_standalone_shell_test.dart`, `test/tci_screen_drug_model_test.dart`.

---

### Task 1: Add Layout Regression Tests

**Files:**
- Modify: `test/tci_screen_new_test.dart`

- [ ] **Step 1: Replace the test file with helpers and two responsive tests**

Use this complete file content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/screens/tci_screen_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Settings> _settings() async {
  SharedPreferences.setMockInitialValues({});
  final settings = Settings();
  await settings.initializeFromDisk();
  return settings;
}

Future<void> _pumpTciScreen(
  WidgetTester tester, {
  required Size surfaceSize,
}) async {
  final settings = await _settings();
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ChangeNotifierProvider<Settings>.value(
      value: settings,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TCIScreenNew(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TCIScreenNew renders desktop workstation independently',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(1200, 800));

    expect(find.byKey(const ValueKey('tci-new-desktop-workstation')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-desktop-results-area')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-desktop-input-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-mobile-flow')), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.textContaining('Propofol'), findsWidgets);
  });

  testWidgets('TCIScreenNew renders mobile pdtci flow with bottom controls',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(390, 844));

    expect(find.byKey(const ValueKey('tci-new-mobile-flow')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-mobile-results-area')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-mobile-input-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-desktop-workstation')), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.textContaining('Propofol'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run:

```bash
flutter test test/tci_screen_new_test.dart
```

Expected: FAIL because keys such as `tci-new-desktop-workstation` and `tci-new-mobile-flow` do not exist yet.

- [ ] **Step 3: Commit the failing test**

Run:

```bash
git add test/tci_screen_new_test.dart
git commit -m "test: lock new TCI responsive layout paths"
```

---

### Task 2: Add Shared Layout Builders In `TCIScreenNew`

**Files:**
- Modify: `lib/screens/tci_screen_new.dart:876-930`

- [ ] **Step 1: Add an empty-state builder before `_buildResults`**

Insert this method immediately before `_buildResults`:

```dart
  Widget _buildEmptyResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter patient details to see results',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 2: Add desktop/tablet context section builder**

Insert this method after `_buildEmptyResultsState`:

```dart
  Widget _buildDesktopContextSection(InfusionRegimeData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
            child: Padding(
              padding: const EdgeInsets.all(kSp12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate (mL/hr)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: kSp8),
                  Expanded(
                    child: InfusionRateChart(
                      data: data,
                      startTime: _startTime,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: kSp12),
        Expanded(
          flex: 2,
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
            child: Padding(
              padding: const EdgeInsets.all(kSp12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient / model',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: kSp8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildPatientChips(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 3: Add table section builder**

Insert this method after `_buildDesktopContextSection`:

```dart
  Widget _buildTableSection(
    InfusionRegimeData data,
    Settings settings, {
    required int maxVisibleRows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isTableSynced && data.rows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: ((_syncedRowIndex ?? 0) + 1) / data.rows.length,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
        DosageDataTable(
          data: data,
          maxVisibleRows: maxVisibleRows,
          selectedRowIndex: settings.selectedDosageTableRow,
          onRowTap: (index) {
            setState(() => _syncedRowIndex = index);
          },
          scrollController: tableScrollController,
          startTime: _startTime,
          syncedRowIndex: _syncedRowIndex,
          isSynced: _isTableSynced,
        ),
      ],
    );
  }
```

- [ ] **Step 4: Run formatter and focused test**

Run:

```bash
dart format lib/screens/tci_screen_new.dart && flutter test test/tci_screen_new_test.dart
```

Expected: still FAIL because layout keys are not wired yet, but no Dart syntax errors.

---

### Task 3: Implement Desktop/Tablet Workstation Layout

**Files:**
- Modify: `lib/screens/tci_screen_new.dart:934-977`

- [ ] **Step 1: Replace `_buildDesktopLayout`**

Replace the entire `_buildDesktopLayout(Settings settings)` method with:

```dart
  Widget _buildDesktopLayout(Settings settings) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalSidesPaddingPixel,
          right: horizontalSidesPaddingPixel,
          top: kSp12,
          bottom: MediaQuery.of(context).viewInsets.bottom + kSp12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Row(
              key: const ValueKey('tci-new-desktop-workstation'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  key: const ValueKey('tci-new-desktop-results-area'),
                  child: infusionRegimeData != null
                      ? _buildDesktopResults(infusionRegimeData!, settings)
                      : _buildEmptyResultsState(),
                ),
                const SizedBox(width: kSp12),
                SizedBox(
                  key: const ValueKey('tci-new-desktop-input-rail'),
                  width: 393,
                  child: _buildInputPanel(settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 2: Add `_buildDesktopResults` before `_buildDesktopLayout`**

Insert this method immediately before `_buildDesktopLayout`:

```dart
  Widget _buildDesktopResults(InfusionRegimeData data, Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDashboardCards(data),
        const SizedBox(height: kSp12),
        SizedBox(
          height: 250,
          child: _buildDesktopContextSection(data),
        ),
        const SizedBox(height: kSp12),
        Expanded(
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
            child: Padding(
              padding: const EdgeInsets.all(kSp12),
              child: SingleChildScrollView(
                child: _buildTableSection(data, settings, maxVisibleRows: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 3: Run focused desktop test**

Run:

```bash
flutter test test/tci_screen_new_test.dart --plain-name "TCIScreenNew renders desktop workstation independently"
```

Expected: PASS for the desktop test.

- [ ] **Step 4: Commit desktop layout**

Run:

```bash
git add lib/screens/tci_screen_new.dart test/tci_screen_new_test.dart
git commit -m "feat: add new TCI desktop workstation layout"
```

---

### Task 4: Implement Mobile PDTci Flow

**Files:**
- Modify: `lib/screens/tci_screen_new.dart:979-1029`

- [ ] **Step 1: Add `_buildMobileResults` before `_buildMobileLayout`**

Insert this method immediately before `_buildMobileLayout`:

```dart
  Widget _buildMobileResults(InfusionRegimeData data, Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDashboardCards(data, compact: true),
        const SizedBox(height: kSp12),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
          child: Padding(
            padding: const EdgeInsets.all(kSp8),
            child: _buildTableSection(data, settings, maxVisibleRows: 99),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 2: Replace `_buildMobileLayout`**

Replace the entire `_buildMobileLayout(Settings settings)` method with:

```dart
  Widget _buildMobileLayout(Settings settings) {
    return Scaffold(
      key: const ValueKey('tci-new-mobile-flow'),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            key: const ValueKey('tci-new-mobile-results-area'),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: horizontalSidesPaddingPixel,
                    right: horizontalSidesPaddingPixel,
                    top: kSp12,
                    bottom: kSp12,
                  ),
                  child: infusionRegimeData != null
                      ? _buildMobileResults(infusionRegimeData!, settings)
                      : SizedBox(
                          height: constraints.maxHeight - 100,
                          child: _buildEmptyResultsState(),
                        ),
                );
              },
            ),
          ),
          SafeArea(
            key: const ValueKey('tci-new-mobile-input-sheet'),
            top: false,
            child: _buildInputPanel(settings),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: Run focused mobile test**

Run:

```bash
flutter test test/tci_screen_new_test.dart --plain-name "TCIScreenNew renders mobile pdtci flow with bottom controls"
```

Expected: PASS for the mobile test.

- [ ] **Step 4: Run all focused TCI tests**

Run:

```bash
flutter test test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart test/tci_screen_drug_model_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit mobile layout**

Run:

```bash
git add lib/screens/tci_screen_new.dart test/tci_screen_new_test.dart
git commit -m "feat: add new TCI mobile pdtci flow"
```

---

### Task 5: Verify Build And Full Suite

**Files:**
- Modify only if verification exposes a defect in files changed by Tasks 1-4.

- [ ] **Step 1: Format changed Dart files**

Run:

```bash
dart format lib/screens/tci_screen_new.dart test/tci_screen_new_test.dart
```

Expected: formatter completes without error.

- [ ] **Step 2: Run focused tests**

Run:

```bash
flutter test test/tci_screen_new_test.dart test/tci_standalone_shell_test.dart test/tci_screen_drug_model_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 3: Run full test suite**

Run:

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 4: Verify standalone pdtci build**

Run:

```bash
scripts/build_pdtci_web.sh
```

Expected: command exits 0 and prints `Built standalone PDTci web output at .../build/pdtci_web`.

- [ ] **Step 5: Run analyzer hard-error check**

Run:

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Expected: command exits 0. Plain `flutter analyze` may still report historical warnings/infos and is not the completion gate for this plan.

- [ ] **Step 6: Commit verification fixes if any were needed**

If Step 2-5 required fixes, commit only those files:

```bash
git add lib/screens/tci_screen_new.dart test/tci_screen_new_test.dart
git commit -m "fix: stabilize new TCI responsive layout"
```

If no fixes were needed, do not create an empty commit.

---

## Self-Review

- Spec coverage: mobile pdtci flow, desktop/tablet workstation, no identity bar, current color scheme, unchanged current `TCIScreen`, preserved mapping, tests, and build verification are covered by Tasks 1-5.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation steps remain.
- Type consistency: plan uses existing `InfusionRegimeData`, `Settings`, `InfusionRateChart`, `DosageDataTable`, `CollapsibleInputSection`, and the current `collapsedChipRows` API.
