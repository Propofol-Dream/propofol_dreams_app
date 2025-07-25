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
}