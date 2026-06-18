# PD Input Control Frame Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a rollback-safe PD input geometry system that keeps selectors, reset buttons, text fields, switches, and downstream rows stable when compact status/error text appears.

**Architecture:** Add `PDInputControlFrame` as the shared fixed-height control + fixed-height status-lane primitive, then add `PDCalculatorSelectorRow` for selector/reset rows. Preserve existing `PDTextField` and `PDSwitchField` public names and behavior, but add opt-in framed rendering behind `UIConfig.useInputControlFrame` so Volume and TCI can migrate screen-by-screen with rollback.

**Tech Stack:** Flutter, Dart, Provider, `flutter_test`, existing `UIConfig`, existing legacy PD widgets.

---

## Spec

Implement the approved spec:

- `docs/superpowers/specs/2026-06-17-pd-input-control-frame-design.md`

## File Structure

Create:

- `lib/components/PDInputControlFrame.dart`: shared input frame and `PDInputStatusType` enum.
- `lib/components/PDCalculatorSelectorRow.dart`: shared selector/reset row using the frame.
- `test/pd_input_control_frame_test.dart`: widget tests for the new frame, selector row, opt-in `PDTextField`, and opt-in `PDSwitchField`.

Modify:

- `lib/config/ui_config.dart`: add central rollback flag and helper.
- `lib/components/legacy/PDTextField.dart`: add optional `useInputControlFrame`, route framed status externally, preserve old path.
- `lib/components/legacy/PDSwitchField.dart`: add optional `useInputControlFrame`, route framed status externally, preserve old path.
- `lib/screens/volume_screen.dart`: migrate selector/reset row and affected fields/switches to opt-in frame.
- `lib/screens/tci_screen.dart`: migrate selector/reset row and affected fields/switches to opt-in frame.

Do not modify clinical calculations, model validation rules, controller ownership, or callback timing.

---

### Task 1: Add Failing Frame And Selector Row Tests

**Files:**
- Create: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Create the failing widget test file**

