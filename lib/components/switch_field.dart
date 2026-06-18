import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/design_tokens.dart';

class SwitchField extends StatefulWidget {
  const SwitchField({
    super.key,
    this.prefixIcon,
    required this.labelText,
    required this.value,
    required this.switchLabels,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData? prefixIcon;
  final String labelText;
  final bool value;
  final Map<bool, String> switchLabels;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  State<SwitchField> createState() => _SwitchFieldState();
}

class _SwitchFieldState extends State<SwitchField> {
  bool _highlighted = false;
  Timer? _highlightTimer;

  void _flashHighlight() {
    setState(() => _highlighted = true);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _highlighted = false);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = widget.switchLabels[widget.value] ?? '';

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          controller: TextEditingController(text: displayText),
          style: TextStyle(
            color: widget.enabled
                ? theme.colorScheme.onSurface
                : theme.disabledColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.enabled
                ? theme.colorScheme.surfaceContainerHighest
                : null,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: widget.enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.disabledColor,
                  )
                : null,
            labelText: widget.labelText,
            labelStyle: TextStyle(
              color: widget.enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.disabledColor,
            ),
            floatingLabelStyle: TextStyle(
              color: _highlighted
                  ? theme.colorScheme.primary
                  : widget.enabled
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: kSp16,
              vertical: kSp12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: BorderSide(
                color: _highlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: BorderSide(
                color: _highlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2.0,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Transform.translate(
            offset: const Offset(0, 2),
            child: Switch(
              value: widget.value,
              activeThumbColor: theme.colorScheme.primary,
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              inactiveThumbColor: widget.enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.disabledColor,
              inactiveTrackColor: widget.enabled
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1)
                  : theme.disabledColor.withValues(alpha: 0.1),
              onChanged: widget.enabled
                  ? (v) {
                      HapticFeedback.lightImpact();
                      _flashHighlight();
                      widget.onChanged(v);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
