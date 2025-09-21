import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A wrapper widget that provides different layouts based on screen size
/// Automatically chooses the appropriate layout while preserving mobile behavior
class AdaptiveLayout extends StatelessWidget {
  /// The widget to display on mobile screens (< 768px)
  /// This preserves the existing mobile portrait layout
  final Widget mobileLayout;

  /// The widget to display on tablet screens (768px-1023px)
  /// If null, falls back to mobileLayout
  final Widget? tabletLayout;

  /// The widget to display on desktop screens (>= 1024px)
  /// If null, falls back to tabletLayout or mobileLayout
  final Widget? desktopLayout;

  const AdaptiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktopLayout != null) {
      return desktopLayout!;
    }

    if (ResponsiveHelper.isTablet(context) && tabletLayout != null) {
      return tabletLayout!;
    }

    // Default to mobile layout (preserves existing behavior)
    return mobileLayout;
  }
}

/// A responsive container that adapts its padding and constraints
/// based on screen size while preserving mobile behavior
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding;

    if (ResponsiveHelper.isDesktop(context) && desktopPadding != null) {
      padding = desktopPadding!;
    } else if (ResponsiveHelper.isTablet(context) && tabletPadding != null) {
      padding = tabletPadding!;
    } else if (mobilePadding != null) {
      padding = mobilePadding!;
    } else {
      // Use responsive helper defaults
      final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);
      padding = EdgeInsets.symmetric(horizontal: horizontalPadding);
    }

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    // Apply max width constraint for larger screens
    if (maxWidth != null && !ResponsiveHelper.isMobile(context)) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A responsive row that stacks vertically on mobile and horizontally on larger screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final space = spacing ?? ResponsiveHelper.getSpacing(context);

    if (ResponsiveHelper.shouldUseMobileLayout(context)) {
      // Stack vertically on mobile (preserves existing behavior)
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((child) => Padding(
          padding: EdgeInsets.symmetric(vertical: space / 2),
          child: child,
        )).toList(),
      );
    } else {
      // Arrange horizontally on larger screens
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children.map((child) => Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: space / 2),
            child: child,
          ),
        )).toList(),
      );
    }
  }
}

/// A responsive grid that adapts the number of columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    int columns;

    if (ResponsiveHelper.isDesktop(context)) {
      columns = desktopColumns ?? 3;
    } else if (ResponsiveHelper.isTablet(context)) {
      columns = tabletColumns ?? 2;
    } else {
      columns = mobileColumns ?? 1;
    }

    final space = spacing ?? ResponsiveHelper.getSpacing(context);

    if (columns == 1) {
      // Single column layout (mobile)
      return Column(
        children: children.map((child) => Padding(
          padding: EdgeInsets.symmetric(vertical: space / 2),
          child: child,
        )).toList(),
      );
    }

    // Multi-column layout for larger screens
    List<Widget> rows = [];
    for (int i = 0; i < children.length; i += columns) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < columns && i + j < children.length; j++) {
        rowChildren.add(Expanded(
          child: Padding(
            padding: EdgeInsets.all(space / 2),
            child: children[i + j],
          ),
        ));
      }

      // Fill remaining spaces in incomplete rows
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(Row(children: rowChildren));
    }

    return Column(children: rows);
  }
}