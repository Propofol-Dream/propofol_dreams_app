import 'dart:async';
import 'package:flutter/material.dart';
import '../config/ui_config.dart';
import 'legacy/PDTextField.dart';
import 'material3/m3_text_field.dart';

/// Adaptive TextField wrapper that switches between legacy and Material 3 implementations
///
/// This component provides seamless fallback behavior during the migration:
/// - Uses Material 3 implementation when feature flags are enabled
/// - Falls back to legacy PDTextField when flags are disabled
/// - Maintains identical API surface for drop-in replacement
/// - Respects emergency fallback settings for production safety
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.prefixIcon,
    required this.labelText,
    this.helperText = '',
    required this.interval,
    required this.fractionDigits,
    required this.controller,
    required this.onPressed,
    required this.range,
    this.timer,
    this.enabled = true,
    this.height = 56,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  final IconData? prefixIcon;
  final String labelText;
  final String helperText;
  final double interval;
  final int fractionDigits;
  final TextEditingController controller;
  final VoidCallback onPressed;
  final List<num> range;
  final Timer? timer;
  final bool enabled;
  final double? height;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    // Check if Material 3 text field should be used
    if (UIConfig.shouldUseMaterial3Components || UIConfig.useMaterial3TextField) {
      return M3TextField(
        prefixIcon: prefixIcon,
        labelText: labelText,
        helperText: helperText,
        interval: interval,
        fractionDigits: fractionDigits,
        controller: controller,
        onPressed: onPressed,
        range: range,
        timer: timer,
        enabled: enabled,
        height: height,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
      );
    }

    // Fallback to legacy implementation
    return PDTextField(
      prefixIcon: prefixIcon,
      labelText: labelText,
      helperText: helperText,
      interval: interval,
      fractionDigits: fractionDigits,
      controller: controller,
      onPressed: onPressed,
      range: range,
      timer: timer,
      enabled: enabled,
      height: height,
    );
  }
}