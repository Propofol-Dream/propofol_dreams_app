import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'screens/home_screen.dart';
import 'providers/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Provider.of<Settings>(context, listen: false).load();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => Settings()),
    ],
    child: const MyApp(),
  ));
}

// SharedPreferences prefs;
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   prefs = await SharedPreferences.getInstance();
//
//   // Rest of your code...
// }

// void main() {
//   runApp(MultiProvider(
//     providers: [
//       ChangeNotifierProvider(create: (context) => Settings()),
//     ],
//     child: const MyApp(),
//   ));
// }

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
        // print("app in resumed");
        // Provider.of<Settings>(context, listen: false).load();
        break;
      case AppLifecycleState.inactive:
        // print("app in inactive");
        break;
      case AppLifecycleState.paused:
        // print("app in paused");
        // Provider.of<Settings>(context, listen: false).save();
        break;
      case AppLifecycleState.detached:
        // print("app in detached");
        break;
      case AppLifecycleState.hidden:
      // print("app in hidden");
    }
  }

  @override
  void initState() {
    // Provider.of<Settings>(context, listen: false).load();
    // Provider.of<Settings>(context, listen: false).load().then(
    //         (value) {
    //           setState(() {
    //             _name = prefValue.getString('name')?? "";
    //             _controller = new TextEditingController(text: _name);
    //           })
    //         });

    // final settings = context.read<Settings>();
    // Provider.of<Settings>(context, listen: false).load();

    // Provider.of<Settings>(context, listen: false).load().then((value) {
    //   setState(() {
    //     print('main setState');
    //     settings.adultWeight = settings.adultWeight;
    //   });
    // });

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load().then((value) {
      setState(() {
      });
    });

    // var settings = context.read<Settings>();
    // print('settings: ${settings.isDarkTheme}');

    // loadSharedPref();
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

    // return FutureBuilder(
    //   future: Provider.of<Settings>(context).load(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.done) {
    //       return MaterialApp(
    //         debugShowCheckedModeBanner: false,
    //         title: 'Propofol Dreams',
    //         home: ,
    //       )
    //     } else {
    //       return CircularProgressIndicator();
    //     }
    //   },
    // );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Propofol Dreams',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: PDLightGreen,
          background: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        chipTheme:
        const ChipThemeData(labelStyle: TextStyle(color: Color(0xffE0E3DF))),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xff66DBB2),
          onPrimary: const Color(0xff003828),
          primaryContainer: const Color(0xff00513B),
          onPrimaryContainer: const Color(0xff83F8CD),
          background: const Color(0xff191C1B),
          onBackground: const Color(0xffE0E3DF),
          error: const Color(0xffFFB4A9),
          onError: const Color(0xff680003),
          surface: const Color(0xff191C1B),
        ),
      ),
      themeMode: settings.themeModeSelection,
      home: const HomeScreen(),
    );

  }
}
