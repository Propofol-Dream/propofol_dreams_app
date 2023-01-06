import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings.dart';

class PDTextField extends StatefulWidget {
  PDTextField({
    Key? key,
    this.prefixIcon,
    required this.labelText,
    required this.helperText,
    required this.interval,
    required this.fractionDigits,
    required this.controller,
    required this.onPressed,
    // required this.onChanged,
    required this.range,
    this.timer,
    this.enabled = true,
    this.height = 56,
  }) : super(key: key);

  final String labelText;
  final IconData? prefixIcon;
  final String helperText;
  final double interval;
  final int fractionDigits;
  final TextEditingController controller;
  final range;
  Function onPressed;

  // Function onChanged;
  Function? onLongPressedStart;
  Function? onLongPressedEnd;
  bool enabled;
  Timer? timer;
  final Duration delay = Duration(milliseconds: 50);
  double? height;

  @override
  State<PDTextField> createState() => _PDTextFieldState();
}

class _PDTextFieldState extends State<PDTextField> {
  // final _textEditingController = TextEditingController();

  // dispose it when the widget is unmounted
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    //this controls size of the plus & minus buttons
    double suffixIconConstraintsWidth = 84;
    double suffixIconConstraintsHeight = widget.height ?? 56;

    var val =     widget.fractionDigits > 0
        ? double.tryParse(widget.controller.text)
        : int.tryParse(widget.controller.text);
    // double.tryParse(widget.controller.text);


    bool isWithinRange =
        val != null ? val >= widget.range[0] && val <= widget.range[1] : false;
    bool isNumeric = widget.controller.text.isEmpty ? false : val != null;


    return Stack(alignment: Alignment.topRight, children: [
      TextField(
        enabled: widget.enabled,
        style: TextStyle(
            color: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor),
        scrollPadding: EdgeInsets.all(48.0),
        onSubmitted: (val) {
          widget.onPressed();
        },
        controller: widget.controller,
        keyboardType: TextInputType.numberWithOptions(
            signed: true, decimal: widget.fractionDigits > 0 ? true : false),
        // keyboardType: TextInputType.numberWithOptions(
        //     signed: widget.fractionDigits > 0 ? true : false,
        //     decimal: widget.fractionDigits > 0 ? true : false),
        keyboardAppearance:
            settings.isDarkTheme ? Brightness.dark : Brightness.light,

        decoration: InputDecoration(
          filled: widget.enabled ? true : false,
          fillColor: (isWithinRange && isNumeric)
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onError,
          errorText: widget.enabled
              ? widget.controller.text.isEmpty
                  ? 'Please enter a value'
                  : isNumeric
                      ? isWithinRange
                          ? null
                          : 'min: ${widget.range[0]} and max: ${widget.range[1]}'
                      : 'Please enter a value'
              : '',
          errorStyle: TextStyle(color: Theme.of(context).colorScheme.error),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: widget.enabled
                ? (isWithinRange && isNumeric)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error
                : Theme.of(context).disabledColor,
          ),
          prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
          helperText: widget.helperText,
          labelText: widget.labelText,
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: widget.enabled
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).disabledColor),
          ),
        ),
      ),
      widget.controller.text.isNotEmpty
          ? Container(
              width: suffixIconConstraintsWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      width: suffixIconConstraintsWidth / 2,
                      height: suffixIconConstraintsHeight,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0, style: BorderStyle.none)),
                      child: Icon(
                        Icons.remove,
                        color: widget.enabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    onTap: widget.enabled
                        ? () async {
                            double? prev =
                                double.tryParse(widget.controller.text);
                            if (prev != null && prev >= widget.range[0]) {
                              prev -= widget.interval;
                              if (prev >= widget.range[0]) {
                                widget.controller.text =
                                    prev.toStringAsFixed(widget.fractionDigits);
                                await HapticFeedback.mediumImpact();
                              } else {
                                widget.controller.text = widget.range[0]
                                    .toStringAsFixed(widget.fractionDigits);
                              }
                              widget.onPressed();
                            }
                          }
                        : null,
                    onLongPress: widget.enabled
                        ? () {
                            widget.timer =
                                Timer.periodic(widget.delay, (t) async {
                              double? prev =
                                  double.tryParse(widget.controller.text);
                              if (prev != null && prev >= widget.range[0]) {
                                prev -= widget.interval;
                                if (prev >= widget.range[0]) {
                                  widget.controller.text = prev
                                      .toStringAsFixed(widget.fractionDigits);
                                  await HapticFeedback.mediumImpact();
                                } else {
                                  widget.controller.text = widget.range[0]
                                      .toStringAsFixed(widget.fractionDigits);
                                }
                              }
                            });
                          }
                        : null,
                    onLongPressEnd: (_) {
                      if (widget.timer != null) {
                        widget.timer!.cancel();
                        widget.onPressed();
                      }
                    },
                  ),
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      width: suffixIconConstraintsWidth / 2,
                      height: suffixIconConstraintsHeight,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0, style: BorderStyle.none)),
                      child: Icon(
                        Icons.add,
                        color: widget.enabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    onTap: widget.enabled
                        ? () async {
                            double? prev =
                                double.tryParse(widget.controller.text);
                            if (prev != null && prev <= widget.range[1]) {
                              prev += widget.interval;
                              if (prev <= widget.range[1]) {
                                widget.controller.text =
                                    prev.toStringAsFixed(widget.fractionDigits);
                                await HapticFeedback.mediumImpact();
                              } else {
                                widget.controller.text = widget.range[1]
                                    .toStringAsFixed(widget.fractionDigits);
                              }
                              widget.onPressed();
                            }
                          }
                        : null,
                    onLongPress: widget.enabled
                        ? () {
                            widget.timer =
                                Timer.periodic(widget.delay, (t) async {
                              double? prev =
                                  double.tryParse(widget.controller.text);
                              if (prev != null && prev <= widget.range[1]) {
                                prev += widget.interval;
                                if (prev <= widget.range[1]) {
                                  widget.controller.text = prev
                                      .toStringAsFixed(widget.fractionDigits);
                                  await HapticFeedback.mediumImpact();
                                } else {
                                  widget.controller.text = widget.range[1]
                                      .toStringAsFixed(widget.fractionDigits);
                                }
                              }
                            });
                          }
                        : null,
                    onLongPressEnd: (_) {
                      if (widget.timer != null) {
                        widget.timer!.cancel();
                        widget.onPressed();
                      }
                    },
                  ),
                ],
              ),
            )
          : Container(
              width: 0,
              height: 0,
            )
    ]);
  }
}