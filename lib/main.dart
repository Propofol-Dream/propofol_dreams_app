import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'providers/settings.dart';

import 'theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings from disk before UI renders
  final settings = Settings();
  await settings.initializeFromDisk();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<Settings>.value(value: settings),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app resumed");
        break;
      case AppLifecycleState.inactive:
        print("app inactive");
        break;
      case AppLifecycleState.paused:
        print("app paused - saving settings");
        // Save all settings when app pauses to ensure data persistence
        Provider.of<Settings>(context, listen: false).saveAllSettings();
        break;
      case AppLifecycleState.detached:
        print("app detached - saving settings");
        // Save all settings when app is being terminated
        Provider.of<Settings>(context, listen: false).saveAllSettings();
        break;
      case AppLifecycleState.hidden:
        print("app in hidden");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Settings are already initialized in main() - no async loading needed
  }

  @override
  void dispose() {
    // Save settings one final time before disposal
    Provider.of<Settings>(context, listen: false).saveAllSettings();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Propofol Dreams',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSwatch().copyWith(
      //     primary: PDLightGreen,
      //     secondary: PDLightNavy,
      //     background: Colors.white,
      //   ),
      // ),
      localizationsDelegates: [
        AppLocalizations.delegate, // Add this line
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,

      ],
      supportedLocales: [
        Locale('en'), // English
        Locale('ja'), // Japanese
        Locale.fromSubtags(languageCode: 'zh'), // generic Chinese 'zh'
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ), // generic simplified Chinese 'zh_Hans'
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ), // generic traditional Chinese 'zh_Hant'
      ],
      theme: ThemeData(colorScheme: MaterialTheme.lightScheme()),
      // darkTheme: ThemeData.dark().copyWith(
      //   chipTheme:
      //   const ChipThemeData(labelStyle: TextStyle(color: Color(0xffE0E3DF))),
      //   colorScheme: ColorScheme.fromSwatch().copyWith(
      //     primary: const Color(0xff66DBB2),
      //     onPrimary: const Color(0xff003828),
      //     primaryContainer: const Color(0xff00513B),
      //     onPrimaryContainer: const Color(0xff83F8CD),
      //     background: const Color(0xff191C1B),
      //     onBackground: const Color(0xffE0E3DF),
      //     error: const Color(0xffFFB4A9),
      //     onError: const Color(0xff680003),
      //     surface: const Color(0xff191C1B),
      //   ),
      // ),
      darkTheme: ThemeData(colorScheme: MaterialTheme.darkScheme()),
      themeMode: settings.themeModeSelection,
      home: const HomeScreen(),
    );

  }
}
