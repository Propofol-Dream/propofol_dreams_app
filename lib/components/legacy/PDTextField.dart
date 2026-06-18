import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/design_tokens.dart';
import '../../config/ui_config.dart';
import '../../providers/settings.dart';
import '../PDInputControlFrame.dart';

class PDTextField extends StatefulWidget {
  PDTextField({
    super.key,
    this.prefixIcon,
    required this.labelText,
    this.helperText,
    required this.interval,
    required this.fractionDigits,
    required this.controller,
    required this.onPressed,
    // required this.onChanged,
    required this.range,
    this.timer,
    this.enabled = true,
    this.height, // Now nullable for responsive calculation
    this.m3Style = false,
    this.useInputControlFrame = false,
  });

  final String labelText;
  final String? helperText;
  final IconData? prefixIcon;

  final double interval;
  final int fractionDigits;
  final TextEditingController controller;
  final List<num> range;
  Function onPressed;

  // Function onChanged;
  Function? onLongPressedStart;
  Function? onLongPressedEnd;
  bool enabled;
  Timer? timer;
  final Duration delay = const Duration(milliseconds: 50);
  double? height;
  final bool m3Style;
  final bool useInputControlFrame;

  @override
  State<PDTextField> createState() => _PDTextFieldState();
}

class _PDTextFieldState extends State<PDTextField> {
  // final _textEditingController = TextEditingController();
  Timer? _localTimer; // Local timer for long press when widget.timer is null

  // dispose it when the widget is unmounted
  @override
  void dispose() {
    _localTimer?.cancel(); // Cancel local timer to prevent memory leaks
    // DO NOT dispose the controller - it's shared with other components
    // widget.controller.dispose();
    super.dispose();
  }

  double _getResponsiveHeight() {
    if (widget.height != null) return widget.height!;

    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);

    // Base height calculation with responsive scaling
    double baseHeight = 56.0;

    // Adjust for screen width (mobile vs tablet vs desktop)
    if (screenWidth > 1200) {
      // Desktop: Larger touch targets
      baseHeight = 64.0;
    } else if (screenWidth > 600) {
      // Tablet: Medium touch targets
      baseHeight = 60.0;
    } else {
      // Mobile: Standard size but scale with text
      baseHeight = 56.0;
    }

    // Scale with accessibility text size
    baseHeight = baseHeight * textScale.clamp(1.0, 1.5);

    // Ensure minimum usable height for accessibility
    return baseHeight.clamp(56.0, 88.0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();

    final responsiveHeight = _getResponsiveHeight();

    //this controls size of the plus & minus buttons
    double suffixIconConstraintsWidth = 84;
    double suffixIconConstraintsHeight = responsiveHeight;

    var val = widget.fractionDigits > 0
        ? double.tryParse(widget.controller.text)
        : int.tryParse(widget.controller.text);
    // double.tryParse(widget.controller.text);

    bool isWithinRange =
        val != null ? val >= widget.range[0] && val <= widget.range[1] : false;

    bool isNumeric = widget.controller.text.isEmpty ? false : val != null;

    bool isError = !(isNumeric && isWithinRange);

    bool isWarning = widget.helperText != null && widget.helperText!.isNotEmpty;

    bool canBeDecreased =
        val != null ? val - widget.interval >= widget.range[0] : false;

    bool canBeIncreased =
        val != null ? val + widget.interval <= widget.range[1] : false;

    final validationErrorText = widget.enabled
        ? widget.controller.text.isEmpty
            ? 'Please enter a value'
            : isNumeric
                ? isWithinRange
                    ? null
                    : 'min: ${widget.range[0]} and max: ${widget.range[1]}'
                : 'Please enter a value'
        : null;

    final useFrame = UIConfig.shouldUseInputControlFrame(
      optIn: widget.useInputControlFrame,
    );

    final field = _buildTextFieldStack(
      context: context,
      settings: settings,
      responsiveHeight: responsiveHeight,
      suffixIconConstraintsWidth: suffixIconConstraintsWidth,
      suffixIconConstraintsHeight: suffixIconConstraintsHeight,
      isError: isError,
      isWarning: isWarning,
      isNumeric: isNumeric,
      isWithinRange: isWithinRange,
      canBeDecreased: canBeDecreased,
      canBeIncreased: canBeIncreased,
      usesExternalStatusLane: useFrame,
      errorText: useFrame
          ? null
          : widget.enabled
              ? validationErrorText
              : '',
      helperText: useFrame ? null : widget.helperText,
    );

    if (!useFrame) return field;

    final helperText =
        widget.helperText?.trim().isNotEmpty == true ? widget.helperText : null;

    return PDInputControlFrame(
      controlHeight: responsiveHeight,
      statusText: validationErrorText ?? helperText,
      statusType: validationErrorText != null
          ? PDInputStatusType.error
          : helperText != null
              ? PDInputStatusType.warning
              : PDInputStatusType.none,
      child: field,
    );
  }

