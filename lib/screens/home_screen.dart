import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/settings.dart';
import '../utils/responsive_helper.dart';
import '../models/volume_mode.dart';
import 'volume_screen.dart';
import 'volume_plus_screen.dart';
import 'duration_screen.dart';
import 'elemarsh_screen.dart';
import 'tci_screen.dart';
import 'settings_screen_m3.dart'; // M3 migrated

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currenIndex = 1;

  List<Widget> _getScreens(Settings settings) {
    return [
      EleMarshScreen(),
      const TCIScreen(),
      settings.volumeMode == VolumeMode.Volume
          ? const VolumeScreen()
          : const VolumePlusScreen(),
      const DurationScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
  }

  void _setControllersFromSettings(Settings settings) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      settings.statusBarInfo = null;
    });
    currenIndex = settings.currentScreenIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    settings.isDarkTheme == true
        ? SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light)
        : SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return _buildShell(settings);
  }

  Widget _buildRailItem(int index, IconData icon, IconData selectedIcon, String label, ThemeData theme, Settings settings) {
    final selected = currenIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            settings.statusBarInfo = null;
            currenIndex = settings.currentScreenIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: selected
              ? BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, color: selected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: selected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  /// On web, wraps [child] in `Center > ConstrainedBox(maxWidth: 1440)` so the
  /// body content is constrained and centered on wide browser windows. The
  /// `Scaffold` chrome (AppBar, bottomNavigationBar / status bar) sits
  /// **outside** this constraint and stays full-width.
  ///
  /// Added in L7 (LAYOUT_MIGRATION_SPEC.md). Returns [child] unchanged on
  /// non-web platforms.
  Widget _wrapWithWebMaxWidth(Widget child) {
    if (!kIsWeb) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: SizedBox(
              width: constraints.maxWidth.clamp(0.0, 1440.0),
              height: constraints.maxHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Shared shell that renders the outer [Scaffold] with either a mobile
  /// [NavigationBar] or a desktop [NavigationRail] side nav depending on
  /// the breakpoint returned by [ResponsiveHelper.shouldUseMobileLayout].
  Widget _buildShell(Settings settings) {
    final screens = _getScreens(settings);
    final theme = Theme.of(context);
    final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);

    final navDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.hub_outlined),
        selectedIcon: Icon(Icons.hub),
        label: 'EleMarsh',
      ),
      NavigationDestination(
        icon: Icon(Icons.ssid_chart_outlined),
        selectedIcon: Icon(Icons.ssid_chart),
        label: 'TCI',
      ),
      NavigationDestination(
        icon: Icon(Icons.science_outlined),
        selectedIcon: Icon(Icons.science),
        label: 'Volume',
      ),
      NavigationDestination(
        icon: Icon(Icons.schedule_outlined),
        selectedIcon: Icon(Icons.schedule),
        label: 'Duration',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    final bodyContent = useMobile
        ? Column(
            children: [
              Expanded(child: screens[currenIndex]),
            ],
          )
        : Row(
            children: [
              Container(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildRailItem(0, Icons.hub_outlined, Icons.hub, 'EleMarsh', theme, settings),
                    _buildRailItem(1, Icons.ssid_chart_outlined, Icons.ssid_chart, 'TCI', theme, settings),
                    _buildRailItem(2, Icons.science_outlined, Icons.science, 'Volume', theme, settings),
                    _buildRailItem(3, Icons.schedule_outlined, Icons.schedule, 'Duration', theme, settings),
                    _buildRailItem(4, Icons.settings_outlined, Icons.settings, 'Settings', theme, settings),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: _wrapWithWebMaxWidth(screens[currenIndex]),
              ),
            ],
          );

    final body = useMobile ? _wrapWithWebMaxWidth(bodyContent) : bodyContent;

    return Scaffold(
      body: body,
      bottomNavigationBar: useMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NavigationBar(
                  selectedIndex: currenIndex,
                  onDestinationSelected: (index) async {
                    await HapticFeedback.heavyImpact();
                    setState(() {
                      settings.statusBarInfo = null;
                      currenIndex = settings.currentScreenIndex = index;
                    });
                  },
                  indicatorColor: theme.colorScheme.secondaryContainer,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  height: 80,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: navDestinations,
                ),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        appVersion,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildStatusBar(settings),
    );
  }

  /// Desktop status bar showing model / drug / pump info from the active screen.
  Widget _buildStatusBar(Settings settings) {
    final info = settings.statusBarInfo;
    if (info == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            info,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            appVersion,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
