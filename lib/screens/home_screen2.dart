import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings.dart';
import 'volume_screen.dart';
import 'duration_screen.dart';
import 'elemarsh_screen.dart';
import 'settings_screen.dart';

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({Key? key}) : super(key: key);

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
   int currenIndex = 3;
  final screens = [
    VolumeScreen(),
    EleMarshtScreen(),
    DurationScreen(),
    SettingsScreen()
  ];

  @override
  void initState() {
    final settings = context.read<Settings>();
    currenIndex = settings.currentScreenIndex;
    load().then((value) {
      setState(() {
      });
    });
    super.initState();
  }

  Future<void> load() async {
    final settings = context.read<Settings>();
    currenIndex = settings.currentScreenIndex =3;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    //this is to set status bar text color
    settings.isDarkTheme?
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light):
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      body: SingleChildScrollView(
          physics: MediaQuery
              .of(context)
              .viewInsets
              .bottom <= 0
              ? NeverScrollableScrollPhysics()
              : BouncingScrollPhysics(),
          child: screens[currenIndex]),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currenIndex,
          onTap: (index) async {
            await HapticFeedback.heavyImpact();
            setState(() {
              currenIndex = settings.currentScreenIndex = index;
            });
          },
          items:[
            BottomNavigationBarItem(
                icon:  Icon(Icons.science_outlined),
                label: 'Volume'),
            BottomNavigationBarItem(
                icon: Icon(Icons.hub_outlined),
                label: 'EleMarsh'),
            BottomNavigationBarItem(
                icon:  Icon(Icons.schedule),
                label: 'Duration'),
            BottomNavigationBarItem(
                icon:  Icon(Icons.settings),
                label: 'Settings'),
          ]),
    );
  }
}
