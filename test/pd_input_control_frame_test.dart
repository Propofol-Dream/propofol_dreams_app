import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
      if (methodCall.method == 'HapticFeedback.vibrate') {
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

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

  testWidgets(
    'PDCalculatorSelectorRow keeps reset button fixed while status appears',
    (tester) async {
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
      final buttonFinder = find.byTooltip('Reset model defaults');
      final buttonRectWithoutStatus = tester.getRect(buttonFinder);

      await tester.pumpWidget(buildRow(statusText: 'BMI outside model range'));
      final buttonRectWithStatus = tester.getRect(buttonFinder);

      expect(buttonRectWithStatus, buttonRectWithoutStatus);
      expect(find.text('BMI outside model range'), findsOneWidget);

      await tester.tap(buttonFinder);
      expect(resetCount, 1);
    },
  );

  testWidgets(
    'PDTextField opt-in frame preserves step callback and external status lane',
    (tester) async {
      final controller = TextEditingController(text: '5');
      addTearDown(controller.dispose);
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
    await tester.pumpAndSettle();
      expect(controller.text, '6');
      expect(callbackCount, 1);
    },
  );

  testWidgets('PDSwitchField opt-in frame preserves toggle callback', (
    tester,
  ) async {
    final controller = PDSwitchController()..val = false;
    addTearDown(controller.dispose);
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
    await tester.pumpAndSettle();
    expect(controller.val, true);
    expect(callbackCount, 1);
  });
}
