import 'package:flutter/material.dart';
import '../legacy/PDTextField.dart';

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
    return PDTextField(
      m3Style: true,
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
