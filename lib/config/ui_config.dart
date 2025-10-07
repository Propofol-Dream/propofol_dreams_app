import 'package:flutter/foundation.dart';

/// UI Configuration for Material 3 Migration
///
/// This class manages feature flags for the gradual migration from custom PD components
/// to Material 3 design system. All flags start as false to ensure no disruption to
/// existing functionality.
///
/// Migration phases:
/// - Phase 1: Foundation (directories, flags, wrappers)
/// - Phase 2: Component replacement (dropdowns, text fields)
/// - Phase 3: Enhanced features (charts, advanced layouts)
/// - Phase 4: Per-screen migration
class UIConfig {
  // ===========================================================================
  // GLOBAL MATERIAL 3 FEATURE FLAGS
  // ===========================================================================

  /// Master flag for all Material 3 components
  /// When false, all components fall back to legacy PD implementations
  static const bool useMaterial3Components = false;

  /// Enable Material 3 navigation components (NavigationBar, NavigationRail, NavigationDrawer)
  static const bool useMaterial3Navigation = false;

  /// Enable Material 3 data tables with sorting, filtering, and selection
  static const bool useMaterial3Tables = false;

  /// Enable enhanced data visualization (charts, graphs, pharmacokinetic curves)
  static const bool enableDataVisualization = false;

  // ===========================================================================
  // PER-COMPONENT FEATURE FLAGS
  // ===========================================================================

  /// Replace PDTextField with Material 3 TextFormField
  static const bool useMaterial3TextField = false;

  /// Replace PDSegmentedControl with Material 3 SegmentedButton
  static const bool useMaterial3SegmentedButton = false;

  /// Replace PDModelSelectorModal with Material 3 DropdownMenu
  static const bool useMaterial3DropdownMenu = false;

  /// Replace PDSwitchField with Material 3 Switch
  static const bool useMaterial3Switch = false;

  // ===========================================================================
  // PER-SCREEN MIGRATION FLAGS
  // ===========================================================================

  /// Enable Material 3 enhancements for TCI screen
  static const bool tciScreenMaterial3 = false;

  /// Enable Material 3 enhancements for Volume screen
  static const bool volumeScreenMaterial3 = false;

  /// Enable Material 3 enhancements for Duration screen
  static const bool durationScreenMaterial3 = false;

  /// Enable Material 3 enhancements for EleMarsh screen
  static const bool eleMarshScreenMaterial3 = false;

  /// Enable Material 3 enhancements for Settings screen
  static const bool settingsScreenMaterial3 = false;

  // ===========================================================================
  // RESPONSIVE DESIGN ENHANCEMENTS
  // ===========================================================================

  /// Enable enhanced desktop layouts with multi-pane views
  static const bool enableDesktopEnhancements = false;

  /// Enable enhanced tablet layouts with adaptive grids
  static const bool enableTabletEnhancements = false;

  /// Enable landscape-specific optimizations
  static const bool enableLandscapeOptimizations = false;

  // ===========================================================================
  // DEVELOPMENT AND TESTING FLAGS
  // ===========================================================================

  /// Show Material 3 migration controls in settings (debug builds only)
  static bool get showMigrationControls => kDebugMode;

  /// Enable A/B testing between old and new components
  static const bool enableABTesting = false;

  /// Log component usage for migration analytics
  static const bool enableUsageLogging = false;

  // ===========================================================================
  // SAFETY AND ROLLBACK FLAGS
  // ===========================================================================

  /// Emergency fallback flag - immediately disables all Material 3 features
  static bool _emergencyFallback = false;

  /// Check if emergency fallback is active
  static bool get emergencyFallbackActive => _emergencyFallback;

  /// Activate emergency fallback (can be called from error handlers)
  static void activateEmergencyFallback() {
    _emergencyFallback = true;
    if (kDebugMode) {
      print('🚨 UIConfig: Emergency fallback activated - all Material 3 features disabled');
    }
  }

  /// Deactivate emergency fallback (developer use only)
  static void deactivateEmergencyFallback() {
    if (kDebugMode) {
      _emergencyFallback = false;
      print('✅ UIConfig: Emergency fallback deactivated');
    }
  }

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  /// Master check for any Material 3 feature being enabled
  /// Takes into account emergency fallback
  static bool get anyMaterial3Enabled =>
    !_emergencyFallback && (
      useMaterial3Components ||
      useMaterial3Navigation ||
      useMaterial3Tables ||
      enableDataVisualization ||
      tciScreenMaterial3 ||
      volumeScreenMaterial3 ||
      durationScreenMaterial3 ||
      eleMarshScreenMaterial3 ||
      settingsScreenMaterial3
    );

  /// Check if Material 3 components should be used (respects emergency fallback)
  static bool get shouldUseMaterial3Components =>
    !_emergencyFallback && useMaterial3Components;

  /// Check if specific TCI screen enhancements should be enabled
  static bool get shouldEnhanceTCIScreen =>
    !_emergencyFallback && (useMaterial3Components || tciScreenMaterial3);

  /// Check if specific dropdown enhancements should be enabled
  static bool get shouldUseMaterial3Dropdown =>
    !_emergencyFallback && (useMaterial3Components || useMaterial3DropdownMenu);

  /// Check if data visualization should be enabled
  static bool get shouldShowDataVisualization =>
    !_emergencyFallback && enableDataVisualization;

  // ===========================================================================
  // MIGRATION UTILITIES
  // ===========================================================================

  /// Get current migration status summary
  static Map<String, dynamic> getMigrationStatus() {
    return {
      'emergencyFallback': _emergencyFallback,
      'anyMaterial3Enabled': anyMaterial3Enabled,
      'components': {
        'material3Components': useMaterial3Components,
        'material3Navigation': useMaterial3Navigation,
        'material3Tables': useMaterial3Tables,
        'dataVisualization': enableDataVisualization,
      },
      'screens': {
        'tciScreen': tciScreenMaterial3,
        'volumeScreen': volumeScreenMaterial3,
        'durationScreen': durationScreenMaterial3,
        'eleMarshScreen': eleMarshScreenMaterial3,
        'settingsScreen': settingsScreenMaterial3,
      },
      'responsive': {
        'desktopEnhancements': enableDesktopEnhancements,
        'tabletEnhancements': enableTabletEnhancements,
        'landscapeOptimizations': enableLandscapeOptimizations,
      },
    };
  }

  /// Validate configuration consistency
  static List<String> validateConfiguration() {
    final issues = <String>[];

    // Check for logical inconsistencies
    if (tciScreenMaterial3 && !useMaterial3Components && !useMaterial3DropdownMenu) {
      issues.add('TCI screen Material 3 enabled but no Material 3 components enabled');
    }

    if (enableDataVisualization && !anyMaterial3Enabled) {
      issues.add('Data visualization enabled but no Material 3 features enabled');
    }

    if (enableDesktopEnhancements && !useMaterial3Components) {
      issues.add('Desktop enhancements require Material 3 components');
    }

    return issues;
  }
}