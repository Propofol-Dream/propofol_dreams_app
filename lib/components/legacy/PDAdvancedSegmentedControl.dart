import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:propofol_dreams_app/models/sex.dart';

import 'package:propofol_dreams_app/components/legacy/PDAdvancedSegmentedController.dart';

import '../../constants.dart';

class PDAdvancedSegmentedControl extends StatefulWidget {
  const PDAdvancedSegmentedControl({
    super.key,
    required this.options,
    required this.segmentedController,
    required this.onPressed,
    required this.assertValues,
    required this.height,
  });

  final List options;
  final PDAdvancedSegmentedController segmentedController;
  final Function onPressed;
  final Map<String, Object> assertValues;
  final double height;

  @override
  State<PDAdvancedSegmentedControl> createState() =>
      _PDAdvancedSegmentedControlState();
}

class _PDAdvancedSegmentedControlState
    extends State<PDAdvancedSegmentedControl> {
  // @override
  // void dispose() {
  //   widget.segmentedController.dispose();
  //   super.dispose();
  // }


  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var screenRatio = mediaQuery.size.width / mediaQuery.size.height;

    final Sex sex = widget.assertValues['sex'] as bool ? Sex.Female : Sex.Male;
    final int weight = widget.assertValues['weight'] as int;
    final int height = widget.assertValues['height'] as int;
    final int age = widget.assertValues['age'] as int;

    bool isError = widget.segmentedController.hasValidationError(
        sex: sex,
        weight: weight,
        height: height,
        age: age);

    String errorText = widget.segmentedController.getValidationErrorText(
        sex: sex,
        weight: weight,
        height: height,
        age: age);

    return Stack(children: [
      SizedBox(
        width: MediaQuery.of(context).size.width -
            horizontalSidesPaddingPixel * 2 -
            widget.height -
            16,
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            // helperText: '',
            errorText: errorText,
            errorStyle: isError
                ? TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 10)
                : TextStyle(
                color: Theme.of(context).colorScheme.primary, fontSize: 10),
            border: const OutlineInputBorder(
                borderSide: BorderSide(width: 0, style: BorderStyle.none)),
          ),
        ),
      ),
      SizedBox(
        height: widget.height,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: widget.options.length,
          itemBuilder: (buildContext, buildIndex) {
            return SizedBox(
              child: ElevatedButton(
                onPressed: widget.options[buildIndex].isEnable(
                    age: age,
                    height: height,
                    weight: weight)
                    ? () async {
                  await HapticFeedback.mediumImpact();
                  widget.segmentedController.selection =
                  widget.options[buildIndex];
                  widget.onPressed(widget.options[buildIndex]);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  elevation: 0,
                  foregroundColor: widget.segmentedController.selection ==
                      widget.options[buildIndex]
                      ? Theme.of(context).colorScheme.onPrimary
                      : isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  backgroundColor: widget.segmentedController.selection ==
                      widget.options[buildIndex]
                      ? isError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      // strokeAlign: StrokeAlign.outside, // deprecated in flutter 3.7
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: widget.options[buildIndex].isEnable(
                            age: age,
                            height: height,
                            weight: weight)
                            ? isError
                            ? widget.segmentedController.selection ==
                            widget.options[buildIndex]
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary
                            : isError
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).disabledColor),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(buildIndex == 0 ? 5 : 0),
                      bottomLeft: Radius.circular(buildIndex == 0 ? 5 : 0),
                      topRight: Radius.circular(
                          buildIndex == widget.options.length - 1 ? 5 : 0),
                      bottomRight: Radius.circular(
                          buildIndex == widget.options.length - 1 ? 5 : 0),
                    ),
                  ),
                ),
                child: Text(
                  widget.options[buildIndex].toString(),
                  style: TextStyle(
                      fontSize: screenRatio >= 0.455 ? 14 : 12,
                      color: widget.options[buildIndex].isEnable(
                          age: age,
                          height: height,
                          weight: weight)
                          ? isError
                          ? widget.segmentedController.selection ==
                          widget.options[buildIndex]
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.primary
                          : widget.segmentedController.selection ==
                          widget.options[buildIndex]
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary
                          : isError
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).disabledColor),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
