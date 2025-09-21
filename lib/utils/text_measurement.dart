import 'package:flutter/material.dart';

/// Utility class for measuring text dimensions
class TextMeasurement {
  /// Measure the width of text with given style
  static double measureTextWidth({
    required String text,
    required TextStyle style,
    double? maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    
    textPainter.layout(maxWidth: maxWidth ?? double.infinity);
    return textPainter.size.width;
  }
  
  /// Calculate the optimal width for drug selector field
  /// Accounts for the longest drug name plus UI elements (icon, padding, borders)
  static double calculateDrugSelectorWidth({
    required BuildContext context,
    required List<String> drugNames,
    required TextStyle textStyle,
  }) {
    double maxTextWidth = 0.0;

    // Find the widest drug name
    for (final drugName in drugNames) {
      final width = measureTextWidth(
        text: drugName,
        style: textStyle,
      );
      if (width > maxTextWidth) {
        maxTextWidth = width;
      }
    }

    // Add padding for UI elements:
    // - Left icon: ~40px
    // - Right dropdown arrow: ~40px
    // - Internal padding: ~32px (16px left + 16px right)
    // - Border and focus ring: ~4px
    const double uiElementsWidth = 40 + 40 + 32 + 4;

    final calculatedWidth = maxTextWidth + uiElementsWidth;

    // Apply responsive constraints
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAllowedWidth = screenWidth * 0.7; // Max 70% of screen width
    final minAllowedWidth = screenWidth * 0.3; // Min 30% of screen width

    // Ensure we respect the constraints
    final constrainedWidth = calculatedWidth.clamp(minAllowedWidth, maxAllowedWidth);

    return constrainedWidth;
  }

  /// Calculate the optimal width for segmented control fields (like EleMarsh flow control)
  /// Accounts for the longest segment text plus UI elements
  static double calculateSegmentedControlWidth({
    required BuildContext context,
    required List<String> segmentLabels,
    required TextStyle textStyle,
  }) {
    double maxTextWidth = 0.0;

    // Find the widest segment label
    for (final label in segmentLabels) {
      final width = measureTextWidth(
        text: label,
        style: textStyle,
      );
      if (width > maxTextWidth) {
        maxTextWidth = width;
      }
    }

    // For segmented controls with 2 segments:
    // - Text width for both segments: maxTextWidth * 2
    // - Segment divider: ~2px
    // - Internal padding: ~48px total (24px per segment - increased for mobile)
    // - Border and focus ring: ~8px (increased for mobile touch targets)
    final segmentCount = segmentLabels.length;
    const double segmentDividerWidth = 2.0;
    const double paddingPerSegment = 24.0; // Increased from 16px
    const double borderWidth = 8.0; // Increased from 4px

    final calculatedWidth = (maxTextWidth * segmentCount) +
                           (segmentDividerWidth * (segmentCount - 1)) +
                           (paddingPerSegment * segmentCount) +
                           borderWidth;

    // Apply responsive constraints - more generous for segmented controls
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAllowedWidth = screenWidth * 0.8; // Max 80% of screen width (increased)
    final minAllowedWidth = screenWidth * 0.4; // Min 40% of screen width (increased)

    // For mobile devices, ensure minimum width to prevent text wrapping
    final mobileMinWidth = screenWidth * 0.45; // 45% minimum for mobile
    final finalMinWidth = screenWidth < 768 ? mobileMinWidth : minAllowedWidth;

    // Ensure we respect the constraints
    final constrainedWidth = calculatedWidth.clamp(finalMinWidth, maxAllowedWidth);

    return constrainedWidth;
  }
}