import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings.dart';
import 'volume_screen.dart';
import 'duration_screen.dart';
import 'pump_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
   int currenIndex = 1;
  final screens = [
    VolumeScreen(),
    DurationScreen(),
    PumpScreen(),
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
    var pref = await SharedPreferences.getInstance();
    if (pref.containsKey('currentScreenIndex')) {
      settings.currentScreenIndex = pref.getInt('currentScreenIndex')!;
    }else{
      settings.currentScreenIndex = 0;
    }

    currenIndex = settings.currentScreenIndex;


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
                icon:  Icon(Icons.schedule),
                label: 'Duration'),
            BottomNavigationBarItem(
                icon: Icon(Icons.tune),
                label: 'TCI'),
            BottomNavigationBarItem(
                icon:  Icon(Icons.settings),
                label: 'Settings'),
          ]),
    );
  }
}
