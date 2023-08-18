import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:propofol_dreams_app/models/adjustement.dart';
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

class PumpScreen extends StatefulWidget {
  PumpScreen({Key? key}) : super(key: key);

  @override
  State<PumpScreen> createState() => _PumpScreenState();
}

class _PumpScreenState extends State<PumpScreen> {
  PDSwitchController genderController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  TextEditingController durationController = TextEditingController();

  String weightBestGuess = "--";
  String bolusBestGuess = "--";
  String initialCPTarget = "--";

  @override
  void initState() {
    final settings = context.read<Settings>();

    genderController.val = settings.AMWCGender == Gender.Female ? true : false;
    ageController.text = settings.AMWCAge.toString();
    heightController.text = settings.AMWCHeight.toString();
    weightController.text = settings.AMWCWeight.toString();
    targetController.text = settings.AMWCTarget.toString();
    durationController.text = settings.AMWCDuration.toString();

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

    if (pref.containsKey('AMWCGender')) {
      String gender = pref.getString('AMWCGender')!;
      settings.AMWCGender = gender == 'Female' ? Gender.Female : Gender.Male;
    } else {
      settings.AMWCGender = Gender.Female;
    }

    if (pref.containsKey('AMWCAge')) {
      settings.AMWCAge = pref.getInt('AMWCAge');
    } else {
      settings.AMWCAge = 40;
    }

    if (pref.containsKey('AMWCHeight')) {
      settings.AMWCHeight = pref.getInt('AMWCHeight');
    } else {
      settings.AMWCHeight = 170;
    }

    if (pref.containsKey('AMWCWeight')) {
      settings.AMWCWeight = pref.getInt('AMWCWeight');
    } else {
      settings.AMWCWeight = 70;
    }

    if (pref.containsKey('AMWCTarget')) {
      settings.AMWCTarget = pref.getDouble('AMWCTarget');
    } else {
      settings.AMWCTarget = 3.0;
    }

    if (pref.containsKey('AMWCDuration')) {
      settings.AMWCDuration = pref.getInt('AMWCDuration');
    } else {
      settings.AMWCDuration = 60;
    }

    genderController.val = settings.AMWCGender == Gender.Female ? true : false;
    ageController.text = settings.AMWCAge.toString();
    heightController.text = settings.AMWCHeight.toString();
    weightController.text = settings.AMWCWeight.toString();
    targetController.text = settings.AMWCTarget.toString();
    durationController.text = settings.AMWCDuration.toString();

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
      settings.AMWCGender = gender;
      settings.AMWCAge = age;
      settings.AMWCHeight = height;
      settings.AMWCWeight = weight;
      settings.AMWCTarget = target;
      // settings.AMWCDuration = duration;
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
          bolusBestGuess = (result.bolusBestGuess/10.round() *10).toString();
          initialCPTarget = result.initialCPTarget.round().toString();

          print({
            'weightBestGuess': weightBestGuess,
            'bolusBestGuess': bolusBestGuess,
            'initialCPTarget': initialCPTarget,
            'calcuation time':
            '${calculationDuration.inMilliseconds.toString()} milliseconds'
          });


        });
      } else {
        setState(() {
          weightBestGuess = "--";
          bolusBestGuess = "--";
          initialCPTarget = "--";
        });
      }
    } else {
      setState(() {
        weightBestGuess = "--";
        bolusBestGuess = "--";
        initialCPTarget = "--";
      });
    }

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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await HapticFeedback.mediumImpact();
                        settings.density == 10
                            ? settings.density = 20
                            : settings.density = 10;
                        run();
                      },
                      child: Chip(
                          avatar: settings.density == 10
                              ? Icon(Icons.water_drop_outlined)
                              : Icon(Icons.water_drop),
                          label: Text('${(density / 10).toInt()} %')),
                    )
                  ],
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
                                      style: TextStyle(fontSize: 14),
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
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      "$bolusBestGuess mcg/mL",
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
                                      "Adjustement Bolus",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      "$initialCPTarget mg",
                                      style: TextStyle(fontSize: 24),
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
              children: [
                Container(
                  height: UIHeight + 20,
                  child: Text(
                    "Adjusted Marsh \nWeight Calculator",
                    style: TextStyle(fontSize: 24),
                  ),
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
                        // await HapticFeedback.mediumImpact();
                        // reset(toDefault: true);
                      },
                      child: Icon(Icons.refresh),
                    )),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            height: UIHeight + 24,
            child: Row(
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
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    height: UIHeight + 2,
                    prefixIcon: Icons.psychology_outlined,
                    // labelText: 'Target in mcg/mL',
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
