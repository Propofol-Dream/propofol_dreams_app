import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';

import 'package:propofol_dreams_app/controllers/PDSwitchController.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchField.dart';
import 'package:propofol_dreams_app/controllers/PDTextField.dart';

import 'package:propofol_dreams_app/controllers/PDSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDSegmentedControl.dart';

import 'package:propofol_dreams_app/widgets/PDLabel.dart';
import 'package:propofol_dreams_app/widgets/PDStyledLabel.dart';

import '../constants.dart';

class EleMarshScreen extends StatefulWidget {
  EleMarshScreen({Key? key}) : super(key: key);

  @override
  State<EleMarshScreen> createState() => _EleMarshScreenState();
}

class _EleMarshScreenState extends State<EleMarshScreen> {
  PDSwitchController genderController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  TextEditingController wakeUpController = TextEditingController();

  final PDSegmentedController flowController = PDSegmentedController();

  String weightBestGuess = "--";
  String adjustmentBolus = "--";
  String inductionCPTarget = "--";

  String BMI = "--";

  String predictedBIS = "--";

  @override
  void initState() {
    final settings = context.read<Settings>();

    genderController.val = settings.EMGender == Gender.Female ? true : false;
    ageController.text = settings.EMAge.toString();
    heightController.text = settings.EMHeight.toString();
    weightController.text = settings.EMWeight.toString();
    targetController.text = settings.EMTarget.toString();
    // durationController.text = settings.EMDuration.toString();
    flowController.val = settings.EMFlow == 'wakeUp' ? 1 : 0;

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

    if (pref.containsKey('density')) {
      settings.density = pref.getInt('density')!;
    } else {
      settings.density = 10;
    }

    if (pref.containsKey('EMGender')) {
      String gender = pref.getString('EMGender')!;
      settings.EMGender = gender == 'Female' ? Gender.Female : Gender.Male;
    } else {
      settings.EMGender = Gender.Female;
    }

    if (pref.containsKey('EMAge')) {
      settings.EMAge = pref.getInt('EMAge');
    } else {
      settings.EMAge = 40;
    }

    if (pref.containsKey('EMHeight')) {
      settings.EMHeight = pref.getInt('EMHeight');
    } else {
      settings.EMHeight = 170;
    }

    if (pref.containsKey('EMWeight')) {
      settings.EMWeight = pref.getInt('EMWeight');
    } else {
      settings.EMWeight = 70;
    }

    if (pref.containsKey('EMTarget')) {
      settings.EMTarget = pref.getDouble('EMTarget');
    } else {
      settings.EMTarget = 3.0;
    }

    if (pref.containsKey('EMDuration')) {
      settings.EMDuration = pref.getInt('EMDuration');
    } else {
      settings.EMDuration = 60;
    }

    if (pref.containsKey('EMFlow')) {
      settings.EMFlow = pref.getString('EMFlow')!;
    } else {
      settings.EMFlow = 'induction';
    }

    genderController.val = settings.EMGender == Gender.Female ? true : false;
    ageController.text = settings.EMAge.toString();
    heightController.text = settings.EMHeight.toString();
    weightController.text = settings.EMWeight.toString();
    targetController.text = settings.EMTarget.toString();
    // durationController.text = settings.EMDuration.toString();
    flowController.val = settings.EMFlow == 'wakeUp' ? 1 : 0;

    run(initState: true);
  }

  // _launchURL() async {
  //   // const url = 'https://propofoldreams.org/in_app_redirect/';
  //   // final uri = Uri.parse(url);
  //   // if (await canLaunchUrl(uri)) {
  //   //   await launchUrl(uri);
  //   // } else {
  //   //   throw 'Could not launch $url';
  //   // }
  // }

  void updatePDTextEditingController() {
    // final settings = Provider.of<Settings>(context, listen: false);
    run();
  }

