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
}
