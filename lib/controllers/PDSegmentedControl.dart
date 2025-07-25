import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'PDSegmentedController.dart';

class PDSegmentedControl extends StatefulWidget {
  PDSegmentedControl({
    super.key,
    required this.labels,
    required this.segmentedController,
    required this.onPressed,
    this.fontSize,
    this.fitWidth = false,
    this.fitHeight = false,
    required this.defaultColor,
    required this.defaultOnColor,
  });

  final List<String> labels;
  final PDSegmentedController segmentedController;
  final List<VoidCallback?> onPressed;
  final double? fontSize;
  final bool fitWidth; // Property to control width behavior
  final bool fitHeight; // Property to control height behavior
  Color defaultColor;
  Color defaultOnColor;

  @override
  State<PDSegmentedControl> createState() => _PDSegmentedControlState();
}

class _PDSegmentedControlState extends State<PDSegmentedControl> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.labels.length, (buildIndex) {
        Widget button = widget.fitWidth
            ? Expanded(
                child: buildButton(context, buildIndex),
              )
            : buildButton(context, buildIndex);
        return button;
      }),
    );
  }

  Widget buildButton(BuildContext context, int buildIndex) {
    return SizedBox(
      height: widget.fitHeight ? double.infinity : null,
      // Set height based on fitHeight
      child: ElevatedButton(
        onPressed: widget.onPressed[buildIndex] == null
            ? null
            : () async {
                await HapticFeedback.mediumImpact();
                setState(() {
                  widget.segmentedController.val = buildIndex;
                });
                widget.onPressed[buildIndex]!();
              },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: widget.onPressed[buildIndex] == null
              ? Theme.of(context).disabledColor
              : widget.segmentedController.val == buildIndex
                  ? widget.defaultColor
                  : widget.defaultOnColor,
          backgroundColor: widget.onPressed[buildIndex] == null
              ? Theme.of(context).disabledColor
              : widget.segmentedController.val == buildIndex
                  ? widget.defaultColor
                  : widget.defaultOnColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              strokeAlign: BorderSide.strokeAlignInside,
              color: widget.onPressed[buildIndex] == null
                  ? Theme.of(context).disabledColor
                  : widget.defaultColor,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(buildIndex == 0 ? 5 : 0),
              bottomLeft: Radius.circular(buildIndex == 0 ? 5 : 0),
              topRight: Radius.circular(
                  buildIndex == widget.labels.length - 1 ? 5 : 0),
              bottomRight: Radius.circular(
                  buildIndex == widget.labels.length - 1 ? 5 : 0),
            ),
          ),
        ),
        child: Text(
          widget.labels[buildIndex],
          style: TextStyle(
            color: widget.onPressed[buildIndex] == null
                ? Theme.of(context).disabledColor
                : widget.segmentedController.val == buildIndex
                    ? widget.defaultOnColor
                    : widget.defaultColor,
            fontSize: widget.fontSize ?? 14,
          ),
        ),
      ),
    );
  }
}
