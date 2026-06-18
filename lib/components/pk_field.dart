import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/design_tokens.dart';

class PKField extends StatefulWidget {
  const PKField({
    super.key,
    this.prefixIcon,
    required this.labelText,
    required this.controller,
    required this.interval,
    required this.fractionDigits,
    required this.range,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  final IconData? prefixIcon;
  final String labelText;
  final TextEditingController controller;
  final double interval;
  final int fractionDigits;
  final List<num> range;
  final VoidCallback? onChanged;
  final bool enabled;
  final bool hasError;

  @override
  State<PKField> createState() => _PKFieldState();
}

class _PKFieldState extends State<PKField> {
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

    final val = double.tryParse(widget.controller.text);
    final isWithinRange =
        val != null && val >= widget.range[0] && val <= widget.range[1];
    final isError = (widget.hasError) ||
        (widget.enabled &&
            widget.controller.text.isNotEmpty &&
            (val == null || !isWithinRange));
    final canDecrease =
        val != null && (val - widget.interval) >= widget.range[0];
    final canIncrease =
        val != null && (val + widget.interval) <= widget.range[1];

    void onDecrease() {
      final current = double.tryParse(widget.controller.text);
      if (current != null) {
        final next = current - widget.interval;
        if (next >= widget.range[0]) {
          widget.controller.text =
              next.toStringAsFixed(widget.fractionDigits);
        } else {
          widget.controller.text =
              widget.range[0].toStringAsFixed(widget.fractionDigits);
        }
        HapticFeedback.lightImpact();
        widget.onChanged?.call();
      }
    }

    void onIncrease() {
      final current = double.tryParse(widget.controller.text);
      if (current != null) {
        final next = current + widget.interval;
        if (next <= widget.range[1]) {
          widget.controller.text =
              next.toStringAsFixed(widget.fractionDigits);
        } else {
          widget.controller.text =
              widget.range[1].toStringAsFixed(widget.fractionDigits);
        }
        HapticFeedback.lightImpact();
        widget.onChanged?.call();
      }
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.numberWithOptions(
            signed: true,
            decimal: widget.fractionDigits > 0,
          ),
          onChanged: (_) => widget.onChanged?.call(),
          style: TextStyle(
            color: widget.enabled
                ? (isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface)
                : theme.disabledColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.onPrimary,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: widget.enabled
                        ? (isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant)
                        : theme.disabledColor,
                  )
                : null,
            labelText: widget.labelText,
            labelStyle: TextStyle(
              color: widget.enabled
                  ? (isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant)
                  : theme.disabledColor,
            ),
            floatingLabelStyle: TextStyle(
              color: widget.enabled
                  ? (isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary)
                  : theme.disabledColor,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: kSp16,
              vertical: kSp12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: BorderSide(color: _borderColor(theme)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: BorderSide(color: _borderColor(theme)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadius),
              borderSide: BorderSide(
                color: isError
                    ? theme.colorScheme.error
                    : _highlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary,
                width: 2.0,
              ),
            ),
          ),
        ),
        if (widget.controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PillButton(
                  icon: Icons.remove,
                  enabled: widget.enabled && canDecrease,
                  onTap: () {
                    onDecrease();
                    _flashHighlight();
                  },
                ),
                _PillButton(
                  icon: Icons.add,
                  enabled: widget.enabled && canIncrease,
                  onTap: () {
                    onIncrease();
                    _flashHighlight();
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _borderColor(ThemeData theme) {
    if (!widget.enabled) return theme.disabledColor;
    if (_highlighted) return theme.colorScheme.primary;
    if (widget.hasError) return theme.colorScheme.error;
    if (double.tryParse(widget.controller.text) != null) {
      final val = double.parse(widget.controller.text);
      if (val < widget.range[0] || val > widget.range[1]) {
        return theme.colorScheme.error;
      }
    }
    return theme.colorScheme.outline;
  }
}

class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  Timer? _timer;

  void _onLongPress() {
    widget.onTap();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      widget.onTap();
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 44,
      height: 44,
      child: Listener(
        onPointerUp: _onPointerUp,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: widget.enabled ? widget.onTap : null,
            onLongPress: widget.enabled ? _onLongPress : null,
            child: Icon(
              widget.icon,
              color: widget.enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.disabledColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
