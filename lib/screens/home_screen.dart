import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/settings.dart';
import '../utils/responsive_helper.dart';
import 'volume_screen.dart';
import 'duration_screen.dart';
import 'elemarsh_screen.dart';
import 'tci_screen_new.dart';
import 'settings_screen.dart';

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
      const TCIScreenNew(),
      const VolumeScreen(),
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

    final railDestinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.hub_outlined),
        selectedIcon: Icon(Icons.hub),
        label: Text('EleMarsh'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.ssid_chart_outlined),
        selectedIcon: Icon(Icons.ssid_chart),
        label: Text('TCI'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.science_outlined),
        selectedIcon: Icon(Icons.science),
        label: Text('Volume'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.schedule_outlined),
        selectedIcon: Icon(Icons.schedule),
        label: Text('Duration'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
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
              NavigationRail(
                selectedIndex: currenIndex,
                onDestinationSelected: (index) async {
                  await HapticFeedback.lightImpact();
                  setState(() {
                    settings.statusBarInfo = null;
                    currenIndex = settings.currentScreenIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: theme.colorScheme.surface,
                indicatorColor: theme.colorScheme.secondaryContainer,
                destinations: railDestinations,
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
                  backgroundColor: theme.colorScheme.surface,
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
