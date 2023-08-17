import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'PDSwitchController.dart';

class PDSwitchField extends StatefulWidget {
  PDSwitchField({
    Key? key,
    required this.prefixIcon,
    required this.labelTexts,
    required this.helperText,
    required this.controller,
    required this.onChanged,
    required this.height,
    this.enabled = true,
  }) : super(key: key);

  final Map<bool, String> labelTexts;
  final IconData prefixIcon;
  final String helperText;
  final PDSwitchController controller;
  final Function onChanged;
  bool enabled;
  double height;

  @override
  State<PDSwitchField> createState() => _PDSwitchFieldState();
}

class _PDSwitchFieldState extends State<PDSwitchField> {
  // dispose it when the widget is unmounted
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController textEditingController =
    TextEditingController(text: widget.labelTexts[widget.controller.val]!);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          controller: textEditingController,
          style: TextStyle(
              color: widget.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor),
          decoration: InputDecoration(
            filled: widget.enabled ? true : false,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            prefixIcon: Icon(
              widget.prefixIcon,
              color: widget.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
            prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        Container(
          height: widget.height,
          child: Switch(
            activeColor: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
            activeTrackColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            inactiveThumbColor: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
            inactiveTrackColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            value: widget.controller.val,
            onChanged: widget.enabled
                ? (val) async {
              await HapticFeedback.mediumImpact();
              setState(() {
                widget.controller.val = val;
              });
              widget.onChanged();
            }
                : null,
          ),
        ),
      ],
    );
  }
}