  run({initState = false}) async {
    final settings = Provider.of<Settings>(context, listen: false);

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    Gender gender = genderController.val ? Gender.Female : Gender.Male;

    if (initState == false) {
      settings.EMGender = gender;
      settings.EMAge = age;
      settings.EMHeight = height;
      settings.EMWeight = weight;
      settings.EMTarget = target;
    }

    if (age != null && height != null && weight != null && target != null) {
      if (age >= 14 &&
          age <= 105 &&
          height >= 100 &&
          height <= 220 &&
          weight >= 35 &&
          weight <= 350 &&
          target >= 0.5 &&
          target <= 8.0) {
        DateTime start = DateTime.now();

        Model model = Model.Eleveld;
        Patient patient =
            Patient(weight: weight, height: height, age: age, gender: gender);
        Pump pump = Pump(
            timeStep: Duration(seconds: settings.time_step),
            density: settings.density,
            maxPumpRate: settings.max_pump_rate,
            target: target,
            duration: Duration(hours: 3));
        // Operation operation =
        //     Operation(target: target, duration: Duration(hours: 3));
        PDSim.Simulation simulation =
            PDSim.Simulation(model: model, patient: patient, pump: pump);

        EleMarsh elemarsh = EleMarsh(goldSimulation: simulation);

        var result = elemarsh.estimate(weightBound: 0, bolusBound: 0);

        DateTime finish = DateTime.now();

        Duration calculationDuration = finish.difference(start);

        setState(() {
          weightBestGuess = result.weightBestGuess.toString();
          inductionCPTarget = result.inductionCPTarget.toStringAsFixed(1);
          adjustmentBolus = result.adjustmentBolus.round().toString();
          // int guessIndex = result.guessIndex;
          predictedBIS = result.predictedBIS.toStringAsFixed(0);
          // MDAPE = (result.MDAPEs[guessIndex] * 100).toStringAsFixed(1);
          BMI = patient.bmi.toStringAsFixed(1);

          print({
            'weightBestGuess': weightBestGuess,
            'adjustmentBolus': adjustmentBolus,
            'inductionCPTarget': inductionCPTarget,
            'calculation time':
                '${calculationDuration.inMilliseconds.toString()} milliseconds'
          });
        });
      } else {
        setState(() {
          weightBestGuess = "--";
          adjustmentBolus = "--";
          inductionCPTarget = "--";
        });
      }
    } else {
      setState(() {
        weightBestGuess = "--";
        adjustmentBolus = "--";
        inductionCPTarget = "--";
      });
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    genderController.val = toDefault
        ? true
        : settings.EMGender == Gender.Female
            ? true
            : false;
    ageController.text = toDefault
        ? 40.toString()
        : settings.EMAge != null
            ? settings.EMAge.toString()
            : '';
    heightController.text = toDefault
        ? 170.toString()
        : settings.EMHeight != null
            ? settings.EMHeight.toString()
            : '';
    weightController.text = toDefault
        ? 70.toString()
        : settings.EMWeight != null
            ? settings.EMWeight.toString()
            : '';
    targetController.text = toDefault
        ? 3.0.toString()
        : settings.EMTarget != null
            ? settings.EMTarget.toString()
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

    final double rowHeight = 20 + 34 + 2 + 4;

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
              title: Text('Info'),
              content: SingleChildScrollView(
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
                  child: Text('Close'),
                ),
              ],
            );
          });
    }

    ;

    return Container(
      height: screenHeight,
      margin: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(child: Container()),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            // Add your desired radius here
            child: Container(
              height: rowHeight * 3,
              child: Column(
                children: [
                  Container(
                    height: rowHeight,
                    color: Theme.of(context).colorScheme.onPrimary,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Divider(
                          height: 0.0,
                          color: Colors.transparent,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "EleMarsh ABW",
                                style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              Row(
                                children: [
                                  Text("$weightBestGuess",
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  Text(" kg",
                                      style: TextStyle(
                                          fontSize: 24,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 16.0),
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
                        Divider(
                          height: 0.0,
                          color: Colors.transparent,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Induction CpT",
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "$inductionCPTarget",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    " μg/mL",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Divider(
                            height: 1.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      ],
                    ),
                  ),
                  // Container(
                  //   height: rowHeight,
                  //   color: Theme.of(context).colorScheme.onPrimary,
                  //   child: Column(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       Divider(
                  //         height: 0.0,
                  //         color: Colors.transparent,
                  //       ),
                  //       Container(
                  //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                  //         child: Row(
                  //           mainAxisAlignment:
                  //               MainAxisAlignment.spaceBetween,
                  //           children: [
                  //             Text(
                  //               "Adjustment Bolus",
                  //               style: TextStyle(fontSize: 16),
                  //             ),
                  //             Row(
                  //               children: [
                  //                 Text(
                  //                   "$adjustmentBolus",
                  //                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  //                 ),
                  //                 Text(
                  //                   " mg",
                  //                   style: TextStyle(fontSize: 20),
                  //                 ),
                  //               ],
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //       Container(
                  //         padding: EdgeInsets.only(left: 16.0),
                  //         child: Divider(
                  //           height: 1.0,
                  //           color: Theme.of(context).colorScheme.primary,
                  //         ),
                  //       )
                  //     ],
                  //   ),
                  // ),
                  Container(
                    height: rowHeight,
                    color: Theme.of(context).colorScheme.onPrimary,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Divider(
                          height: 0.0,
                          color: Colors.transparent,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: Row(
                                  children: [
                                    Text(
                                      "Predicted BIS",
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      "$predictedBIS",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "BMI",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(
                                    width: 8.0,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "$BMI",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Row(
                              //   children: [
                              //     Text(
                              //       "MaxAPE",
                              //       style: TextStyle(fontSize: 14),
                              //     ),
                              //     SizedBox(
                              //       width: 8.0,
                              //     ),
                              //     Text(
                              //       "$MaxAPE %",
                              //       style: TextStyle(fontSize: 14),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Divider(
                            height: 1.0,
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
          Container(
            width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: UIHeight,
                    child: PDSegmentedControl(
                        fitHeight: true,
                        fontSize: 14,
                        defaultColor: Theme.of(context).colorScheme.primary,
                        defaultOnColor: Theme.of(context).colorScheme.onPrimary,
                        labels: ["Induction", "Wake Up"],
                        segmentedController: flowController,
                        onPressed: [
                          () {
                            settings.EMFlow = 'induction';
                          },
                          null
                        ]),
                  ),
                ),
                Row(
                  children: [
                    Container(
                        height: UIHeight,
                        width: UIHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(0),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () {
                            showAlertDialog(context);
                          },
                          child:
                              Center(child: Icon(Icons.info_outline_rounded)),
                        )),
                    SizedBox(
                      width: 8,
                    ),
                    Container(
                        height: UIHeight,
                        width: UIHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(0),
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () async {
                            await HapticFeedback.mediumImpact();
                            reset(toDefault: true);
                          },
                          child: Icon(Icons.restart_alt_outlined),
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
          Opacity(
            opacity: flowController.val == 0 ? 1 : 0,
            child: Container(
              height: flowController.val == 0 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: UIWidth,
                    child: PDSwitchField(
                      labelText: 'Sex',
                      prefixIcon: Icons.wc,
                      controller: genderController,
                      switchTexts: {
                        true: Gender.Female.toString(),
                        false: Gender.Male.toString()
                      },
                      onChanged: run,
                      height: UIHeight,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                    height: 0,
                  ),
                  Container(
                    width: UIWidth,
                    child: PDTextField(
                      prefixIcon: Icons.calendar_month,
                      labelText: 'Age',
                      // helperText: '',
                      interval: 1.0,
                      fractionDigits: 0,
                      controller: ageController,
                      range: [14, 105],
                      onPressed: updatePDTextEditingController,
                      // onChanged: restart,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: flowController.val == 1 ? 1 : 0,
            child: Container(
              height: flowController.val == 1 ? UIHeight + 24 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width:
                        mediaQuery.size.width - 2 * horizontalSidesPaddingPixel,
                    child: PDTextField(
                      prefixIcon: Icons.psychology_alt_outlined,
                      labelText:
                          '${Model.Eleveld.target.toString()} Wake Up (mcg/mL)',
                      interval: 0.5,
                      fractionDigits: 1,
                      controller: wakeUpController,
                      range: [0.5, 8],
                      onPressed: updatePDTextEditingController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.straighten,
                    labelText: 'Height (cm)',
                    // helperText: '',
                    interval: 1,
                    fractionDigits: 0,
                    controller: heightController,
                    range: [100, 220],
                    onPressed: updatePDTextEditingController,
                  ),
                ),
                SizedBox(
                  width: 8,
                  height: 0,
                ),
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.monitor_weight_outlined,
                    labelText: 'Weight (kg)',
                    // helperText: '',
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: weightController,
                    range: [35, 350],
                    onPressed: updatePDTextEditingController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: UIWidth * 2 + 8,
                  child: PDTextField(
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText:
                        '${Model.Eleveld.target.toString()} Target (mcg/mL)',
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: targetController,
                    range: [0.5, 8],
                    onPressed: updatePDTextEditingController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}
