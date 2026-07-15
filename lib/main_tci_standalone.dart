import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'providers/settings.dart';
import 'screens/tci_standalone_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = Settings();
  await settings.initializeFromDisk();

  runApp(
    ChangeNotifierProvider<Settings>.value(
      value: settings,
      child: const PdtciStandaloneApp(),
    ),
  );
}

class PdtciStandaloneApp extends StatelessWidget {
  const PdtciStandaloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Propofol Dreams TCI',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
        Locale.fromSubtags(languageCode: 'zh'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ],
      theme: ThemeData(colorScheme: MaterialTheme.lightScheme()),
      darkTheme: ThemeData(colorScheme: MaterialTheme.darkScheme()),
      themeMode: settings.themeModeSelection,
      home: const TciStandaloneShell(),
    );
  }
}
