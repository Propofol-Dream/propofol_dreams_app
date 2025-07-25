import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

import '../providers/settings.dart';
import 'volume_screen.dart';
import 'duration_screen.dart';
import 'elemarsh_screen.dart';
import 'tci_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currenIndex = 1;
  final screens = [
    EleMarshScreen(),
    const TCIScreen(), // Moved to position 1 (TCI screen)
    const VolumeScreen(),
    const DurationScreen(),
    const SettingsScreen(),
    // TestScreen()
  ];

  @override
  void initState() {
    super.initState();
    
    // Settings are already loaded - initialize controllers with final values
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
  }

  void _setControllersFromSettings(Settings settings) {
    currenIndex = settings.currentScreenIndex;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    //this is to set status bar text color
    settings.isDarkTheme!
        ? SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light)
        : SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      // body: SingleChildScrollView(
      // physics: MediaQuery
      //     .of(context)
      //     .viewInsets
      //     .bottom <= 0
      //     ? const NeverScrollableScrollPhysics()
      //     : const BouncingScrollPhysics(),
      // child: screens[currenIndex]),
      body: Column(
        children: [
          Expanded(
            child:
                screens[currenIndex], // no need for SingleChildScrollView here
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currenIndex,
          onTap: (index) async {
            await HapticFeedback.heavyImpact();
            setState(() {
              currenIndex = settings.currentScreenIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.hub_outlined), label: 'EleMarsh'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.local_pharmacy_outlined), label: 'TCI'), // Moved to position 1 and renamed
            BottomNavigationBarItem(
                icon: const Icon(Icons.science_outlined),
                label: AppLocalizations.of(context)!.volume),
            BottomNavigationBarItem(
                icon: const Icon(Icons.schedule),
                label: AppLocalizations.of(context)!.duration),
            BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: AppLocalizations.of(context)!.settings),
            // BottomNavigationBarItem(
            //     icon:  Icon(Icons.science),
            //     label: 'Test'),
          ]),
    );
  }
}