  Widget _buildTextFieldStack({
    required BuildContext context,
    required Settings settings,
    required double responsiveHeight,
    required double suffixIconConstraintsWidth,
    required double suffixIconConstraintsHeight,
    required bool isError,
    required bool isWarning,
    required bool isNumeric,
    required bool isWithinRange,
    required bool canBeDecreased,
    required bool canBeIncreased,
    required bool usesExternalStatusLane,
    required String? errorText,
    required String? helperText,
  }) {
    return Stack(alignment: Alignment.centerRight, children: [
      TextField(
        enabled: widget.enabled,
        style: TextStyle(
          color: widget.enabled
              ? isError
                  ? Theme.of(context).colorScheme.error
                  : isWarning
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
          // fontSize: 18
        ),
        scrollPadding: const EdgeInsets.all(48.0),
        onSubmitted: (val) {
          widget.onPressed();
        },
        controller: widget.controller,
        keyboardType: TextInputType.numberWithOptions(
            signed: true, decimal: widget.fractionDigits > 0 ? true : false),
        keyboardAppearance:
            settings.isDarkTheme == true ? Brightness.dark : Brightness.light,
        decoration: InputDecoration(
          // contentPadding: EdgeInsets.only(bottom: 0),
          filled: widget.enabled ? true : false,
          fillColor: widget.m3Style
              ? null
              : isError
                  ? Theme.of(context).colorScheme.onError
                  : isWarning
                      ? Theme.of(context).colorScheme.onTertiary
                      : Theme.of(context).colorScheme.onPrimary,
          helperText: helperText,
          helperStyle: TextStyle(
              color: Theme.of(context).colorScheme.tertiary, fontSize: 10),
          errorText: errorText,
          errorStyle: TextStyle(
              color: Theme.of(context).colorScheme.error, fontSize: 10),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: widget.enabled
                ? isError
                    ? Theme.of(context).colorScheme.error
                    : isWarning
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
          // prefixIconConstraints: BoxConstraints.tight(const Size(44, 20)),
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: widget.enabled
                ? isError
                    ? Theme.of(context).colorScheme.error
                    : isWarning
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
          // Full bordered style with rounded corners — added in L8
          // (LAYOUT_MIGRATION_SPEC.md follow-up). Provides a more Material
          // 3-like outlined appearance with consistent border radius.
          // The previous version relied on a theme wrapper which broke
          // when the field was nested in a constrained card layout.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: widget.enabled
                  ? isError
                      ? Theme.of(context).colorScheme.error
                      : isWarning
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2.0,
            ),
          ),
        ),
      ),
      widget.controller.text.isNotEmpty
          ? Container(
              padding: EdgeInsets.only(bottom: usesExternalStatusLane ? 0 : 20),
              width: suffixIconConstraintsWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
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
                            final timer =
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

                            // Store timer reference
                            if (widget.timer != null) {
                              widget.timer = timer;
                            } else {
                              _localTimer = timer;
                            }
                          }
                        : null,
                    onLongPressEnd: (_) {
                      // Cancel the appropriate timer
                      if (widget.timer != null) {
                        widget.timer!.cancel();
                      } else if (_localTimer != null) {
                        _localTimer!.cancel();
                        _localTimer = null;
                      }
                      widget.onPressed();
                    },
                    child: Container(
                      padding: const EdgeInsets.only(top: 2),
                      alignment: Alignment.center,
                      width: suffixIconConstraintsWidth / 2,
                      height: suffixIconConstraintsHeight,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0, style: BorderStyle.none)),
                      child: Icon(
                        Icons.remove,
                        color: widget.enabled && canBeDecreased
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                  GestureDetector(
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
                            // Use provided timer or create local timer
                            final timer =
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

                            // Store timer reference
                            if (widget.timer != null) {
                              widget.timer = timer;
                            } else {
                              _localTimer = timer;
                            }
                          }
                        : null,
                    onLongPressEnd: (_) {
                      // Cancel the appropriate timer
                      if (widget.timer != null) {
                        widget.timer!.cancel();
                      } else if (_localTimer != null) {
                        _localTimer!.cancel();
                        _localTimer = null;
                      }
                      widget.onPressed();
                    },
                    child: Container(
                      padding: const EdgeInsets.only(top: 2),
                      alignment: Alignment.center,
                      width: suffixIconConstraintsWidth / 2,
                      height: suffixIconConstraintsHeight,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0, style: BorderStyle.none)),
                      child: Icon(
                        Icons.add,
                        color: widget.enabled && canBeIncreased
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(
              width: 0,
              height: 0,
            ),
    ]);
  }
}