Create `test/pd_input_control_frame_test.dart` with this content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/components/PDCalculatorSelectorRow.dart';
import 'package:propofol_dreams_app/components/PDInputControlFrame.dart';
import 'package:propofol_dreams_app/components/legacy/PDSwitchController.dart';
import 'package:propofol_dreams_app/components/legacy/PDSwitchField.dart';
import 'package:propofol_dreams_app/components/legacy/PDTextField.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => Settings(),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('PDInputControlFrame reserves stable status lane', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PDInputControlFrame(
          controlHeight: 56,
          statusHeight: 24,
          statusText: null,
          child: SizedBox.expand(child: Placeholder()),
        ),
      ),
    );

    final frameWithoutStatus = tester.getSize(find.byType(PDInputControlFrame));
    expect(frameWithoutStatus.height, 80);
    expect(find.text('BMI outside model range'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        const PDInputControlFrame(
          controlHeight: 56,
          statusHeight: 24,
          statusText: 'BMI outside model range',
          statusType: PDInputStatusType.error,
          child: SizedBox.expand(child: Placeholder()),
        ),
      ),
    );

    final frameWithStatus = tester.getSize(find.byType(PDInputControlFrame));
    expect(frameWithStatus.height, frameWithoutStatus.height);
    expect(find.text('BMI outside model range'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('PDCalculatorSelectorRow keeps reset button fixed while status appears', (tester) async {
    var resetCount = 0;

    Widget buildRow({String? statusText}) {
      return _wrap(
        PDCalculatorSelectorRow(
          resetTooltip: 'Reset model defaults',
          selectorStatusText: statusText,
          selectorStatusType: statusText == null
              ? PDInputStatusType.none
              : PDInputStatusType.error,
          onReset: () => resetCount++,
          selector: const TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildRow());
    final buttonFinder = find.byIcon(Icons.restart_alt_outlined);
    final buttonTopWithoutStatus = tester.getTopLeft(buttonFinder).dy;
    final buttonSizeWithoutStatus = tester.getSize(buttonFinder);

    await tester.pumpWidget(buildRow(statusText: 'BMI outside model range'));
    final buttonTopWithStatus = tester.getTopLeft(buttonFinder).dy;
    final buttonSizeWithStatus = tester.getSize(buttonFinder);

    expect(buttonTopWithStatus, buttonTopWithoutStatus);
    expect(buttonSizeWithStatus, buttonSizeWithoutStatus);
    expect(find.text('BMI outside model range'), findsOneWidget);

    await tester.tap(buttonFinder);
    expect(resetCount, 1);
  });

  testWidgets('PDTextField opt-in frame preserves step callback and external status lane', (tester) async {
    final controller = TextEditingController(text: '5');
    var callbackCount = 0;

    await tester.pumpWidget(
      _wrap(
        PDTextField(
          prefixIcon: Icons.calendar_month,
          labelText: 'Age',
          interval: 1,
          fractionDigits: 0,
          controller: controller,
          range: const [1, 10],
          helperText: 'Age helper',
          onPressed: () => callbackCount++,
          height: 56,
          useInputControlFrame: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(PDTextField)).height, 80);
    expect(find.text('Age helper'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(controller.text, '6');
    expect(callbackCount, 1);
  });

  testWidgets('PDSwitchField opt-in frame preserves toggle callback', (tester) async {
    final controller = PDSwitchController(false);
    var callbackCount = 0;

    await tester.pumpWidget(
      _wrap(
        PDSwitchField(
          prefixIcon: Icons.person,
          labelText: 'Sex',
          switchTexts: const {true: 'Female', false: 'Male'},
          controller: controller,
          onChanged: () => callbackCount++,
          height: 56,
          useInputControlFrame: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(PDSwitchField)).height, 80);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(controller.val, true);
    expect(callbackCount, 1);
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
```

Expected: FAIL because `PDInputControlFrame.dart`, `PDCalculatorSelectorRow.dart`, and `useInputControlFrame` constructor parameters do not exist yet.

- [ ] **Step 3: Commit the failing tests**

```bash
git add test/pd_input_control_frame_test.dart
git commit -m "test: add PD input control frame tests"
```

---

### Task 2: Add PDInputControlFrame And UIConfig Flag

**Files:**
- Create: `lib/components/PDInputControlFrame.dart`
- Modify: `lib/config/ui_config.dart`
- Test: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Add `PDInputControlFrame`**

Create `lib/components/PDInputControlFrame.dart`:

```dart
import 'package:flutter/material.dart';

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

  bool get _hasStatus =>
      statusText != null &&
      statusText!.trim().isNotEmpty &&
      statusType != PDInputStatusType.none;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (statusType) {
      PDInputStatusType.error => theme.colorScheme.error,
      PDInputStatusType.warning => theme.colorScheme.tertiary,
      PDInputStatusType.info => theme.colorScheme.primary,
      PDInputStatusType.none => theme.colorScheme.onSurfaceVariant,
    };
    final icon = statusIcon ??
        switch (statusType) {
          PDInputStatusType.error => Icons.error_outline,
          PDInputStatusType.warning => Icons.warning_amber_outlined,
          PDInputStatusType.info => Icons.info_outline,
          PDInputStatusType.none => null,
        };

    return SizedBox(
      height: controlHeight + statusHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: controlHeight,
            width: double.infinity,
            child: child,
          ),
          SizedBox(
            height: statusHeight,
            width: double.infinity,
            child: _hasStatus
                ? Semantics(
                    label: '${statusType.name}: ${statusText!.trim()}',
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 14, color: color),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            statusText!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add rollback flag and migration status in `UIConfig`**

Modify `lib/config/ui_config.dart`.

Add this under the per-component feature flags:

```dart
  /// Enable the PD fixed control/status-lane input frame for opted-in widgets.
  static const bool useInputControlFrame = false;
```

Add this computed property near the other computed properties:

```dart
  /// Check if an opted-in widget should use PDInputControlFrame.
  static bool shouldUseInputControlFrame({required bool optIn}) =>
      !_emergencyFallback && useInputControlFrame && optIn;
```

Add this entry in `getMigrationStatus()['components']`:

```dart
        'inputControlFrame': useInputControlFrame,
```

- [ ] **Step 3: Run the focused test**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
```

Expected: still FAIL because `PDCalculatorSelectorRow` and widget opt-in parameters are not implemented.

- [ ] **Step 4: Commit frame and config**

```bash
git add lib/components/PDInputControlFrame.dart lib/config/ui_config.dart
git commit -m "feat: add PD input control frame"
```

---

### Task 3: Add PDCalculatorSelectorRow

**Files:**
- Create: `lib/components/PDCalculatorSelectorRow.dart`
- Test: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Add `PDCalculatorSelectorRow`**

Create `lib/components/PDCalculatorSelectorRow.dart`:

```dart
import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import '../config/ui_config.dart';
import 'PDInputControlFrame.dart';

class PDCalculatorSelectorRow extends StatelessWidget {
  const PDCalculatorSelectorRow({
    super.key,
    required this.selector,
    required this.onReset,
    required this.resetTooltip,
    this.selectorStatusText,
    this.selectorStatusType = PDInputStatusType.none,
    this.height = 56,
    this.spacing = kSp8,
  });

  final Widget selector;
  final VoidCallback onReset;
  final String resetTooltip;
  final String? selectorStatusText;
  final PDInputStatusType selectorStatusType;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final resetButton = SizedBox(
      height: height,
      width: height,
      child: Tooltip(
        message: resetTooltip,
        child: Semantics(
          button: true,
          label: resetTooltip,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(kRadius),
              ),
            ),
            onPressed: onReset,
            child: const Icon(Icons.restart_alt_outlined),
          ),
        ),
      ),
    );

    if (!UIConfig.useInputControlFrame) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SizedBox(height: height, child: selector)),
          SizedBox(width: spacing),
          resetButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PDInputControlFrame(
            controlHeight: height,
            statusText: selectorStatusText,
            statusType: selectorStatusType,
            child: selector,
          ),
        ),
        SizedBox(width: spacing),
        SizedBox(
          width: height,
          height: height + 24,
          child: Column(
            children: [
              resetButton,
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Temporarily enable frame for the selector row test**

Because `UIConfig.useInputControlFrame` is a `static const`, the selector-row status test requires the flag to be `true` during implementation verification.

Edit `lib/config/ui_config.dart`:

```dart
  static const bool useInputControlFrame = true;
```

This is intentional for the migration implementation slice. Rollback remains one-line: set it back to `false`.

- [ ] **Step 3: Run the focused test**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
```

Expected: still FAIL because `PDTextField.useInputControlFrame` and `PDSwitchField.useInputControlFrame` are not implemented yet.

- [ ] **Step 4: Commit selector row**

```bash
git add lib/components/PDCalculatorSelectorRow.dart lib/config/ui_config.dart
git commit -m "feat: add PD calculator selector row"
```

---

### Task 4: Add Framed PDTextField Path

**Files:**
- Modify: `lib/components/legacy/PDTextField.dart`
- Test: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Add imports and constructor parameter**

Modify `lib/components/legacy/PDTextField.dart`.

Add imports:

```dart
import '../../config/ui_config.dart';
import '../PDInputControlFrame.dart';
```

Add the constructor parameter after `this.m3Style = false,`:

```dart
    this.useInputControlFrame = false,
```

Add the field after `final bool m3Style;`:

```dart
  final bool useInputControlFrame;
```

- [ ] **Step 2: Extract the existing `Stack` into a private builder**

Inside `_PDTextFieldState`, replace the final `return Stack(alignment: Alignment.centerRight, children: [` block in `build` with this pattern:

```dart
    final errorText = widget.enabled
        ? widget.controller.text.isEmpty
            ? 'Please enter a value'
            : isNumeric
                ? isWithinRange
                    ? null
                    : 'min: ${widget.range[0]} and max: ${widget.range[1]}'
                : 'Please enter a value'
        : null;

    final useFrame = UIConfig.shouldUseInputControlFrame(
      optIn: widget.useInputControlFrame,
    );

    final field = _buildTextFieldStack(
      context: context,
      settings: settings,
      responsiveHeight: responsiveHeight,
      suffixIconConstraintsWidth: suffixIconConstraintsWidth,
      suffixIconConstraintsHeight: suffixIconConstraintsHeight,
      isError: isError,
      isWarning: isWarning,
      isNumeric: isNumeric,
      isWithinRange: isWithinRange,
      canBeDecreased: canBeDecreased,
      canBeIncreased: canBeIncreased,
      errorText: useFrame ? null : errorText,
      helperText: useFrame ? null : widget.helperText,
    );

    if (!useFrame) return field;

    return PDInputControlFrame(
      controlHeight: responsiveHeight,
      statusText: errorText ?? widget.helperText,
      statusType: errorText != null
          ? PDInputStatusType.error
          : widget.helperText != null && widget.helperText!.trim().isNotEmpty
              ? PDInputStatusType.warning
              : PDInputStatusType.none,
      child: field,
    );
```

Then create `_buildTextFieldStack` below `build`. Move the current `Stack(alignment: Alignment.centerRight, children: [` block into this helper and replace the hard-coded decoration fields with the parameters:

```dart
          helperText: helperText,
          errorText: errorText,
```

The helper signature must be:

```dart
  Widget _buildTextFieldStack({
    required BuildContext context,
    required Settings settings,
    required double responsiveHeight,
    required double suffixIconConstraintsWidth,
    required double suffixIconConstraintsHeight,
    required bool isError,
    required bool isWarning,
    required bool isNumeric,
    required bool isWithinRange,
    required bool canBeDecreased,
    required bool canBeIncreased,
    required String? errorText,
    required String? helperText,
  })
```

The helper body is the current `Stack(alignment: Alignment.centerRight, children: [` block from `PDTextField.build`, moved mechanically into the helper. After moving it, the only body edits are these two `InputDecoration` assignments: `helperText: helperText` and `errorText: errorText`.

- [ ] **Step 3: Preserve step and long-press behavior**

In the extracted helper, preserve these existing statements exactly where they already occur:

```dart
widget.controller.text = prev.toStringAsFixed(widget.fractionDigits);
await HapticFeedback.mediumImpact();
widget.onPressed();
final timer = Timer.periodic(widget.delay, (t) async {
  double? prev = double.tryParse(widget.controller.text);
  if (prev != null && prev >= widget.range[0]) {
    prev -= widget.interval;
  }
});
```

Expected diff shape: layout wrapping changes only; plus/minus and long-press code remain behaviorally identical.

- [ ] **Step 4: Run focused test**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
```

Expected: still FAIL only for `PDSwitchField.useInputControlFrame` if switch is not implemented yet. The `PDTextField` test should now pass.

- [ ] **Step 5: Commit PDTextField frame support**

```bash
git add lib/components/legacy/PDTextField.dart
git commit -m "feat: add framed PD text field path"
```

---

### Task 5: Add Framed PDSwitchField Path

**Files:**
- Modify: `lib/components/legacy/PDSwitchField.dart`
- Test: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Add imports and constructor parameters**

Modify `lib/components/legacy/PDSwitchField.dart`.

Add imports:

```dart
import '../../config/ui_config.dart';
import '../PDInputControlFrame.dart';
```

Add constructor parameters after `this.enabled = true,`:

```dart
    this.useInputControlFrame = false,
    this.statusText,
    this.statusType = PDInputStatusType.none,
```

Add fields after `double height;`:

```dart
  final bool useInputControlFrame;
  final String? statusText;
  final PDInputStatusType statusType;
```

- [ ] **Step 2: Wrap the existing stack when opted in**

At the end of `build`, replace `return Stack(alignment: Alignment.centerRight, children: [` with:

```dart
    final field = _buildSwitchStack(context, textEditingController);

    if (!UIConfig.shouldUseInputControlFrame(optIn: widget.useInputControlFrame)) {
      return field;
    }

    return PDInputControlFrame(
      controlHeight: widget.height,
      statusText: widget.statusText,
      statusType: widget.statusType,
      child: field,
    );
```

Move the existing stack into this helper below `build`:

```dart
  Widget _buildSwitchStack(
    BuildContext context,
    TextEditingController textEditingController,
  ) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          controller: textEditingController,
          decoration: InputDecoration(
            filled: widget.enabled ? true : false,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            helperText: null,
            helperStyle: const TextStyle(fontSize: 10),
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(right: 4, bottom: 16),
          height: widget.height,
          child: const SizedBox(height: 24, width: 48),
        ),
      ],
    );
  }
```

Do not change the existing `Switch.onChanged` body:

```dart
await HapticFeedback.mediumImpact();
setState(() {
  widget.controller.val = val;
});
widget.onChanged();
```

- [ ] **Step 3: Run focused test**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
```

Expected: PASS.

- [ ] **Step 4: Run analyzer for component files**

Run:

```bash
flutter analyze lib/components/PDInputControlFrame.dart lib/components/PDCalculatorSelectorRow.dart lib/components/legacy/PDTextField.dart lib/components/legacy/PDSwitchField.dart test/pd_input_control_frame_test.dart
```

Expected: no errors. Existing style infos are acceptable only if already present for legacy widget naming.

- [ ] **Step 5: Commit switch frame support**

```bash
git add lib/components/legacy/PDSwitchField.dart test/pd_input_control_frame_test.dart
git commit -m "feat: add framed PD switch field path"
```

---

### Task 6: Migrate Volume Screen To PDCalculatorSelectorRow And Opt-In Fields

**Files:**
- Modify: `lib/screens/volume_screen.dart`
- Test: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Add imports**

Add imports near the other component imports in `lib/screens/volume_screen.dart`:

```dart
import 'package:propofol_dreams_app/components/PDCalculatorSelectorRow.dart';
import 'package:propofol_dreams_app/components/PDInputControlFrame.dart';
```

- [ ] **Step 2: Make the model selector control-only**

In `buildModelSelector`, remove selector-level `errorText` and helper text from the `InputDecoration` when used by `PDCalculatorSelectorRow`:

```dart
                  helperText: null,
                  errorText: null,
```

Keep error coloring exactly as currently implemented:

```dart
color: hasValidationError
    ? Theme.of(context).colorScheme.error
    : Theme.of(context).colorScheme.primary,
```

- [ ] **Step 3: Replace the model selector/reset row**

Replace the `Row` at `volume_screen.dart` around the `// Model selector and reset button` comment with:

```dart
        PDCalculatorSelectorRow(
          height: UIHeight,
          resetTooltip: 'Reset model defaults',
          selector: buildModelSelector(settings, UIHeight),
          selectorStatusText: validationErrorText,
          selectorStatusType: hasValidationError
              ? PDInputStatusType.error
              : PDInputStatusType.none,
          onReset: () async {
            await HapticFeedback.mediumImpact();
            reset(toDefault: true);
          },
        ),
```

- [ ] **Step 4: Opt in Volume switch and text fields**

Add `useInputControlFrame: true,` to every `PDSwitchField` and `PDTextField` returned by these Volume helpers:

```dart
_buildSexField
_buildAgeField
_buildHeightField
_buildWeightField
_buildTargetField
_buildDurationField
```

Example:

```dart
    return PDTextField(
      prefixIcon: Icons.calendar_month,
      labelText: AppLocalizations.of(context)!.age,
      interval: 1.0,
      fractionDigits: 0,
      controller: ageController,
      range: age != null
          ? age >= 17
              ? [17, selectedModel == Model.Schnider ? 100 : 105]
              : [1, 16]
          : [1, 16],
      onPressed: updatePDTextEditingController,
      enabled: enabled,
      useInputControlFrame: true,
    );
```

- [ ] **Step 5: Preserve current row heights**

Do not change the current `SizedBox` wrappers whose `height` is `UIHeight + 24` in this task. They now match `PDInputControlFrame`'s `controlHeight + statusHeight` geometry.

- [ ] **Step 6: Run focused checks**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
flutter analyze lib/screens/volume_screen.dart lib/components/PDCalculatorSelectorRow.dart lib/components/PDInputControlFrame.dart
```

Expected: tests pass, analyzer has no new errors.

- [ ] **Step 7: Commit Volume migration**

```bash
git add lib/screens/volume_screen.dart
git commit -m "feat: migrate volume inputs to PD frame"
```

---

### Task 7: Migrate TCI Screen To PDCalculatorSelectorRow And Opt-In Fields

**Files:**
- Modify: `lib/screens/tci_screen.dart`
- Test: `test/pd_input_control_frame_test.dart`

- [ ] **Step 1: Add imports**

Add imports near other component imports in `lib/screens/tci_screen.dart`:

```dart
import 'package:propofol_dreams_app/components/PDCalculatorSelectorRow.dart';
import 'package:propofol_dreams_app/components/PDInputControlFrame.dart';
```

- [ ] **Step 2: Make the drug/model selector control-only**

In TCI `buildModelSelector`, change selector `InputDecoration` to avoid internal status height:

```dart
              helperText: null,
              errorText: null,
```

Keep current validation colors, drug icon color, modal behavior, and model/drug selection callbacks unchanged.

- [ ] **Step 3: Replace TCI selector/reset row**

Replace the row around the `// Model selector and reset button` comment with:

```dart
        PDCalculatorSelectorRow(
          height: UIHeight,
          spacing: 8,
          resetTooltip: 'Reset TCI defaults',
          selector: buildModelSelector(settings, UIHeight),
          selectorStatusText: validationErrorText,
          selectorStatusType: hasValidationError
              ? PDInputStatusType.error
              : PDInputStatusType.none,
          onReset: () async {
            await HapticFeedback.mediumImpact();
            reset(toDefault: true);
          },
        ),
```

- [ ] **Step 4: Opt in TCI switch and text fields**

Add `useInputControlFrame: true,` to these TCI helpers:

```dart
_buildSexField
_buildAgeField
_buildHeightField
_buildWeightField
_buildTargetField
```

Example:

```dart
    return PDSwitchField(
      labelText: AppLocalizations.of(context)!.sex,
      prefixIcon: sexController.val == true
          ? isAdult ? Icons.woman : Icons.girl
          : isAdult ? Icons.man : Icons.boy,
      controller: sexController,
      switchTexts: {
        true: isAdult
            ? Sex.Female.toLocalizedString(context)
            : Sex.Girl.toLocalizedString(context),
        false: isAdult
            ? Sex.Male.toLocalizedString(context)
            : Sex.Boy.toLocalizedString(context),
      },
      onChanged: calculate,
      height: UIHeight,
      enabled: sexSwitchEnabled,
      useInputControlFrame: true,
    );
```

- [ ] **Step 5: Preserve current row heights**

Do not change the current `SizedBox` wrappers whose `height` is `UIHeight + 24` in this task.

- [ ] **Step 6: Run focused checks**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
flutter analyze lib/screens/tci_screen.dart lib/components/PDCalculatorSelectorRow.dart lib/components/PDInputControlFrame.dart
```

Expected: tests pass, analyzer has no new errors.

- [ ] **Step 7: Commit TCI migration**

```bash
git add lib/screens/tci_screen.dart
git commit -m "feat: migrate TCI inputs to PD frame"
```

---

### Task 8: Browser And Runtime Verification

**Files:**
- No source changes expected.
- Runtime artifacts: `/tmp/flutter_web.log`, `/tmp/pd-frame-*.png`

- [ ] **Step 1: Run targeted tests and analyzer**

Run:

```bash
flutter test test/pd_input_control_frame_test.dart
flutter analyze lib/components/PDInputControlFrame.dart lib/components/PDCalculatorSelectorRow.dart lib/components/legacy/PDTextField.dart lib/components/legacy/PDSwitchField.dart lib/screens/volume_screen.dart lib/screens/tci_screen.dart
```

Expected: tests pass, analyzer reports no new errors.

- [ ] **Step 2: Restart Flutter web**

Run:

```bash
lsof -ti:8080 2>/dev/null | xargs kill -9 2>/dev/null; sleep 1; nohup flutter run -d chrome --web-port 8080 > /tmp/flutter_web.log 2>&1 &
```

Expected: process starts in background.

- [ ] **Step 3: Check dev server**

Run:

```bash
sleep 12; curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
```

Expected: `200`.

- [ ] **Step 4: Scan runtime log**

Run:

```bash
rg -n "EXCEPTION|overflowed|called during build|RenderFlex children|Cannot hit test|Failed to compile|Assertion failed|used after being disposed|navigator\.vibrate" /tmp/flutter_web.log
```

Expected: no matches.

- [ ] **Step 5: Capture responsive screenshots**

Run with the existing gstack browse CLI:

```bash
B="$HOME/.config/opencode/skills/gstack/browse/dist/browse" && "$B" console --clear && "$B" goto http://localhost:8080 && "$B" wait --networkidle && "$B" responsive /tmp/pd-frame && "$B" console --errors
```

Expected: screenshots saved to:

```text
/tmp/pd-frame-mobile.png
/tmp/pd-frame-tablet.png
/tmp/pd-frame-desktop.png
```

Expected console: no app-level Flutter errors. Headless WebGL warnings are acceptable.

- [ ] **Step 6: Manual visual checks**

Open or inspect screenshots and confirm:

```text
Volume selector/reset row: selector and reset align; no right-side overflow.
TCI selector/reset row: selector and reset align; no right-side overflow.
Volume input rows: text fields/switches align and row spacing is stable.
TCI input rows: text fields/switches align and row spacing is stable.
No downstream row moves when selector or field status text appears.
```

- [ ] **Step 7: Commit verification-only fixes if needed**

If verification reveals a layout-only fix, make the minimal source edit, rerun Steps 1-6, then commit:

```bash
git status --short
git add lib/components/PDInputControlFrame.dart lib/components/PDCalculatorSelectorRow.dart lib/components/legacy/PDTextField.dart lib/components/legacy/PDSwitchField.dart lib/screens/volume_screen.dart lib/screens/tci_screen.dart test/pd_input_control_frame_test.dart
git commit -m "fix: stabilize PD input frame layout"
```

If no fixes are needed, do not create an empty commit.

---

## Plan Self-Review

Spec coverage:

- `PDInputControlFrame`: Task 2.
- `PDCalculatorSelectorRow`: Task 3.
- `PDTextField` opt-in framed rendering: Task 4.
- `PDSwitchField` opt-in framed rendering: Task 5.
- `UIConfig` rollback and migration status: Task 2.
- Volume rollout first: Task 6.
- TCI rollout second: Task 7.
- Verification: Task 8.
- Cleanup phase: intentionally not implemented in this first plan; the spec says cleanup happens after all calculator screens are migrated and verified.

Placeholder scan:

- No placeholder markers or unspecified implementation steps remain.

Type consistency:

- `PDInputStatusType` is defined in Task 2 and imported by Tasks 3, 5, 6, and 7.
- `useInputControlFrame` is added to `PDTextField` and `PDSwitchField` before screen migrations use it.
- `UIConfig.shouldUseInputControlFrame({required bool optIn})` is defined before widgets call it.
