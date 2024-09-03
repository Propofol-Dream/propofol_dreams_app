import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:propofol_dreams_app/models/calculator.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propofol_dreams_app/providers/settings.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';




import '../constants.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  TextEditingController calculatorWakeUpCEController = TextEditingController();
  TextEditingController calculatorWakeUpSEController = TextEditingController();

  //Displays
  String lower = "--";
  String upper = "--";

  @override
  void initState() {
    final settings = context.read<Settings>();

    calculatorWakeUpCEController.text = settings.calculatorWakeUpCE.toString();
    calculatorWakeUpSEController.text = settings.calculatorWakeUpSE.toString();

    load();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> load() async {
    var pref = await SharedPreferences.getInstance();
    final settings = context.read<Settings>();

    if (pref.containsKey('calculatorWakeUpCE')) {
      settings.calculatorWakeUpCE = pref.getDouble('calculatorWakeUpCE')!;
    } else {
      settings.calculatorWakeUpCE = 3;
    }

    if (pref.containsKey('calculatorWakeUpSE')) {
      settings.calculatorWakeUpSE = pref.getInt('calculatorWakeUpSE')!;
    } else {
      settings.calculatorWakeUpSE = 3;
    }

    calculatorWakeUpCEController.text = settings.calculatorWakeUpCE.toString();
    calculatorWakeUpSEController.text = settings.calculatorWakeUpSE.toString();
    run(initState: true);
  }

  void updatePDTextEditingController() {
    // final settings = Provider.of<Settings>(context, listen: false);
    run();
  }

  run({initState = false}) async {
    final settings = Provider.of<Settings>(context, listen: false);

    double? calculatorWakeUpCE =
        double.tryParse(calculatorWakeUpCEController.text);
    int? calculatorWakeUpSE =
        int.tryParse(calculatorWakeUpSEController.text);

    //Save all the settings
    if (initState == false) {
      settings.calculatorWakeUpCE = calculatorWakeUpCE;
      settings.calculatorWakeUpSE = calculatorWakeUpSE;
    }

    if (calculatorWakeUpCE != null && calculatorWakeUpSE != null) {
      DateTime start = DateTime.now();

      Calculator c = Calculator();

      var result = c.calcWakeUpCE(ce: calculatorWakeUpCE, se: calculatorWakeUpSE, m: Model.Eleveld);
      // print(result);

      DateTime finish = DateTime.now();

      Duration calculationDuration = finish.difference(start);

      setState(() {
        lower = result.lower.toStringAsFixed(6);
        upper = result.upper.toStringAsFixed(6);

        print({
          'lower': lower,
          'upper': upper,
          'calculation time':
              '${calculationDuration.inMilliseconds.toString()} milliseconds'
        });
      });
    } else {
      setState(() {
        lower = "--";
        upper = "--";
      });
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    calculatorWakeUpCEController.text = toDefault
        ? 3.0.toString()
        : settings.calculatorWakeUpCE != null
            ? settings.calculatorWakeUpCE.toString()
            : '';

    calculatorWakeUpSEController.text = toDefault
        ? 25.toString()
        : settings.calculatorWakeUpSE != null
            ? settings.calculatorWakeUpSE.toString()
            : '';
    run();
  }

  @override
  Widget build(BuildContext context) {
    // print(weightBestGuess);

    final mediaQuery = MediaQuery.of(context);

    final double UIHeight = mediaQuery.size.aspectRatio >= 0.455
        ? mediaQuery.size.height >= screenBreakPoint1
            ? 56
            : 48
        : 48;
    final double UIWidth =
        (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;

    const double rowHeight = 20 + 34 + 2 + 4;

    final double screenHeight = mediaQuery.size.height -
        (Platform.isAndroid
            ? 48
            : mediaQuery.size.height >= screenBreakPoint1
                ? 88
                : 56);

    final settings = context.watch<Settings>();
    int density = settings.density;

    void showAlertDialog(BuildContext context) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Info'),
              content: const SingleChildScrollView(
                child: Text.rich(
                  TextSpan(
                      text:
                          """The purpose of EleMarsh Mode is to make the Marsh model mimic the Eleveld model.""",
                      children: [
                        TextSpan(text: "\n\n"),
                        TextSpan(
                            text:
                                "Step by step guide to using the EleMarsh mode:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: """
              
              
(1) Enter patient details and desired Ce target

(2) EleMarsh generates the """),
                        TextSpan(
                          text: """Adjusted Body Weight """,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: """and """),
                        TextSpan(
                          text: """Induction CpT""",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: """


(3) Use the """),
                        TextSpan(
                          text: """Adjusted Body Weight """,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text:
                                """as the Marsh input weight on your TCI pump"""),
                        TextSpan(text: """


(4) Use the """),
                        TextSpan(
                          text: """Induction CpT """,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text:
                                """as your initial CpT setting. As soon as the bolus is given, drop the CpT down to your desired CeT. The Marsh model on your pump will now mimic the behaviour of the Eleveld model."""),
                        TextSpan(
                          text: """
                    
                    
Reference""",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: """


Zhong G., Xu, X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. """),
                        TextSpan(
                          text: """2024""",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: """.""",
                        ),
                      ]),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Close the modal
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          });
    }


    return Container(
      height: screenHeight,
      margin: const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(child: Container()),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            // Add your desired radius here
            child: SizedBox(
              height: rowHeight * 2,
              child: Column(
                children: [
                  Container(
                    height: rowHeight,
                    color: Theme.of(context).colorScheme.onPrimary,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Divider(
                          height: 0.0,
                          color: Colors.transparent,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Wake Up",
                                style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              Row(
                                children: [
                                  Text(lower,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  // Text(" kg",
                                  //     style: TextStyle(
                                  //         fontSize: 24,
                                  //         color: Theme.of(context)
                                  //             .colorScheme
                                  //             .primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Divider(
                            height: 1.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: rowHeight,
                    color: Theme.of(context).colorScheme.onPrimary,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Divider(
                          height: 0.0,
                          color: Colors.transparent,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "EEg Speed Up",
                                style: TextStyle(
                                    fontSize: 18,
                                    color:
                                    Theme.of(context).colorScheme.primary),
                              ),
                              Row(
                                children: [
                                  Text(
                                    upper,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  // Text(
                                  //   " μg/mL",
                                  //   style: TextStyle(fontSize: 20),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: const Divider(
                            height: 0.0,
                            color: Colors.transparent,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          SizedBox(
            width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    SizedBox(
                        height: UIHeight,
                        width: UIHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () {
                            showAlertDialog(context);
                          },
                          child:
                              const Center(child: Icon(Icons.info_outline_rounded)),
                        )),
                    const SizedBox(
                      width: 8,
                    ),
                    SizedBox(
                        height: UIHeight,
                        width: UIHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () async {
                            await HapticFeedback.mediumImpact();
                            reset(toDefault: true);
                          },
                          child: const Icon(Icons.restart_alt_outlined),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height:
                28, //this has been manually adjusted from 24, don't know the root cause yet.
          ),
          SizedBox(
            height:  UIHeight + 24 ,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width:
                      mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                  child: PDTextField(
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText:
                        'Maintenance Ce',
                    interval: 0.1,
                    fractionDigits: 1,
                    controller: calculatorWakeUpCEController,
                    range: const [0.5, 10],
                    onPressed: updatePDTextEditingController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),

          SizedBox(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width:
                      mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                  child: PDTextField(
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText: 'Observed State Entropy',
                    interval: 1,
                    fractionDigits: 1,
                    controller: calculatorWakeUpSEController,
                    range: const [1, 99],
                    onPressed: updatePDTextEditingController,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 8,
          ),
          // Container(
          //   height: UIHeight + 24,
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Container(
          //         width: UIWidth * 2 + 8,
          //         child: PDTextField(
          //           prefixIcon: Icons.psychology_alt_outlined,
          //           labelText:
          //               '${Model.Eleveld.target.toString()} Target (mcg/mL)',
          //           interval: 0.5,
          //           fractionDigits: 1,
          //           controller: targetController,
          //           range: [0.5, 8],
          //           onPressed: updatePDTextEditingController,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}
