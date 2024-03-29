import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

// import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';

import 'package:propofol_dreams_app/controllers/PDSwitchController.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchField.dart';
import 'package:propofol_dreams_app/controllers/PDTextField.dart';

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

  // TextEditingController durationController = TextEditingController();

  String weightBestGuess = "--";
  String adjustmentBolus = "--";
  String inductionCPTarget = "--";

  String BMI = "--";

  // String MaxAPE = "--";
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

    genderController.val = settings.EMGender == Gender.Female ? true : false;
    ageController.text = settings.EMAge.toString();
    heightController.text = settings.EMHeight.toString();
    weightController.text = settings.EMWeight.toString();
    targetController.text = settings.EMTarget.toString();
    // durationController.text = settings.EMDuration.toString();

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

        EleMarsh elemarsh =
            EleMarsh(goldSimulation: simulation, weightBound: 0, bolusBound: 0);

        var result = elemarsh.calculate();

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

    AlertDialog displayInfoDialog() {
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
                      text: "Step by step guide to using the EleMarsh mode:",
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
                      text: """as the Marsh input weight on your TCI pump"""),
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
    }

    return Container(
      height: screenHeight,
      margin: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 24 + (settings.showMaxPumpRate ? 32 : 0) + 12,
                      //fontSize + 12 padding
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          settings.showMaxPumpRate
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "EleMarsh",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    Text(
                                      "Mode",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ],
                                )
                              : Text(
                                  "EleMarsh Mode",
                                  style: TextStyle(fontSize: 24),
                                ),
                          const SizedBox(
                            width: 8,
                          ),
                          GestureDetector(
                            onTap: () async {
                              await HapticFeedback.mediumImpact();
                              // Show the modal
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return displayInfoDialog();
                                },
                              );
                            },
                            child: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        settings.showMaxPumpRate
                            ? GestureDetector(
                                onTap: () async {
                                  await HapticFeedback.mediumImpact();
                                  settings.showMaxPumpRate =
                                      !settings.showMaxPumpRate;
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (BuildContext context) => HomeScreen(),
                                  //   ),
                                  // );
                                },
                                child: Chip(
                                  avatar: Icon(
                                    Icons.speed_outlined,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  label: Text(
                                    '${settings.max_pump_rate.toString()}',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : Container(),
                        SizedBox(
                          width: 8,
                        ),
                        GestureDetector(
                          onTap: () async {
                            await HapticFeedback.mediumImpact();
                            settings.density == 10
                                ? settings.density = 20
                                : settings.density = 10;
                            run();
                          },
                          onLongPress: () async {
                            await HapticFeedback.mediumImpact();
                            settings.showMaxPumpRate =
                                !settings.showMaxPumpRate;
                          },
                          child: Chip(
                            avatar: settings.density == 10
                                ? Icon(
                                    Icons.water_drop_outlined,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                : Icon(
                                    Icons.water_drop,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                            label: Text(
                              '${(density / 10).toInt()} %',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Adjusted Body Weight",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
              ],
            ),
          ),
          const SizedBox(
            height: 32,
          ),
          Container(
            width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            height: UIHeight + 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: UIWidth,
                  child: PDSwitchField(
                    prefixIcon: Icons.wc,
                    controller: genderController,
                    labelTexts: {
                      true: Gender.Female.toString(),
                      false: Gender.Male.toString()
                    },
                    // helperText: '',
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
                    height: UIHeight + 2,
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
          const SizedBox(
            height: 8,
          ),
          Container(
            height: UIHeight + 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    height: UIHeight + 2,
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
                    height: UIHeight + 2,
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
            height: UIHeight + 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    height: UIHeight + 2,
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText: '${Model.Eleveld.target.toString()}',
                    // helperText: '',
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: targetController,
                    range: [0.5, 8],
                    onPressed: updatePDTextEditingController,
                    // onChanged: restart,
                  ),
                ),
                SizedBox(
                  width: 8,
                  height: 0,
                ),
                Container(
                    height: UIHeight + 4,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              // strokeAlign: StrokeAlign.outside, //depreicated in flutter 3.7
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      ),
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        reset(toDefault: true);
                      },
                      child: Icon(Icons.restart_alt_outlined),
                    )),
                // Container(
                //   width: UIWidth,
                //   child: PDTextField(
                //     height: UIHeight + 2,
                //     prefixIcon: Icons.schedule,
                //     labelText: 'Duration (mins)',
                //     helperText: '',
                //     interval: double.tryParse(durationController.text) != null
                //         ? double.parse(durationController.text) >= 60
                //             ? 10
                //             : 5
                //         : 1,
                //     fractionDigits: 0,
                //     controller: durationController,
                //     range: [kMinDuration, kMaxDuration],
                //     onPressed: updatePDTextEditingController,
                //   ),
                // ),
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
