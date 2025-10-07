import 'package:flutter/material.dart';
import '../legacy/PDTextField.dart';

/// Material 3 TextFormField replacement for PDTextField
///
/// This component provides a modern Material 3 text input with enhanced features:
/// - Material 3 design tokens and styling
/// - Responsive height calculation
/// - Enhanced visual feedback for validation states
/// - Uses the proven PDTextField as the base implementation
class M3TextField extends StatelessWidget {
  const M3TextField({
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
    this.height,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  final String labelText;
  final String helperText;
  final IconData? prefixIcon;
  final double interval;
  final int fractionDigits;
  final TextEditingController controller;
  final List<num> range;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool enabled;
  final dynamic timer;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // Use the enhanced PDTextField with Material 3 styling
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2.0,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
        ),
      ),
      child: PDTextField(
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
      ),
    );
  }
}