import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'PDSegmentedController.dart';
import 'package:propofol_dreams_app/constants.dart';

class PDSegmentedControl extends StatefulWidget {
  const PDSegmentedControl({
    Key? key,
    required this.labels,
    required this.segmentedController,
    required this.onPressed,
    this.height,
    this.fontSize,
  }) : super(key: key);

  final List<String> labels;
  final PDSegmentedController segmentedController;
  final List<Function> onPressed;
  final double? height;
  final double? fontSize;

  @override
  State<PDSegmentedControl> createState() => _PDSegmentedControlState();
}

class _PDSegmentedControlState extends State<PDSegmentedControl> {
  @override
  // void dispose() {
  //   widget.segmentedController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var screenRatio = mediaQuery.size.width / mediaQuery.size.height;

    return Container(
      height: widget.height ?? 36,
      width: mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: widget.labels.length,
        itemBuilder: (buildContext, buildIndex) {
          return SizedBox(
            width: (mediaQuery.size.width - 2 * horizontalSidesPaddingPixel) /
                widget.labels.length,
            child: ElevatedButton(
              onPressed: () async{
                await HapticFeedback.mediumImpact();
                setState(() {
                  widget.segmentedController.val = buildIndex;
                });
                widget.onPressed[buildIndex]();
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: widget.segmentedController.val == buildIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                backgroundColor: widget.segmentedController.val == buildIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      strokeAlign: StrokeAlign.outside,
                      color: Theme.of(context).colorScheme.primary),
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
                    color: widget.segmentedController.val == buildIndex
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                    fontSize: widget.fontSize ?? 14),
              ),
            ),
          );
        },
      ),
    );
  }
}
