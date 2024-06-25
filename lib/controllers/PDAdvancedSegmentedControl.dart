import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:propofol_dreams_app/models/gender.dart';
import 'package:propofol_dreams_app/models/model.dart';

import 'package:propofol_dreams_app/controllers/PDAdvancedSegmentedController.dart';

import '../constants.dart';

class PDAdvancedSegmentedControl extends StatefulWidget {
  const PDAdvancedSegmentedControl({
    Key? key,
    required this.options,
    required this.segmentedController,
    required this.onPressed,
    required this.assertValues,
    required this.height,
  }) : super(key: key);

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
  @override
  // void dispose() {
  //   widget.segmentedController.dispose();
  //   super.dispose();
  // }

  bool checkError(
      {required Gender gender,
        required int weight,
        required int height,
        required int age}) {
    Model selectedModel = widget.segmentedController.selection as Model;
    return !(selectedModel.checkConstraints(
        gender: gender,
        weight: weight,
        height: height,
        age: age)['assertion'] as bool);
  }

  String showErrorText(
      {required Gender gender,
        required int weight,
        required int height,
        required int age}) {
    Model selectedModel = widget.segmentedController.selection as Model;
    return (selectedModel.checkConstraints(
        gender: gender,
        weight: weight,
        height: height,
        age: age)['text'] as String);
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var screenRatio = mediaQuery.size.width / mediaQuery.size.height;

    bool isError = checkError(
        gender:
        widget.assertValues['gender'] as bool ? Gender.Female : Gender.Male,
        weight: widget.assertValues['weight'] as int,
        height: widget.assertValues['height'] as int,
        age: widget.assertValues['age'] as int);

    String errorText = showErrorText(
        gender:
        widget.assertValues['gender'] as bool ? Gender.Female : Gender.Male,
        weight: widget.assertValues['weight'] as int,
        height: widget.assertValues['height'] as int,
        age: widget.assertValues['age'] as int);

    return Stack(children: [
      Container(
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
      Container(
        height: widget.height,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: widget.options.length,
          itemBuilder: (buildContext, buildIndex) {
            return SizedBox(
              child: ElevatedButton(
                onPressed: widget.options[buildIndex].isEnable(
                    age: widget.assertValues['age'],
                    height: widget.assertValues['height'],
                    weight: widget.assertValues['weight'])
                    ? () async {
                  await HapticFeedback.mediumImpact();
                  widget.segmentedController.selection =
                  widget.options[buildIndex];
                  widget.onPressed(widget.options[buildIndex]);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                            age: widget.assertValues['age'],
                            height: widget.assertValues['height'],
                            weight: widget.assertValues['weight'])
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
                          age: widget.assertValues['age'],
                          height: widget.assertValues['height'],
                          weight: widget.assertValues['weight'])
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
