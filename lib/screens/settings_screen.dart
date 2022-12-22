import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/providers/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PDSegmentedController formulationController = PDSegmentedController();
  final PDSegmentedController themeController = PDSegmentedController();


  @override
  void initState() {
    themeController.val = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    // var mediaQuery = MediaQuery.of(context);
    // var screenWidth = mediaQuery.size.width;

    final settings = context.watch<Settings>();
    formulationController.val = settings.propofolFormulation == 10?0:1;
    // print(settings.propofolFormulation);

    return Column(children: [
      Container(
        height: 96,
        padding: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
        alignment: Alignment.bottomLeft,
        child: Text(
          'Settings',
          style: TextStyle(
              fontSize: 24, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      Divider(
        color: Theme.of(context).colorScheme.primary,
      ),
      Container(
        height: MediaQuery.of(context).size.height - 90 - 96 - 16,
        padding: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
        // decoration: BoxDecoration(
        //   border: Border.all(color: Theme.of(context).colorScheme.primary),
        // ),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Propofol Formulation',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 8,
                ),
                PDSegmentedControl(
                  height: 40,
                  fontSize: 16,
                  labels: ['1%', '2%'],
                  segmentedController: formulationController,
                  onPressed: [
                    () {
                      settings.propofolFormulation = 10;
                    },
                    () {
                      settings.propofolFormulation = 20;
                    }
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(
              height: 8,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: 8,
                ),
                PDSegmentedControl(
                  height: 40,
                  fontSize: 16,
                  labels: ['Light', 'Dark', 'Auto'],
                  segmentedController: themeController,
                  onPressed: [
                    () {
                      print('1');
                    },
                    () {
                      print('2');
                    },
                    () {
                      print('3');
                    }
                  ],
                ),
              ],
            ),
          ],
        ),
      )
    ]);
  }
}

class PDSegmentedController extends ChangeNotifier {
  PDSegmentedController();

  int _val = 0;

  int get val {
    return _val;
  }

  void set val(int v) {
    _val = v;
    notifyListeners();
  }
}

class PDSegmentedControl extends StatefulWidget {
  PDSegmentedControl({
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
  double? height;
  double? fontSize;

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
        // shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: widget.labels.length,
        itemBuilder: (buildContext, buildIndex) {
          return SizedBox(
            width: (mediaQuery.size.width - 2 * horizontalSidesPaddingPixel) /
                widget.labels.length,
            child: ElevatedButton(
              onPressed: () {
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
