import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'PDSwitchController.dart';

class PDSwitchField extends StatefulWidget {
  PDSwitchField({
    super.key,
    required this.prefixIcon,
    required this.labelText,
    required this.switchTexts,
    // required this.helperText,
    required this.controller,
    required this.onChanged,
    required this.height,
    this.enabled = true,
  });

  final String labelText;
  final Map<bool, String> switchTexts;
  final IconData prefixIcon;

  // final String helperText;
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
        TextEditingController(text: widget.switchTexts[widget.controller.val]!);

    return Stack(
      alignment: Alignment.centerRight,
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
            errorStyle: TextStyle(color: Theme.of(context).colorScheme.error),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(
                widget.prefixIcon,
                color: widget.enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
            // prefixIconConstraints: BoxConstraints.tight(const Size(40, 18)),
            helperText: '',
            helperStyle: const TextStyle(fontSize: 10),
            labelText: widget.labelText,
            labelStyle: TextStyle(
              color: widget.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
            border: const OutlineInputBorder(),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).disabledColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(right: 4, bottom: 16),
          height: widget.height,
          child: SizedBox(
            height: 24,
            width: 48,
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
          ),
        ),
      ],
    );
  }
}
