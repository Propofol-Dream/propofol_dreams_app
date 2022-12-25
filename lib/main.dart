import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'screens/home_screen.dart';
import 'providers/settings.dart';

void main() {
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

class _MyAppState extends State<MyApp> {
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
          chipTheme: ChipThemeData(
          labelStyle: TextStyle(color: Color(0xffE0E3DF))
        ),
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
      themeMode: settings.themeSelection == 0
          ? ThemeMode.light
          : settings.themeSelection == 1
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
