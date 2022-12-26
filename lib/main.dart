import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        Provider.of<Settings>(context, listen: false).load();
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        Provider.of<Settings>(context, listen: false).save();
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  void initState() {
    Provider.of<Settings>(context, listen: false).load();
    // Provider.of<Settings>(context, listen: false).load().then(
    //         (value) {
    //           setState(() {
    //             _name = prefValue.getString('name')?? "";
    //             _controller = new TextEditingController(text: _name);
    //           })
    //         });



    super.initState();
    WidgetsBinding.instance.addObserver(this);


    var settings = context.read<Settings>();
    // print('settings: ${settings.isDarkTheme}');

    // loadSharedPref();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  didChangeDependencies() {
    // loadSharedPref();
  }

  // void loadSharedPref() async {
  //   print('loadSharedPref');
  //   var setting = context.watch<Settings>();
  //   var pref = await SharedPreferences.getInstance();
  //   print('pref: ${pref.getBool('isDarkTheme')}');
  //   setting.isDarkTheme = pref.getBool('isDarkTheme') ?? false;
  //   print('setting: ${setting.isDarkTheme}');
  // }

  // void saveSharedPref() async {
  //   var setting = Provider.of<Settings>(context, listen: false);
  //   var pref = await SharedPreferences.getInstance();
  //   print('pref: ${pref.getBool('isDarkTheme')}');
  //   pref.setBool('isDarkTheme', setting.isDarkTheme);
  //   print('setting: ${setting.isDarkTheme}');
  // }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

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
            ChipThemeData(labelStyle: TextStyle(color: Color(0xffE0E3DF))),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xff66DBB2),
          onPrimary: Color(0xff003828),
          primaryContainer: Color(0xff00513B),
          onPrimaryContainer: Color(0xff83F8CD),
          background: Color(0xff191C1B),
          onBackground: Color(0xffE0E3DF),
          error: Color(0xffFFB4A9),
          onError: Color(0xff680003),
          surface: Color(0xff191C1B),
        ),
      ),
      themeMode: settings.themeModeSelection,
      home: const HomeScreen(),
    );
  }
}
