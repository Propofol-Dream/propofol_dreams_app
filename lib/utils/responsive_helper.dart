import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Responsive utilities for determining screen sizes and layout behavior
/// Used to provide different layouts for mobile, tablet, and desktop while
/// preserving the existing mobile portrait experience
class ResponsiveHelper {
  // Breakpoints based on common web standards and existing app constants
  static const double _mobileBreakpoint = 768;
  static const double _desktopBreakpoint = 1024;

  /// Returns true if the screen is mobile size (< 768px width)
  /// This preserves the existing mobile portrait layout
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  /// Returns true if the screen is tablet size (768px-1023px width)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _desktopBreakpoint;
  }

  /// Returns true if the screen is desktop size (>= 1024px width)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  /// Returns true if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Returns true if the screen should use web/tablet layout
  /// (tablet or desktop size, regardless of orientation)
  static bool shouldUseWebLayout(BuildContext context) {
    return isTablet(context) || isDesktop(context);
  }

  /// Returns true if the screen should use mobile layout
  /// (mobile size, preserving existing behavior)
  static bool shouldUseMobileLayout(BuildContext context) {
    return isMobile(context);
  }

  /// Get responsive padding based on screen size
  /// Mobile: 16px (existing horizontalSidesPaddingPixel)
  /// Tablet: 24px
  /// Desktop: 32px
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Get responsive font size multiplier
  /// Mobile: 1.0 (preserve existing sizes)
  /// Tablet: 1.1
  /// Desktop: 1.2
  static double getFontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.1;
    return 1.2;
  }

  /// Get the number of columns for responsive grids
  /// Mobile: 1 column (existing stacked layout)
  /// Tablet: 2 columns
  /// Desktop: 3 columns
  static int getColumnCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Get responsive spacing between elements
  /// Mobile: 8px (existing)
  /// Tablet: 12px
  /// Desktop: 16px
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  /// Get responsive button height
  /// Mobile: existing calculation from screens
  /// Tablet/Desktop: slightly larger for easier clicking
  static double getButtonHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (isMobile(context)) {
      // Use existing calculation from screens
      return (mediaQuery.size.aspectRatio >= 0.455
          ? mediaQuery.size.height >= 704 // screenBreakPoint1
              ? 56
              : 48
          : 48);
    }
    return 56; // Consistent larger size for tablet/desktop
  }

  /// Get responsive content width for forms and inputs
  /// Mobile: full width (existing behavior)
  /// Tablet: max 600px centered
  /// Desktop: max 800px centered
  static double getContentMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 600;
    return 800;
  }

  /// Web-safe platform detection utilities
  /// These work across all platforms including web

  /// Returns true if running on web platform
  static bool isWeb() {
    return kIsWeb;
  }

  /// Returns true if running on Android (web-safe)
  static bool isAndroid() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// Returns true if running on iOS (web-safe)
  static bool isIOS() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns true if running on mobile platform (Android or iOS)
  static bool isMobilePlatform() {
    return isAndroid() || isIOS();
  }
}