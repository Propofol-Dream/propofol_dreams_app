import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/screens/tci_screen_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('TCIScreenNew renders independently', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = Settings();
    await settings.initializeFromDisk();
    await tester.binding.setSurfaceSize(const Size(1200, 800));
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

    expect(find.textContaining('Propofol'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
