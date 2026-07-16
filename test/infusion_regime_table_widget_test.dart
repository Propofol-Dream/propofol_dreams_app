import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/components/collapsible_input_section.dart';
import 'package:propofol_dreams_app/components/infusion_regime_table.dart' as infusion_table;
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/screens/volume_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestRowData extends infusion_table.TableRowData {
  final String time;

  TestRowData(this.time);

  @override
  String get timeString => time;

  @override
  List<String> get values => ['1 mL', '2 mL', '3 mL'];
}

void main() {
  testWidgets('DataTable scrolls all rows inside a five-row viewport', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: infusion_table.DataTable(
              data: List.generate(9, (index) => TestRowData('0:${index}0')),
              headers: const ['Low', 'Target', 'High'],
              maxVisibleRows: 5,
              scrollController: controller,
            ),
          ),
        ),
      ),
    );

    expect(controller.hasClients, isTrue);
    expect(controller.offset, 0);

    await tester.drag(find.text('0:00'), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
  });

  testWidgets('Volume collapsed table scrolls beyond first five rows', (tester) async {
    SharedPreferences.setMockInitialValues({
      'adultAge': 40,
      'adultHeight': 170,
      'adultWeight': 70,
      'adultTarget': 3.0,
      'adultDuration': 60,
    });
    final settings = Settings();
    await settings.initializeFromDisk();

    tester.view.physicalSize = const Size(500, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<Settings>.value(
        value: settings,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VolumeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(CollapsibleInputSection), const Offset(0, 500), 1200);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(find.text('0:40'), const Offset(0, -140));
    await tester.pumpAndSettle();

    expect(settings.volumeTableScrollPosition, greaterThan(0));
  });
}
