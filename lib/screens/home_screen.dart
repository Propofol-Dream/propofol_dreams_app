import 'package:flutter/material.dart';

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
  int currenIndex = 0;
  final screens = [
    VolumeScreen(),
    DurationScreen(),
    PumpScreen(),
    SettingsScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currenIndex],
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currenIndex,
          onTap: (index) => setState(() {
                currenIndex = index;
              }),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.science_outlined), label: 'Volume'),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: 'Duration'),
            BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'TCI'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
          ]),
    );
  }
}
