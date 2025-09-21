import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

import '../providers/settings.dart';
import '../utils/responsive_helper.dart';
import 'volume_screen.dart';
import 'duration_screen.dart';
import 'elemarsh_screen.dart';
import 'tci_screen.dart'; // Using original TCI screen
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currenIndex = 1; // Start with TCI screen (index 1)
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

    // Use mobile layout for small screens, web layout for larger screens
    if (ResponsiveHelper.shouldUseMobileLayout(context)) {
      return _buildMobileLayout(settings);
    } else {
      return _buildWebLayout(settings);
    }
  }

  /// Build the original mobile layout with bottom navigation
  Widget _buildMobileLayout(Settings settings) {
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
            BottomNavigationBarItem(
                icon: const Icon(Icons.ssid_chart), 
                label: AppLocalizations.of(context)!.tci), // Moved to position 1 and renamed
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

  /// Build the web/tablet layout with side navigation
  Widget _buildWebLayout(Settings settings) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail
          NavigationRail(
            selectedIndex: currenIndex,
            onDestinationSelected: (index) async {
              await HapticFeedback.lightImpact();
              setState(() {
                currenIndex = settings.currentScreenIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.hub_outlined),
                label: Text('EleMarsh'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.ssid_chart),
                label: Text(AppLocalizations.of(context)!.tci),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.science_outlined),
                label: Text(AppLocalizations.of(context)!.volume),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.schedule),
                label: Text(AppLocalizations.of(context)!.duration),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                label: Text(AppLocalizations.of(context)!.settings),
              ),
            ],
          ),
          // Vertical divider
          const VerticalDivider(thickness: 1, width: 1),
          // Main content area
          Expanded(
            child: screens[currenIndex],
          ),
        ],
      ),
    );
  }
}
