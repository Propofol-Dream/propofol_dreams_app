import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'screens/home_screen.dart';
import 'providers/settings.dart';

import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => Settings()),
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
        // Provider.of<Settings>(context, listen: false).load();
        break;
      case AppLifecycleState.inactive:
        print("app inactive");
        break;
      case AppLifecycleState.paused:
        print("app paused");
        // Provider.of<Settings>(context, listen: false).save();
        break;
      case AppLifecycleState.detached:
        print("app detached");
        break;
      case AppLifecycleState.hidden:
        print("app in hidden");
    }
  }

  @override
  void initState() {

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load().then((value) {
      setState(() {
      });
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  Future<void> load() async {
    var pref = await SharedPreferences.getInstance();
    final settings = context.read<Settings>();

    if (pref.containsKey('themeMode')) {

      String? themeMode = pref.getString('themeMode');
      switch (themeMode) {
        case 'ThemeMode.light':
          {
            settings.themeModeSelection = ThemeMode.light;
          }
          break;

        case 'ThemeMode.dark':
          {
            settings.themeModeSelection = ThemeMode.dark;
          }
          break;

        case 'ThemeMode.system':
          {
            settings.themeModeSelection = ThemeMode.system;
          }
          break;

        default:
          {
            settings.themeModeSelection = ThemeMode.system;
          }
          break;
      }
    }
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
      theme: ThemeData(colorScheme: MaterialTheme.lightScheme().toColorScheme()),
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
      darkTheme: ThemeData(colorScheme: MaterialTheme.darkScheme().toColorScheme()),
      themeMode: settings.themeModeSelection,
      home: const HomeScreen(),
    );

  }
}
