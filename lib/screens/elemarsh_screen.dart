import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:propofol_dreams_app/models/adjustment.dart';
import 'package:propofol_dreams_app/screens/home_screen.dart';
import 'package:propofol_dreams_app/screens/home_screen2.dart';
import 'package:propofol_dreams_app/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

class EleMarshtScreen extends StatefulWidget {
  EleMarshtScreen({Key? key}) : super(key: key);

  @override
  State<EleMarshtScreen> createState() => _EleMarshtScreenState();
}

class _EleMarshtScreenState extends State<EleMarshtScreen> {
  PDSwitchController genderController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();

  // TextEditingController durationController = TextEditingController();

  String weightBestGuess = "--";
  String adjustmentBolus = "--";
  String inductionCPTarget = "--";
  String MDPE = "--";
  String MDAPE = "--";
  String MaxAPE = "--";

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

  _launchURL() async {
    // const url = 'https://propofoldreams.org/in_app_redirect/';
    // final uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri);
    // } else {
    //   throw 'Could not launch $url';
    // }
  }

  void updatePDTextEditingController() {
    final settings = Provider.of<Settings>(context, listen: false);
    // int? age = int.tryParse(ageController.text);
    // if (age != null) {
    //   settings.inAdultView = age >= 17 ? true : false;
    // }
    // updateModelOptions(settings.inAdultView);
    run();
  }

  run({initState = false}) async {
    final settings = Provider.of<Settings>(context, listen: false);

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    // int? duration = int.tryParse(durationController.text);
    Gender gender = genderController.val ? Gender.Female : Gender.Male;

    if (initState == false) {
      settings.EMGender = gender;
      settings.EMAge = age;
      settings.EMHeight = height;
      settings.EMWeight = weight;
      settings.EMTarget = target;
      // settings.EMDuration = duration;
    }

    if (age != null && height != null && weight != null && target != null) {
      if (age >= 14 &&
          age <= 105 &&
          height >= 100 &&
          height <= 220 &&
          weight >= 40 &&
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
            maxPumpRate: settings.max_pump_rate);
        Operation operation =
            Operation(target: target, duration: Duration(hours: 3));
        PDSim.Simulation simulation = PDSim.Simulation(
            model: model, patient: patient, pump: pump, operation: operation);

        Adjustment adjustment = Adjustment(
            baselineSimulation: simulation, weightBound: 0, bolusBound: 0.0);

        var result = adjustment.calculate();

        DateTime finish = DateTime.now();

        Duration calculationDuration = finish.difference(start);

        setState(() {
          weightBestGuess = result.weightBestGuess.toString();
          inductionCPTarget = result.inductionCPTarget.toStringAsFixed(1);
          // inductionCPTarget = result.inductionCPTarget.toStringAsFixed(2);
          adjustmentBolus = result.adjustmentBolus.round().toString();
          // ((result.adjustmentBolus / 10).round() * 10).toString();
          int guesIndex = result.guessIndex;

          MDPE = (result.MDPEs[guesIndex] * 100).toStringAsFixed(1);
          MDAPE = (result.MDAPEs[guesIndex] * 100).toStringAsFixed(1);
          MaxAPE = (result.MaxAPEs[guesIndex] * 100).toStringAsFixed(1);

          print({
            'weightBestGuess': weightBestGuess,
            'adjustmentBolus': adjustmentBolus,
            'inductionCPTarget': inductionCPTarget,
            'calcuation time':
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
            TextSpan(text: """
The purpose of EleMarsh Mode is to make the Marsh model mimic the Eleveld model.

It achieves this via:
  (1) adjusting the Marsh input weight
  (2) supplemental bolus so that Cp targeting mimics Ce targeting.
              """, children: [
              TextSpan(text: "\n\n"),
              TextSpan(
                  text: "How to use this EleMarsh:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: """


  1. Enter patient details and your desired Ce target.

  2. EleMarsh will generate 3 values - Adjusted Body Weight, Induction CpT, and Adjustment Bolus.

  3. Use the Adjusted Body Weight as the Marsh input weight on your TCI pump.

  4. Use the Induction CpT as the initial CpT setting. As soon as the pump gives the bolus, drop the CpT down to your desired CeT. Your Marsh model will now closely mimic the behaviour of the Eleveld Model.

  5. If you need to increase Ce target, simply increase the Cp target on your TCI pump to give the calculated Adjustment Bolus then drop Cp back to your new desired Ce.
\n\n
"""),
              TextSpan(
                text: """
Additional info for each of the calculated values:
                """,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: """

  Adjusted Body Weight - input this weight into the Marsh Model to convert its behaviour to the Eleveld Model.

  Induction CpT - the starting CpT to set on your TCI pump to quickly get to the desired CeT. Once the bolus has been given, drop CpT back down to CeT. The purpose of this value is to convert plasma targeting (Marsh) to effect site targeting (Eleveld).

  Adjustment Bolus - for every 1 mcg/mL increase in CeT you want to achieve, increase the CpT on the TCI pump such that it delivers this bolus before dropping CpT down to your new desired CeT. The purpose of this value is to convert plasma targeting (Marsh) to effect site targeting (Eleveld).
                """),
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
                      height: 24 + (settings.showMaxPumpRate?24:0) + 12, //fontSize + 12 padding
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
                    height: rowHeight * 4,
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "$weightBestGuess kg",
                                      style: TextStyle(fontSize: 24),
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
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "$inductionCPTarget mcg/mL",
                                      style: TextStyle(fontSize: 20),
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
                                      "Adjustment Bolus",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      "$adjustmentBolus mg",
                                      style: TextStyle(fontSize: 20),
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
                                    Row(
                                      children: [
                                        Text(
                                          "MDPE",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          width: 8.0,
                                        ),
                                        Text(
                                          "$MDPE %",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "MDAPE",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          width: 8.0,
                                        ),
                                        Text(
                                          "$MDAPE %",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "MaxAPE",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          width: 8.0,
                                        ),
                                        Text(
                                          "$MaxAPE %",
                                          style: TextStyle(fontSize: 14),
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
            height: UIHeight + 24,
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
                    helperText: '',
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
                    helperText: '',
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
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    height: UIHeight + 2,
                    prefixIcon: Icons.straighten,
                    labelText: 'Height (cm)',
                    helperText: '',
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
                    helperText: '',
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: weightController,
                    range: [40, 350],
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
                  width: UIWidth,
                  child: PDTextField(
                    height: UIHeight + 2,
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText: '${Model.Eleveld.target.toString()}',
                    helperText: '',
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
                    height: UIHeight,
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
