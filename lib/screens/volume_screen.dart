import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:propofol_dreams_app/models/target.dart';

import '../constants.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchController.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchField.dart';

class VolumeScreen extends StatefulWidget {
  const VolumeScreen({Key? key}) : super(key: key);

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends State<VolumeScreen> {
  final PDAdvancedSegmentedController adultModelController =
      PDAdvancedSegmentedController();
  final PDAdvancedSegmentedController pediatricModelController =
      PDAdvancedSegmentedController();
  PDSwitchController genderController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  final PDTableController tableController = PDTableController();
  final ScrollController scrollController = ScrollController();
  final List<Model> modelOptions = [];
  Timer timer = Timer(Duration.zero, () {});
  Duration delay = const Duration(milliseconds: 500);

  double targetInterval = 0.5;
  int durationInterval = 10; //in mins

  String result = '-- mL';
  String emptyResult = '-- mL';
  List PDTableRows = [];
  List EmptyTableRows = [
    [
      '--',
      '--',
      '--',
      '--',
    ],
    [
      '--',
      '--',
      '--',
      '--',
    ],
    [
      '--',
      '--',
      '--',
      '--',
    ]
  ];

  @override
  void initState() {
    var settings = context.read<Settings>();

    tableController.val = false;

    if (settings.inAdultView) {
      adultModelController.selection = settings.adultModel;
      genderController.val =
          settings.adultGender == Gender.Female ? true : false;
      ageController.text = settings.adultAge.toString();
      heightController.text = settings.adultHeight.toString();
      weightController.text = settings.adultWeight.toString();
      targetController.text = settings.adultTarget.toString();
      durationController.text = settings.adultDuration.toString();
    } else {
      pediatricModelController.selection = settings.pediatricModel;
      genderController.val =
          settings.pediatricGender == Gender.Female ? true : false;
      ageController.text = settings.pediatricAge.toString();
      heightController.text = settings.pediatricHeight.toString();
      weightController.text = settings.pediatricWeight.toString();
      targetController.text = settings.pediatricTarget.toString();
      durationController.text = settings.pediatricDuration.toString();
    }

    load();

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    var pref = await SharedPreferences.getInstance();
    final settings = context.read<Settings>();

    if (pref.containsKey('inAdultView')) {
      settings.inAdultView = pref.getBool('inAdultView')!;
    } else {
      settings.inAdultView = true;
    }

    if (pref.containsKey('density')) {
      settings.density = pref.getInt('density')!;
    } else {
      settings.density = 10;
    }

    if (pref.containsKey('isVolumeTableExpanded')) {
      settings.isVolumeTableExpanded = pref.getBool('isVolumeTableExpanded')!;
      tableController.val = settings.isVolumeTableExpanded;
    } else {
      settings.isVolumeTableExpanded =
          false; //TODO: set isVolumeTableExpanded = true, if device is tablet
      tableController.val = settings.isVolumeTableExpanded;
    }

    if (pref.containsKey('adultModel')) {
      String adultModel = pref.getString('adultModel')!;
      switch (adultModel) {
        case 'Marsh':
          {
            settings.adultModel = Model.Marsh;
          }
          break;

        case 'Schnider':
          {
            settings.adultModel = Model.Schnider;
          }
          break;

        case 'Eleveld':
          {
            settings.adultModel = Model.Eleveld;
          }
          break;

        default:
          {
            settings.adultModel = Model.None;
          }
          break;
      }
    } else {
      settings.adultModel = Model.None;
    }

    if (pref.containsKey('adultGender')) {
      String adultGender = pref.getString('adultGender')!;
      settings.adultGender =
          adultGender == 'Female' ? Gender.Female : Gender.Male;
    } else {
      settings.adultGender = Gender.Female;
    }

    if (pref.containsKey('adultAge')) {
      settings.adultAge = pref.getInt('adultAge');
    } else {
      settings.adultAge = 40;
    }

    if (pref.containsKey('adultHeight')) {
      settings.adultHeight = pref.getInt('adultHeight');
    } else {
      settings.adultHeight = 170;
    }

    if (pref.containsKey('adultWeight')) {
      settings.adultWeight = pref.getInt('adultWeight');
    } else {
      settings.adultWeight = 70;
    }

    if (pref.containsKey('adultTarget')) {
      settings.adultTarget = pref.getDouble('adultTarget');
    } else {
      settings.adultTarget = 3.0;
    }

    if (pref.containsKey('adultDuration')) {
      settings.adultDuration = pref.getInt('adultDuration');
    } else {
      settings.adultDuration = 60;
    }

    if (pref.containsKey('pediatricModel')) {
      String pediatricModel = pref.getString('pediatricModel')!;
      switch (pediatricModel) {
        case 'Paedfusor':
          {
            settings.pediatricModel = Model.Paedfusor;
          }
          break;

        case 'Kataria':
          {
            settings.pediatricModel = Model.Kataria;
          }
          break;

        case 'Eleveld':
          {
            settings.pediatricModel = Model.Eleveld;
          }
          break;

        default:
          {
            settings.pediatricModel = Model.None;
          }
          break;
      }
    } else {
      settings.pediatricModel = Model.None;
    }

    if (pref.containsKey('pediatricGender')) {
      String pediatricGender = pref.getString('pediatricGender')!;
      settings.pediatricGender =
          pediatricGender == 'Female' ? Gender.Female : Gender.Male;
    } else {
      settings.pediatricGender = Gender.Female;
    }

    if (pref.containsKey('pediatricAge')) {
      settings.pediatricAge = pref.getInt('pediatricAge');
    } else {
      settings.pediatricAge = 8;
    }

    if (pref.containsKey('pediatricHeight')) {
      settings.pediatricHeight = pref.getInt('pediatricHeight');
    } else {
      settings.pediatricHeight = 130;
    }

    if (pref.containsKey('pediatricWeight')) {
      settings.pediatricWeight = pref.getInt('pediatricWeight');
    } else {
      settings.pediatricWeight = 26;
    }

    if (pref.containsKey('pediatricTarget')) {
      settings.pediatricTarget = pref.getDouble('pediatricTarget');
    } else {
      settings.pediatricTarget = 3.0;
    }

    if (pref.containsKey('pediatricDuration')) {
      settings.pediatricDuration = pref.getInt('pediatricDuration');
    } else {
      settings.pediatricDuration = 60;
    }

    if (settings.inAdultView) {
      adultModelController.selection = settings.adultModel;
      genderController.val =
          settings.adultGender == Gender.Female ? true : false;
      ageController.text = settings.adultAge.toString();

      heightController.text = settings.adultHeight.toString();
      weightController.text = settings.adultWeight.toString();
      targetController.text = settings.adultTarget.toString();
      durationController.text = settings.adultDuration.toString();
    } else {
      pediatricModelController.selection = settings.pediatricModel;
      genderController.val =
          settings.pediatricGender == Gender.Female ? true : false;
      ageController.text = settings.pediatricAge.toString();
      heightController.text = settings.pediatricHeight.toString();
      weightController.text = settings.pediatricWeight.toString();
      targetController.text = settings.pediatricTarget.toString();
      durationController.text = settings.pediatricDuration.toString();
    }

    updateModelOptions(settings.inAdultView);
    run(initState: true);
  }

  void updateRowsAndResult({cols, times}) {
    List col1 = cols[0];
    List col2 = cols[1];
    List col3 = cols[2];
    List durations = times;

    int durationPlusInterval =
        int.parse(durationController.text) + 2 * durationInterval;

    List<String> resultsCol1 = [];
    List<String> resultsCol2 = [];
    List<String> resultsCol3 = [];
    List<String> resultDuration = [];

    for (int i = durationPlusInterval;
        i >= kMinDuration;
        i -= durationInterval) {
      int index = durations.indexWhere((element) {
        if ((element as Duration).inSeconds == i * 60) {
          return true;
        }
        return false;
      });

      resultDuration.add(durations[index].inMinutes.toString());
      resultsCol1.add('${col1[index].toStringAsFixed(numOfDigits)} mL');
      resultsCol2.add('${col2[index].toStringAsFixed(numOfDigits)} mL');
      resultsCol3.add('${col3[index].toStringAsFixed(numOfDigits)} mL');

      if (i == durationPlusInterval - 2 * durationInterval) {
        updateResultLabel(col2[index]);
      }
    }

    //if duration is greater than 5 mins, add extra row for the 5th mins
    if (durationPlusInterval - 2 * durationInterval >= kMinDuration) {
      int index = durations.indexWhere((element) {
        if ((element as Duration).inSeconds == kMinDuration * 60) {
          return true;
        }
        return false;
      });

      if (!resultDuration.contains(kMinDuration.toString())) {
        resultDuration.add(durations[index].inMinutes.toString());
        resultsCol1.add('${col1[index].toStringAsFixed(numOfDigits)} mL');
        resultsCol2.add('${col2[index].toStringAsFixed(numOfDigits)} mL');
        resultsCol3.add('${col3[index].toStringAsFixed(numOfDigits)} mL');
      }
    }

    List resultRows = [];
    for (int i = 0; i < resultDuration.length; i++) {
      var row = [
        resultDuration[i],
        resultsCol1[i],
        resultsCol2[i],
        resultsCol3[i]
      ];
      resultRows.add(row);
    }
    PDTableRows = resultRows;
  }

  void run({initState = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    int? duration = int.tryParse(durationController.text);
    Gender gender = genderController.val ? Gender.Female : Gender.Male;

    if (initState == false) {
      if (settings.inAdultView) {
        settings.adultModel = adultModelController.selection;
        settings.adultGender = gender;
        settings.adultAge = age;
        settings.adultHeight = height;
        settings.adultWeight = weight;
        settings.adultTarget = target;
        settings.adultDuration = duration;
      } else {
        settings.pediatricModel = pediatricModelController.selection;
        settings.pediatricGender = gender;
        settings.pediatricAge = age;
        settings.pediatricHeight = height;
        settings.pediatricWeight = weight;
        settings.pediatricTarget = target;
        settings.pediatricDuration = duration;
      }
    }

    //Check whether Age is null, if so, clear all adult & peadiatric models to Model.None
    //If Age is not null, check whether other input fiels are null
    //If all input fields are not null and Age is >0, select the model, and check whether the model is Runnable
    //If model is runnable, run the model except Model.None

    // print('Age != null');

    if (age != null &&
        height != null &&
        weight != null &&
        target != null &&
        duration != null) {
      if (age >= 0 &&
          height >= 0 &&
          weight >= 0 &&
          target >= 0 &&
          duration >= 0) {
        Model model = age >= 17 ? settings.adultModel : settings.pediatricModel;

        if (model != Model.None) {
          // print('model != Model.None');

          if (model.isEnable(age: age, height: height, weight: weight) &&
              target <= kMaxTarget &&
              target >= kMinTarget &&
              duration <= kMaxDuration &&
              duration >= kMinDuration) {
            // print('model is enable');

            if (model.checkConstraints(
                weight: weight,
                height: height,
                age: age,
                gender: gender)['assertion'] as bool) {
              // print('model pass constraints');

              DateTime start = DateTime.now();

              // var results1;
              // var results2;
              // var results3;

              Patient patient = Patient(
                  weight: weight, age: age, height: height, gender: gender);

              Pump pump = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  density: settings.density,
                  maxPumpRate: settings.max_pump_rate,
                  target: target,
                  duration: Duration(minutes: duration));

              Pump pump1 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  density: settings.density,
                  maxPumpRate: settings.max_pump_rate,
                  target: target - targetInterval,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              Pump pump2 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  density: settings.density,
                  maxPumpRate: settings.max_pump_rate,
                  target: target,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              Pump pump3 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  density: settings.density,
                  maxPumpRate: settings.max_pump_rate,
                  target: target + targetInterval,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              // Operation operation = Operation(
              //     target: target, duration: Duration(minutes: duration));

              // Operation operation1 = Operation(
              //     target: target - targetInterval,
              //     duration: Duration(minutes: duration + 2 * durationInterval));

              // Operation operation2 = Operation(
              //     target: target,
              //     duration: Duration(minutes: duration + 2 * durationInterval));

              // Operation operation3 = Operation(
              //     target: target + targetInterval,
              //     duration: Duration(minutes: duration + 2 * durationInterval));

              PDSim.Simulation sim1 = PDSim.Simulation(
                  model: model,
                  patient: patient,
                  pump: pump1);

              PDSim.Simulation sim2 = PDSim.Simulation(
                  model: model,
                  patient: patient,
                  pump: pump2);

              PDSim.Simulation sim3 = PDSim.Simulation(
                  model: model,
                  patient: patient,
                  pump: pump3);

              var results1 = sim1.estimate;

              var results2 = sim2.estimate;

              var results3 = sim3.estimate;

              DateTime finish = DateTime.now();

              Duration calculationDuration = finish.difference(start);

              print({
                'model': model,
                'patient': patient,
                'pump': pump,
                'calcuation time':
                    '${calculationDuration.inMilliseconds.toString()} milliseconds'
              });

              setState(() {
                updateRowsAndResult(cols: [
                  results1.cumulativeInfusedVolumes,
                  results2.cumulativeInfusedVolumes,
                  results3.cumulativeInfusedVolumes
                ], times: results2.times);
              });
            } else {
              // print('Model does not meet its constraint');

              setState(() {
                result = emptyResult;
                PDTableRows = EmptyTableRows;
                // print(result);
              });
            }
          } else {
            // print('Model is not enable');
            setState(() {
              result = emptyResult;
              PDTableRows = EmptyTableRows;
              // print(result);
            });
          }
        } else {
          // print('Selected Model = Model.None');
          setState(() {
            result = emptyResult;
            PDTableRows = EmptyTableRows;
            // print(result);
          });
        }
      } else {
        // print('Age <0');
        setState(() {
          result = emptyResult;
          PDTableRows = EmptyTableRows;
          // print(result);
        });
      }
    } else {
      // print('Some fields == null');
      setState(() {
        result = emptyResult;
        PDTableRows = EmptyTableRows;
        // print(result);
      });
    }
    // print('run ends');
  }

  void updateResultLabel(double d) {
    // print(i);
    setState(() {
      result = '${d.toStringAsFixed(numOfDigits)} mL';
      // print(result);
    });
  }

  void updatePDTableController(PDTableController controller) {
    final settings = Provider.of<Settings>(context, listen: false);
    settings.isVolumeTableExpanded = !settings.isVolumeTableExpanded;

    setState(() {
      controller.val = settings.isVolumeTableExpanded;
    });
  }

  void updateModelOptions(bool inAdultView) {
    modelOptions.clear();
    if (inAdultView) {
      modelOptions.add(Model.Marsh);
      modelOptions.add(Model.Schnider);
      modelOptions.add(Model.Eleveld);
    } else {
      modelOptions.add(Model.Paedfusor);
      modelOptions.add(Model.Kataria);
      modelOptions.add(Model.Eleveld);
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    if (settings.inAdultView) {
      genderController.val = toDefault
          ? true
          : settings.adultGender == Gender.Female
              ? true
              : false;
      ageController.text = toDefault
          ? 40.toString()
          : settings.adultAge != null
              ? settings.adultAge.toString()
              : '';
      heightController.text = toDefault
          ? 170.toString()
          : settings.adultHeight != null
              ? settings.adultHeight.toString()
              : '';
      weightController.text = toDefault
          ? 70.toString()
          : settings.adultWeight != null
              ? settings.adultWeight.toString()
              : '';
      targetController.text = toDefault
          ? 3.0.toString()
          : settings.adultTarget != null
              ? settings.adultTarget.toString()
              : '';
      durationController.text = toDefault
          ? 60.toString()
          : settings.adultDuration != null
              ? settings.adultDuration.toString()
              : '';
    } else {
      genderController.val = toDefault
          ? true
          : settings.pediatricGender == Gender.Female
              ? true
              : false;
      ageController.text = toDefault
          ? 8.toString()
          : settings.pediatricAge != null
              ? settings.pediatricAge.toString()
              : '';
      heightController.text = toDefault
          ? 130.toString()
          : settings.pediatricHeight != null
              ? settings.pediatricHeight.toString()
              : '';
      weightController.text = toDefault
          ? 26.toString()
          : settings.pediatricWeight != null
              ? settings.pediatricWeight.toString()
              : '';
      targetController.text = toDefault
          ? 3.0.toString()
          : settings.pediatricTarget != null
              ? settings.pediatricTarget.toString()
              : '';
      durationController.text = toDefault
          ? 60.toString()
          : settings.pediatricDuration != null
              ? settings.pediatricDuration.toString()
              : '';
    }

    updateModelOptions(settings.inAdultView);
    run();
  }

  void updatePDSegmentedController(dynamic s) {
    run();
  }

  void updatePDTextEditingController() {
    final settings = Provider.of<Settings>(context, listen: false);
    int? age = int.tryParse(ageController.text);
    if (age != null) {
      settings.inAdultView = age >= 17 ? true : false;
    }
    updateModelOptions(settings.inAdultView);
    run();
  }

  void restart() {
    final settings = Provider.of<Settings>(context, listen: false);
    updateModelOptions(settings.inAdultView);
    run();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // print(mediaQuery.size.height);

    final double UIHeight = mediaQuery.size.aspectRatio >= 0.455
        ? mediaQuery.size.height >= screenBreakPoint1
            ? 56
            : 48
        : 48;
    final double UIWidth =
        (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;

    final double screenHeight = mediaQuery.size.height -
        (Platform.isAndroid
            ? 48
            : mediaQuery.size.height >= screenBreakPoint1
                ? 88
                : 56);

    final settings = context.watch<Settings>();

    int density = settings.density;

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    int? duration = int.tryParse(durationController.text);
    double? target = double.tryParse(targetController.text);

    adultModelController.selection = settings.adultModel;
    pediatricModelController.selection = settings.pediatricModel;

    Model selectedModel = settings.inAdultView
        ? adultModelController.selection
        : pediatricModelController.selection;

    bool modelIsRunnable = selectedModel.isRunnable(
        age: age,
        height: height,
        weight: weight,
        target: target,
        duration: duration);

    final bool heightTextFieldEnabled = settings.inAdultView
        ? (adultModelController.selection as Model).target != Target.Plasma
        : (pediatricModelController.selection as Model).target != Target.Plasma;

    final bool genderSwitchControlEnabled = settings.inAdultView
        ? (adultModelController.selection as Model).target != Target.Plasma
        : (pediatricModelController.selection as Model).target != Target.Plasma;

    final ageTextFieldEnabled = !(settings.inAdultView &&
        adultModelController.selection == Model.Marsh);

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
                    settings.showMaxPumpRate
                        ? GestureDetector(
                            onTap: () async {
                              await HapticFeedback.mediumImpact();
                              settings.showMaxPumpRate =
                                  !settings.showMaxPumpRate;
                            },
                            child: Chip(
                              avatar: Icon(
                                Icons.speed_outlined,
                                color: Theme.of(context).colorScheme.onPrimary,
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
                        if (settings.inAdultView) {
                          ageController.text = settings.pediatricAge != null
                              ? settings.pediatricAge.toString()
                              : '';
                        } else {
                          ageController.text = settings.adultAge != null
                              ? settings.adultAge.toString()
                              : '';
                        }
                        settings.inAdultView = !settings.inAdultView;
                        reset();
                      },
                      onLongPress: () async {
                        await HapticFeedback.mediumImpact();
                        settings.showMaxPumpRate = !settings.showMaxPumpRate;
                      },
                      child: Chip(
                        avatar: settings.inAdultView
                            ? Icon(
                                Icons.face,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : Icon(
                                Icons.child_care_outlined,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        label: Text(
                          settings.inAdultView ? 'Adult' : 'Paed',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
                        settings.showMaxPumpRate = !settings.showMaxPumpRate;
                      },
                      child: Chip(
                        avatar: settings.density == 10
                            ? Icon(
                                Icons.water_drop_outlined,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : Icon(
                                Icons.water_drop,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        label: Text(
                          '${(density / 10).toInt()} %',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    mediaQuery.size.height >= screenBreakPoint1
                        ? IconButton(
                            onPressed: () async {
                              await HapticFeedback.mediumImpact();
                              updatePDTableController(tableController);
                            },
                            icon: tableController.val
                                ? Icon(Icons.expand_more)
                                : Icon(Icons.expand_less))
                        : Container(),
                    Text(
                      modelIsRunnable ? result : emptyResult,
                      style: TextStyle(
                          fontSize: tableController.val
                              ? 34
                              : 60), //TODO consider font size for tablets
                    )
                  ],
                ),
              ],
            ),
          ),
          mediaQuery.size.height >= screenBreakPoint1
              ? Container(
                  child: PDTable(
                    showRowNumbers: mediaQuery.size.height >= screenBreakPoint2
                        ? min(PDTableRows.length, 5)
                        : 3,
                    colHeaderIcon: Icon(Icons.psychology_alt_outlined),
                    colHeaderLabels: modelIsRunnable
                        ? [
                            (target! - targetInterval) >= 0
                                ? (target - targetInterval).toStringAsFixed(1)
                                : 0.toStringAsFixed(1),
                            (target).toStringAsFixed(1),
                            (target + targetInterval).toStringAsFixed(1)
                          ]
                        : ['--', '--', '--'],
                    rowHeaderIcon: Icon(Icons.schedule),
                    rowLabels: modelIsRunnable ? PDTableRows : EmptyTableRows,
                    tableController: tableController,
                    // scrollController: scrollController,
                    tableLabel: 'Confidence\nInterval',
                    highlightLabel: result,
                  ),
                )
              : SizedBox(
                  height: 0,
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
                  child: PDAdvancedSegmentedControl(
                    height: UIHeight,
                    options: modelOptions,
                    segmentedController: settings.inAdultView
                        ? adultModelController
                        : pediatricModelController,
                    onPressed: updatePDSegmentedController,
                    assertValues: {
                      'gender': genderController.val,
                      'age': (int.tryParse(ageController.text) ?? 0),
                      'height': (int.tryParse(heightController.text) ?? 0),
                      'weight': (int.tryParse(weightController.text) ?? 0)
                    },
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
                        await HapticFeedback.mediumImpact();
                        reset(toDefault: true);
                      },
                      child: Icon(Icons.restart_alt_outlined),
                    )),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            height: UIHeight + 28,
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
                    // helperText: '',
                    onChanged: run,
                    height: UIHeight,
                    enabled: genderSwitchControlEnabled,
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
                    range: age != null
                        ? age >= 17
                            ? [17, selectedModel == Model.Schnider ? 100 : 105]
                            : [1, 16]
                        : [1, 16],
                    onPressed: updatePDTextEditingController,
                    enabled: ageTextFieldEnabled,
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
                    range: [selectedModel.minHeight, selectedModel.maxHeight],
                    onPressed: updatePDTextEditingController,
                    enabled: heightTextFieldEnabled,
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
                    range: [selectedModel.minWeight, selectedModel.maxWeight],
                    onPressed: updatePDTextEditingController,
                    // onChanged: restart,
                    // onLongPressedStart: onLongPressStartUpdatePDTextEditingController,
                    // onLongPressedEnd: onLongPressCancelledPDTextEditingController,
                    // timer: timer,
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
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    height: UIHeight + 2,
                    prefixIcon: Icons.psychology_alt_outlined,
                    // labelText: 'Target in mcg/mL',
                    labelText: '${selectedModel.target.toString()}',
                    // helperText: '',
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: targetController,
                    range: [kMinTarget, kMaxTarget],
                    onPressed: updatePDTextEditingController,
                    // onChanged: restart,
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
                    prefixIcon: Icons.schedule,
                    // labelText: 'Duration in minutes',
                    labelText: 'Duration (mins)',
                    // helperText: '',
                    interval: double.tryParse(durationController.text) != null
                        ? double.parse(durationController.text) >= 60
                            ? 10
                            : 5
                        : 1,
                    fractionDigits: 0,
                    controller: durationController,
                    range: [kMinDuration, kMaxDuration],
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
        ],
      ),
    );
  }
}

class PDTableController extends ChangeNotifier {
  PDTableController();

  bool _val = true;

  bool get val {
    return _val;
  }

  void set val(bool v) {
    _val = v;
    notifyListeners();
  }
}

class PDTable extends StatefulWidget {
  PDTable(
      {Key? key,
      required this.tableController,
      // this.scrollController,
      required this.tableLabel,
      required this.colHeaderIcon,
      required this.colHeaderLabels,
      required this.rowHeaderIcon,
      required this.rowLabels,
      this.highlightLabel,
      this.showRowNumbers})
      : super(key: key);

  final PDTableController tableController;

  // final ScrollController? scrollController;
  final String tableLabel;
  final Icon colHeaderIcon;
  final List<String> colHeaderLabels;
  final Icon rowHeaderIcon;
  final List rowLabels;
  String? highlightLabel;
  int? showRowNumbers;

  @override
  State<PDTable> createState() => _PDTableState();
}

class _PDTableState extends State<PDTable> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double headerColWidth =
        ((mediaQuery.size.width - horizontalSidesPaddingPixel * 2) /
            (widget.colHeaderLabels.length + 1));
    final double rowColWidth =
        ((mediaQuery.size.width - horizontalSidesPaddingPixel * 2) /
            (widget.colHeaderLabels.length + 1));

    var tableHeight = (20 + PDTableRowHeight) *
        (widget.showRowNumbers! > 0 ? widget.showRowNumbers! + 1 : 3 + 1);

    var rowsHeight = (20 + PDTableRowHeight) *
            ((widget.showRowNumbers! > 0) ? widget.showRowNumbers! : 3) -
        19;

    return AnimatedContainer(
      duration: Duration(milliseconds: 1),
      // height: widget.controller.val ? (20 + PDTableRowHeight) * 4 - 19 :0,
      constraints: BoxConstraints(
        maxHeight: widget.tableController.val ? tableHeight : 0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            //This is the header row
            Container(
              height: PDTableRowHeight,
              width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
              child: Row(
                children: [
                  Container(
                    width: headerColWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.tableLabel,
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  Container(
                    child: ListView.builder(
                      // controller: widget.scrollController,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.colHeaderLabels.length,
                      itemBuilder: (buildContext, buildIndex) {
                        return Container(
                          width: headerColWidth,
                          child: Align(
                            child: PDIcon(
                              icon: widget.colHeaderIcon,
                              text: Text(widget.colHeaderLabels[buildIndex]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.primary,
            ),
            Container(
              height: rowsHeight,
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.rowLabels.length,
                  itemBuilder: (buildContext, buildIndexOutter) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          height: PDTableRowHeight,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  widget.rowLabels[buildIndexOutter].length,
                              itemBuilder: (buildContext, buildIndexInner) {
                                return Container(
                                  width: rowColWidth,
                                  alignment: buildIndexInner == 0
                                      ? Alignment.centerLeft
                                      : Alignment.center,
                                  child: buildIndexInner == 0
                                      ? PDIcon(
                                          icon: widget.rowHeaderIcon,
                                          text: Text(
                                              widget.rowLabels[buildIndexOutter]
                                                  [buildIndexInner]),
                                        )
                                      : (widget.highlightLabel ==
                                                  widget.rowLabels[
                                                          buildIndexOutter]
                                                      [buildIndexInner]) &&
                                              (buildIndexInner == 2)
                                          ? Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 4, horizontal: 8),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary), //TODO: manullay adjust light/dark theme here
                                              ),
                                              child: Text(
                                                  widget.rowLabels[
                                                          buildIndexOutter]
                                                      [buildIndexInner],
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary)), //TODO: manullay adjust light/dark theme here
                                            )
                                          : Text(
                                              widget.rowLabels[buildIndexOutter]
                                                  [buildIndexInner]),
                                );
                              }),
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.primary,
                        )
                      ],
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class PDIcon extends StatelessWidget {
  const PDIcon({
    Key? key,
    this.icon,
    this.text,
  }) : super(key: key);

  final Icon? icon;
  final Text? text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      icon ?? Container(),
      SizedBox(
        height: 0,
        width: 4,
      ),
      text ?? Container(),
    ]);
  }
}

class PDAdvancedSegmentedController extends ChangeNotifier {
  PDAdvancedSegmentedController();

  dynamic _selection;

  dynamic get selection {
    return _selection == null
        ? {'error': '_selectedOption == null'}
        : _selection!;
  }

  void set selection(s) {
    _selection = s;
    notifyListeners();
  }
}

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
