import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import '../config/ui_config.dart';
import 'PDInputControlFrame.dart';

const double _statusHeight = 24;

class PDCalculatorSelectorRow extends StatelessWidget {
  const PDCalculatorSelectorRow({
    super.key,
    required this.selector,
    required this.onReset,
    required this.resetTooltip,
    this.selectorStatusText,
    this.selectorStatusType = PDInputStatusType.none,
    this.height = 56,
    this.spacing = kSp8,
  });

  final Widget selector;
  final VoidCallback onReset;
  final String resetTooltip;
  final String? selectorStatusText;
  final PDInputStatusType selectorStatusType;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final resetButton = SizedBox(
      height: height,
      width: height,
      child: Tooltip(
        message: resetTooltip,
        child: Semantics(
          button: true,
          label: resetTooltip,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(kRadius),
              ),
            ),
            onPressed: onReset,
            child: const Icon(Icons.restart_alt_outlined),
          ),
        ),
      ),
    );

    if (!UIConfig.shouldUseInputControlFrame(optIn: true)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: SizedBox(height: height, child: selector)),
          SizedBox(width: spacing),
          resetButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: PDInputControlFrame(
            controlHeight: height,
            statusHeight: _statusHeight,
            statusText: selectorStatusText,
            statusType: selectorStatusType,
            child: selector,
          ),
        ),
        SizedBox(width: spacing),
        SizedBox(
          width: height,
          height: height + _statusHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              resetButton,
            ],
          ),
        ),
      ],
    );
  }
}
