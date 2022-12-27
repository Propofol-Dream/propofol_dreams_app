import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';

import '../models/target.dart';

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
  TextEditingController depthController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  final PDTableController tableController = PDTableController();
  final ScrollController scrollController = ScrollController();
  final List<Model> modelOptions = [];
  Timer timer = Timer(Duration.zero, () {});
  Duration delay = const Duration(milliseconds: 500);

  double depthInterval = 0.5;
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
    load();

    // ageController.text = 40.toString();
    // heightController.text = 170.toString();
    // weightController.text = 70.toString();
    // depthController.text = 3.0.toString();
    // durationController.text = 60.toString();

    super.initState();
    // });
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

    if (pref.containsKey('dilution')) {
      settings.dilution = pref.getInt('dilution')!;
    } else {
      settings.dilution = 10;
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

    if (pref.containsKey('adultDepth')) {
      settings.adultDepth = pref.getDouble('adultDepth');
    } else {
      settings.adultDepth = 3.0;
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

    if (pref.containsKey('pediatricDepth')) {
      settings.pediatricDepth = pref.getDouble('pediatricDepth');
    } else {
      settings.pediatricDepth = 3.0;
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
      depthController.text = settings.adultDepth.toString();
      durationController.text = settings.adultDuration.toString();
    } else {
      pediatricModelController.selection = settings.pediatricModel;
      genderController.val =
          settings.pediatricGender == Gender.Female ? true : false;
      ageController.text = settings.pediatricAge.toString();
      heightController.text = settings.pediatricHeight.toString();
      weightController.text = settings.pediatricWeight.toString();
      depthController.text = settings.pediatricDepth.toString();
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
    if (durationPlusInterval - 2 * durationInterval > kMinDuration) {
      int index = durations.indexWhere((element) {
        if ((element as Duration).inSeconds == kMinDuration * 60) {
          return true;
        }
        return false;
      });

      resultDuration.add(durations[index].inMinutes.toString());
      resultsCol1.add('${col1[index].toStringAsFixed(numOfDigits)} mL');
      resultsCol2.add('${col2[index].toStringAsFixed(numOfDigits)} mL');
      resultsCol3.add('${col3[index].toStringAsFixed(numOfDigits)} mL');
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
    double? depth = double.tryParse(depthController.text);
    int? duration = int.tryParse(durationController.text);
    Gender gender = genderController.val ? Gender.Female : Gender.Male;

    if (settings.inAdultView) {
      //setting provider cannot be directly under initState
      if (initState == false) {
        settings.adultModel = adultModelController.selection;
        settings.adultGender = gender;
        settings.adultAge = age;
        settings.adultHeight = height;
        settings.adultWeight = weight;
        settings.adultDepth = depth;
        settings.adultDuration = duration;
      }
    } else {
      if (initState == false) {
        settings.pediatricModel = pediatricModelController.selection;
        settings.pediatricGender = gender;
        settings.pediatricAge = age;
        settings.pediatricHeight = height;
        settings.pediatricWeight = weight;
        settings.pediatricDepth = depth;
        settings.pediatricDuration = duration;
      }
    }

    //Check whether Age is null, if so, clear all adult & peadiatric models to Model.None
    //If Age is not null, check whether other input fiels are null
    //If all input fields are not null and Age is >0, select the model, and check whether the model is Runnable
    //If model is runnable, run the model except Model.None
    if (age != null) {
      // print('Age != null');

      if (height != null &&
          weight != null &&
          depth != null &&
          duration != null) {
        if (age >= 0) {
          // print('Age >=0');
          Model model = Model.None;

          model = age >= 17 ? settings.adultModel : settings.pediatricModel;

          if (model != Model.None) {
            // print('model != Model.None');

            if (model.isEnable(age: age, height: height, weight: weight) &&
                depth <= kMaxDepth &&
                depth >= kMinDepth &&
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

                var results1;
                var results2;
                var results3;

                Patient patient = Patient(
                    weight: weight, age: age, height: height, gender: gender);

                Pump pump = Pump(
                    time_step: settings.time_step!,
                    dilution: settings.dilution!,
                    max_pump_rate: settings.max_pump_rate!);

                Operation operation =
                    Operation(depth: depth, duration: duration);

                PDSim.Simulation sim = PDSim.Simulation(
                    model: model, patient: patient, pump: pump);

                results1 = sim.estimate(
                    operation: Operation(
                        depth: depth - depthInterval,
                        duration: duration + 2 * durationInterval));

                results2 = sim.estimate(
                    operation: Operation(
                        depth: depth,
                        duration: duration + 2 * durationInterval));

                results3 = sim.estimate(
                    operation: Operation(
                        depth: depth + depthInterval,
                        duration: duration + 2 * durationInterval));

                DateTime finish = DateTime.now();

                Duration calculationDuration = finish.difference(start);
                // print({'duration': calculationDuration.toString()});

                // print({
                //   'model': model,
                //   'age': age,
                //   'height': height,
                //   'weight': weight,
                //   'depth': depth,
                //   'duration': duration,
                //   'calcuation time':
                //       '${calculationDuration.inMilliseconds.toString()} milliseconds'
                // });

                print({
                  'model': model,
                  'patient': patient,
                  'operation': operation,
                  'pump': pump,
                  'calcuation time':
                      '${calculationDuration.inMilliseconds.toString()} milliseconds'
                });

                setState(() {
                  updateRowsAndResult(cols: [
                    results1['cumulative_infused_volumes'],
                    results2['cumulative_infused_volumes'],
                    results3['cumulative_infused_volumes']
                  ], times: results2['times']);
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
    } else {
      // print('Age == null');
      adultModelController.selection = Model.None;
      pediatricModelController.selection = Model.None;
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
      depthController.text = toDefault
          ? 3.0.toString()
          : settings.adultDepth != null
              ? settings.adultDepth.toString()
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
      depthController.text = toDefault
          ? 3.0.toString()
          : settings.pediatricDepth != null
              ? settings.pediatricDepth.toString()
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

    final double UIHeight =
        mediaQuery.size.width / mediaQuery.size.height >= 0.455 ? 56 : 48;
    final double UIWidth =
        (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;

    final settings = context.watch<Settings>();

    int dilution = settings.dilution ?? 10;

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    int? duration = int.tryParse(durationController.text);
    double? depth = double.tryParse(depthController.text);

    adultModelController.selection = settings.adultModel;
    pediatricModelController.selection = settings.pediatricModel;

    Model selectedModel = settings.inAdultView
        ? adultModelController.selection
        : pediatricModelController.selection;

    bool modelIsRunnable = selectedModel.isRunnable(
        age: age,
        height: height,
        weight: weight,
        depth: depth,
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
      height: mediaQuery.size.height - (Platform.isAndroid ? 48 : 88),
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
                      child: Chip(
                        avatar: settings.inAdultView
                            ? Icon(Icons.face)
                            : Icon(Icons.child_care_outlined),
                        label: Text(settings.inAdultView ? 'Adult' : 'Paed'),
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    GestureDetector(
                      onTap: () async {
                        await HapticFeedback.mediumImpact();
                        settings.dilution == 10
                            ? settings.dilution = 20
                            : settings.dilution = 10;
                        run();
                      },
                      child: Chip(
                          avatar: settings.dilution == 10
                              ? Icon(Icons.water_drop_outlined)
                              : Icon(Icons.water_drop),
                          label: Text('${(dilution / 10).toInt()} %')),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () async {
                          await HapticFeedback.mediumImpact();
                          updatePDTableController(tableController);
                        },
                        icon: tableController.val
                            ? Icon(Icons.expand_more)
                            : Icon(Icons.expand_less)),
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
          Container(
            child: PDTable(
              colHeaderIcon: Icon(Icons.psychology_outlined),
              colHeaderLabels: modelIsRunnable
                  ? [
                      (depth! - depthInterval) >= 0
                          ? (depth! - depthInterval).toStringAsFixed(1)
                          : 0.toStringAsFixed(1),
                      (depth).toStringAsFixed(1),
                      (depth + depthInterval).toStringAsFixed(1)
                    ]
                  : ['--', '--', '--'],
              rowHeaderIcon: Icon(Icons.schedule),
              rowLabels: modelIsRunnable ? PDTableRows : EmptyTableRows,
              tableController: tableController,
              // scrollController: scrollController,
              tableLabel: 'Confidence\nInterval',
              highlightLabel: result,
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
                              strokeAlign: StrokeAlign.outside,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      ),
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        reset(toDefault: true);
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
                    prefixIcon: Icons.calendar_month,
                    labelText: 'Age',
                    helperText: '',
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
                    prefixIcon: Icons.straighten,
                    labelText: 'Height (cm)',
                    helperText: '',
                    interval: 1,
                    fractionDigits: 0,
                    controller: heightController,
                    range: [selectedModel.minHeight, selectedModel.maxHeight],
                    onPressed: updatePDTextEditingController,
                    // onChanged: restart,
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
                    prefixIcon: Icons.monitor_weight_outlined,
                    labelText: 'Weight (kg)',
                    helperText: '',
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
            height: UIHeight + 24,
            child: Row(
              children: [
                Container(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.psychology_outlined,
                    // labelText: 'Depth in mcg/mL',
                    labelText: '${selectedModel.target.toString()}',
                    helperText: '',
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: depthController,
                    range: [kMinDepth, kMaxDepth],
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
                    prefixIcon: Icons.schedule,
                    // labelText: 'Duration in minutes',
                    labelText: 'Duration (mins)',
                    helperText: '',
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

    return AnimatedContainer(
      duration: Duration(milliseconds: 1),
      // height: widget.controller.val ? (20 + PDTableRowHeight) * 4 - 19 :0,
      constraints: BoxConstraints(
        maxHeight: widget.tableController.val
            ? (20 + PDTableRowHeight) *
                (widget.showRowNumbers != null
                    ? widget.showRowNumbers! + 1
                    : 3 + 1)
            : 0,
      ),
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
            height: (20 + PDTableRowHeight) *
                    ((widget.showRowNumbers != null)
                        ? widget.showRowNumbers!
                        : 3) -
                19,
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
    Model seletedModel = widget.segmentedController.selection as Model;
    return !(seletedModel.checkConstraints(
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
    Model seletedModel = widget.segmentedController.selection as Model;
    return (seletedModel.checkConstraints(
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
            errorText: errorText,
            errorStyle: isError
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : TextStyle(color: Theme.of(context).colorScheme.primary),
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
                        strokeAlign: StrokeAlign.outside,
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

class PDSwitchController extends ChangeNotifier {
  PDSwitchController();

  bool _val = true;

  bool get val {
    return _val;
  }

  void set val(bool v) {
    _val = v;
    notifyListeners();
  }
}

class PDSwitchField extends StatefulWidget {
  PDSwitchField({
    Key? key,
    required this.prefixIcon,
    required this.labelTexts,
    required this.helperText,
    required this.controller,
    required this.onChanged,
    required this.height,
    this.enabled = true,
  }) : super(key: key);

  final Map<bool, String> labelTexts;
  final IconData prefixIcon;
  final String helperText;
  final PDSwitchController controller;
  final Function onChanged;
  bool enabled;
  double height;

  @override
  State<PDSwitchField> createState() => _PDSwitchFieldState();
}

class _PDSwitchFieldState extends State<PDSwitchField> {
  // dispose it when the widget is unmounted
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController textEditingController =
        TextEditingController(text: widget.labelTexts[widget.controller.val]!);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          controller: textEditingController,
          style: TextStyle(
              color: widget.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor),
          decoration: InputDecoration(
            filled: widget.enabled ? true : false,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            prefixIcon: Icon(
              widget.prefixIcon,
              color: widget.enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
            prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        Container(
          height: widget.height,
          child: Switch(
            activeColor: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
            activeTrackColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            inactiveThumbColor: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
            inactiveTrackColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            value: widget.controller.val,
            onChanged: widget.enabled
                ? (val) async {
                    await HapticFeedback.mediumImpact();
                    setState(() {
                      widget.controller.val = val;
                    });
                    widget.onChanged();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
