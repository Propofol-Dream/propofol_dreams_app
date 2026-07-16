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
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surfaceSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

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

Finder _textFieldWithLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

void main() {
  testWidgets('TCIScreenNew renders desktop workstation independently',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(1200, 800));

    expect(find.byKey(const ValueKey('tci-new-desktop-workstation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-desktop-results-area')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-desktop-input-rail')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-mobile-flow')), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.textContaining('Propofol'), findsWidgets);
  });

  testWidgets('TCIScreenNew keeps table-first structure on tablet width',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(768, 800));

    expect(find.byKey(const ValueKey('tci-new-desktop-workstation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-table-card')), findsOneWidget);
    expect(find.textContaining('eBIS'), findsWidgets);
  });

  testWidgets('TCIScreenNew renders mobile pdtci flow with bottom controls',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(390, 844));

    expect(find.byKey(const ValueKey('tci-new-mobile-flow')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-mobile-results-area')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-mobile-input-sheet')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-desktop-workstation')),
        findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.textContaining('Propofol'), findsWidgets);
  });

  testWidgets('TCIScreenNew input panel is target-first', (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(1200, 800));

    final target = find.byKey(const ValueKey('tci-new-target-primary'));
    final drug = find.byKey(const ValueKey('tci-new-drug-row'));
    final demographics = find.byKey(const ValueKey('tci-new-demographics-row'));
    final size = find.byKey(const ValueKey('tci-new-size-row'));

    expect(target, findsOneWidget);
    expect(drug, findsOneWidget);
    expect(demographics, findsOneWidget);
    expect(size, findsOneWidget);
    expect(tester.getTopLeft(target).dy, lessThan(tester.getTopLeft(drug).dy));
    expect(tester.getTopLeft(drug).dy,
        lessThan(tester.getTopLeft(demographics).dy));
    expect(tester.getTopLeft(demographics).dy,
        lessThan(tester.getTopLeft(size).dy));

    final weight = _textFieldWithLabel('Weight');
    final height = _textFieldWithLabel('Height');
    expect(weight, findsOneWidget);
    expect(height, findsOneWidget);
    expect(
        tester.getTopLeft(weight).dx, lessThan(tester.getTopLeft(height).dx));
  });

  testWidgets('TCIScreenNew shows eBIS in input panel next to target',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(1200, 800));

    final table = find.byKey(const ValueKey('tci-new-table-card'));

    expect(table, findsOneWidget);
    expect(find.textContaining('eBIS'), findsWidgets);
  });

  testWidgets('TCIScreenNew opens Set Clock Time modal after row tap',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(1200, 800));

    await tester.tap(find.byKey(const ValueKey('tci-new-table-card')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tci-new-sync-panel')), findsNothing);
    expect(find.byKey(const ValueKey('tci-new-sync-modal')), findsOneWidget);
    expect(find.text('Set Clock Time'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('tci-new-sync-hour-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('tci-new-sync-minute-field')),
        findsOneWidget);
    expect(find.text('Set Time'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets(
      'TCIScreenNew does not keep sync UI when recalculation is invalid',
      (tester) async {
    await _pumpTciScreen(tester, surfaceSize: const Size(1200, 800));

    await tester.tap(find.byKey(const ValueKey('tci-new-table-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tci-new-sync-modal')), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    await tester.enterText(_textFieldWithLabel('Age'), '999');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tci-new-sync-panel')), findsNothing);
    expect(find.byKey(const ValueKey('tci-new-sync-modal')), findsNothing);
  });
}
