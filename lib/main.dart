import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'constants.dart';
import 'screens/home_screen.dart';
import 'providers/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Settings()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          // primarySwatch: PDGreen,
          // primaryColor: PDGreen,
          colorScheme: ColorScheme.fromSeed(
              seedColor: PDGreen,
              primary: PDGreen,
              secondary: PDNavy),
          // colorScheme:
        ),
        home: const HomeScreen(),

      ),
    );
  }
}
