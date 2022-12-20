import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;

import '../constants.dart';

class VolumeScreen extends StatefulWidget {
  const VolumeScreen({Key? key}) : super(key: key);

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends State<VolumeScreen> {
  final PDSegmentedController adultModelController = PDSegmentedController();
  final PDSegmentedController pediatricModelController =
      PDSegmentedController();
  final PDSwitchController genderController = PDSwitchController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController targetController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final PDTableController tableController = PDTableController();
  final List<Model> modelOptions = [];
  Timer timer = Timer(Duration.zero, () {});
  Duration delay = const Duration(milliseconds: 500);

  int timeStep = 1; //in secs
  int propofolDensity = 10;
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

  void updatePDSegmentedController(
      PDSegmentedController controller, dynamic s) {
    controller.selection = s;
    run();
  }

  void updatePDTableController(PDTableController controller) {
    setState(() {
      controller.val = !controller.val;
    });
  }

  void updatePDTextEditingController() {
    // print('updatePDTextEditingController');
    updateModelOptions(int.tryParse(ageController.text) ?? 0);
    run();
  }

  void updateRowsAndResult({cols, times}) {
    List col1 = cols[0];
    List col2 = cols[1];
    List col3 = cols[2];
    List durations = times;

    int durationPlusInterval =
        int.parse(durationController.text) + durationInterval;

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

      if (i == durationPlusInterval - durationInterval) {
        updateResultLabel(col2[index]);
      }
    }

    //if duration is greater than 5 mins, add extra row for the 5th mins
    if (durationPlusInterval - durationInterval > kMinDuration) {
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

  void run({int cycle = 1}) {
    // print('run');

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    int? duration = int.tryParse(durationController.text);
    Gender gender = genderController.val ? Gender.Female : Gender.Male;

    //Check whether Age is null, if so, clear all adult & peadiatric models to Model.None
    //If Age is not null, check whether other input fiels are null
    //If all input fields are not null and Age is >0, select the model, and check whether the model is Runnable
    //If model is runnable, run the model except Model.None
    if (age != null) {
      // print('Age != null');

      if (height != null &&
          weight != null &&
          target != null &&
          duration != null) {
        if (age >= 0) {
          // print('Age >=0');
          Model model = age >= 17
              ? adultModelController.selection
              : pediatricModelController.selection;

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

                var results1;
                var results2;
                var results3;

                for (int i = 0; i < cycle; i++) {
                  PDSim.Simulation sim = PDSim.Simulation(
                    model: model,
                    weight: weight,
                    height: height,
                    age: age,
                    gender: genderController.val ? Gender.Female : Gender.Male,
                    time_step: timeStep,
                  );

                  results1 = sim.estimate(
                    target: target - targetInterval,
                    duration: duration + durationInterval,
                  );

                  results2 = sim.estimate(
                    target: target,
                    duration: duration + durationInterval,
                  );

                  results3 = sim.estimate(
                    target: target + targetInterval,
                    duration: duration + durationInterval,
                  );
                }

                DateTime finish = DateTime.now();

                Duration calculationDuration = finish.difference(start);
                // print({'duration': calculationDuration.toString()});

                print({
                  'model': model,
                  'age': age,
                  'height': height,
                  'weight': weight,
                  'target': target,
                  'duration': duration,
                  'calcuation time':
                      '${calculationDuration.inMilliseconds.toString()} milliseconds'
                });
                updateRowsAndResult(cols: [
                  results1['cumulative_infused_volumes'],
                  results2['cumulative_infused_volumes'],
                  results3['cumulative_infused_volumes']
                ], times: results2['times']);
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

  @override
  void initState() {
    reset(resetModelSelection: true);
    tableController.val = false;
    super.initState();
  }

  void reset({bool resetModelSelection = false}) {
    if (resetModelSelection == true) {
      adultModelController.selection = Model.Marsh;
      pediatricModelController.selection = Model.Paedfusor;
    }

    int? age = int.tryParse(ageController.text);
    // print(age);
    if (age == null) {
      genderController.val = true;
      ageController.text = 40.toString();
      heightController.text = 170.toString();
      weightController.text = 70.toString();
      targetController.text = 3.0.toString();
      durationController.text = 60.toString();
    } else if (age >= 17) {
      genderController.val = true;
      ageController.text = 40.toString();
      heightController.text = 170.toString();
      weightController.text = 70.toString();
      targetController.text = 3.0.toString();
      durationController.text = 60.toString();
    } else if (age < 17) {
      genderController.val = true;
      ageController.text = 8.toString();
      heightController.text = 130.toString();
      weightController.text = 26.toString();
      targetController.text = 3.0.toString();
      durationController.text = 60.toString();
    }

    updateModelOptions(int.tryParse(ageController.text) ?? 0);

    // updateModelOptions(int.parse(ageController.text));
    // adultModelController.selection = modelOptions.first;
    run();
  }

  void restart() {
    updateModelOptions(int.tryParse(ageController.text) ?? 0);
    run();
  }

  updateModelOptions(int age) {
    modelOptions.clear();
    if (age > 16) {
      modelOptions.add(Model.Marsh);
      modelOptions.add(Model.Schnider);
      modelOptions.add(Model.Eleveld);
    } else if (age <= 16 || age > 0) {
      modelOptions.add(Model.Paedfusor);
      modelOptions.add(Model.Kataria);
      modelOptions.add(Model.Eleveld);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    int? duration = int.tryParse(durationController.text);
    double? target = double.tryParse(targetController.text);

    updateModelOptions(age ?? 0);

    Model selectedModel = (age ?? 0) >= 17
        ? adultModelController.selection
        : pediatricModelController.selection;

    bool modelIsRunnable = selectedModel.isRunnable(
        age: age,
        height: height,
        weight: weight,
        target: target,
        duration: duration);

    final bool heightTextFieldEnabled = (age ?? 0) >= 17
        ? adultModelController.selection != Model.Marsh
        : pediatricModelController.selection == Model.Eleveld;

    final bool genderSwitchControlEnabled = (age ?? 0) >= 17
        ? adultModelController.selection != Model.Marsh
        : pediatricModelController.selection == Model.Eleveld;

    return Scaffold(
      body: SingleChildScrollView(
        physics: mediaQuery.viewInsets.bottom <= 0
            ? NeverScrollableScrollPhysics()
            : BouncingScrollPhysics(),
        child: Container(
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
                          onTap: () {
                            if (age != null) {
                              if (age >= 17) {
                                ageController.text = '8';
                              } else {
                                ageController.text = '40';
                              }
                              reset();
                            }
                          },
                          child: Chip(
                            avatar: (age ?? 0) >= 17
                                ? Icon(Icons.face)
                                : Icon(Icons.child_care_outlined),
                            label:
                                (age ?? 0) >= 17 ? Text('Adult') : Text('Paed'),
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Chip(
                            avatar: Icon(Icons.opacity),
                            label: Text('${(propofolDensity / 10).toInt()} %'))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () =>
                                updatePDTableController(tableController),
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
                  colHeaderIcon: Icon(Icons.airline_seat_flat_outlined),
                  colHeaderLabels: modelIsRunnable
                      ? [
                          (target! - targetInterval) >= 0
                              ? (target! - targetInterval).toStringAsFixed(1)
                              : 0.toStringAsFixed(1),
                          (target).toStringAsFixed(1),
                          (target + targetInterval).toStringAsFixed(1)
                        ]
                      : ['--', '--', '--'],
                  rowHeaderIcon: Icon(Icons.schedule),
                  rowLabels: modelIsRunnable ? PDTableRows : EmptyTableRows,
                  controller: tableController,
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
                    PDSegmentedControl(
                      options: modelOptions,
                      // int.parse(ageController.text) > 17
                      //     ? [Model.Marsh, Model.Schnider, Model.Eleveld]
                      //     : [Model.Paedfusor, Model.Kataria, Model.Eleveld],
                      segmentedController:
                          (int.tryParse(ageController.text) ?? 0) > 16
                              ? adultModelController
                              : pediatricModelController,
                      onPressed: run,
                      assertValues: {
                        'gender': genderController.val,
                        'age': (int.tryParse(ageController.text) ?? 0),
                        'height': (int.tryParse(heightController.text) ?? 0),
                        'weight': (int.tryParse(weightController.text) ?? 0)
                      },
                    ),
                    Container(
                        height: 59,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                          ),
                          onPressed: reset,
                          child: Icon(Icons.refresh),
                        )),
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Container(
                    width: (mediaQuery.size.width - 40) / 2,
                    child: PDSwitchField(
                      icon: const Icon(Icons.wc),
                      controller: genderController,
                      labelTexts: {
                        true: Gender.Female.toString(),
                        false: Gender.Male.toString()
                      },
                      helperText: '',
                      onChanged: run,
                      enabled: genderSwitchControlEnabled,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                    height: 0,
                  ),
                  Container(
                    width: (mediaQuery.size.width - 40) / 2,
                    child: PDTextField(
                      icon: const Icon(Icons.favorite_border),
                      labelText: 'Age',
                      helperText: '',
                      interval: 1.0,
                      fractionDigits: 0,
                      controller: ageController,
                      range: age != null
                          ? age >= 17
                              ? [
                                  17,
                                  selectedModel == Model.Schnider ? 100 : 105
                                ]
                              : [1, 16]
                          : [1, 16],
                      onPressed: updatePDTextEditingController,
                      onChanged: restart,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Container(
                    width: (mediaQuery.size.width - 40) / 2,
                    child: PDTextField(
                      icon: Icon(Icons.straighten),
                      labelText: 'Height (cm)',
                      helperText: '',
                      interval: 1,
                      fractionDigits: 0,
                      controller: heightController,
                      range: [selectedModel.minHeight, selectedModel.maxHeight],
                      onPressed: updatePDTextEditingController,
                      onChanged: restart,
                      enabled: heightTextFieldEnabled,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                    height: 0,
                  ),
                  Container(
                    width: (mediaQuery.size.width - 40) / 2,
                    child: PDTextField(
                      icon: const Icon(Icons.monitor_weight_outlined),
                      labelText: 'Weight (kg)',
                      helperText: '',
                      interval: 1.0,
                      fractionDigits: 0,
                      controller: weightController,
                      range: [selectedModel.minWeight, selectedModel.maxWeight],
                      onPressed: updatePDTextEditingController,
                      onChanged: restart,
                      // onLongPressedStart: onLongPressStartUpdatePDTextEditingController,
                      // onLongPressedEnd: onLongPressCancelledPDTextEditingController,
                      // timer: timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Container(
                    width: (mediaQuery.size.width - 40) / 2,
                    child: PDTextField(
                      icon: const Icon(Icons.airline_seat_flat_outlined),
                      // labelText: 'Depth in mcg/mL',
                      labelText:
                          '${selectedModel.target.toString().replaceAll('_', ' ')}',
                      helperText: '',
                      interval: 0.5,
                      fractionDigits: 1,
                      controller: targetController,
                      range: [kMinTarget, kMaxTarget],
                      onPressed: updatePDTextEditingController,
                      onChanged: restart,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                    height: 0,
                  ),
                  Container(
                    width: (mediaQuery.size.width - 40) / 2,
                    child: PDTextField(
                      icon: const Icon(Icons.schedule),
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
                      onChanged: restart,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          BottomNavigationBar(type: BottomNavigationBarType.fixed, items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined), label: 'Volume'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Duration'),
        BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'TCI'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ]), // This trailing comma makes auto-formatting nicer for build methods.
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
  const PDTable(
      {Key? key,
      required this.controller,
      required this.tableLabel,
      required this.colHeaderIcon,
      required this.colHeaderLabels,
      required this.rowHeaderIcon,
      required this.rowLabels,
      this.highlightLabel})
      : super(key: key);

  final PDTableController controller;
  final String tableLabel;
  final Icon colHeaderIcon;
  final List<String> colHeaderLabels;
  final Icon rowHeaderIcon;
  final List rowLabels;
  final String? highlightLabel;

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
        maxHeight: widget.controller.val ? (20 + PDTableRowHeight) * 4 : 0,
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
            height: (20 + PDTableRowHeight) * 3 - 19,
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
                                    : widget.highlightLabel ==
                                            widget.rowLabels[buildIndexOutter]
                                                [buildIndexInner]
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

class PDSegmentedController extends ChangeNotifier {
  PDSegmentedController();

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

class PDSegmentedControl extends StatefulWidget {
  const PDSegmentedControl({
    Key? key,
    required this.options,
    required this.segmentedController,
    required this.onPressed,
    required this.assertValues,
  }) : super(key: key);

  final List options;
  final PDSegmentedController segmentedController;
  final Function onPressed;
  final Map<String, Object> assertValues;

  @override
  State<PDSegmentedControl> createState() => _PDSegmentedControlState();
}

class _PDSegmentedControlState extends State<PDSegmentedControl> {
  @override
  void dispose() {
    widget.segmentedController.dispose();
    super.dispose();
  }

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
            horizontalSidesPaddingPixel -
            59 -
            30,
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            errorText: errorText,
            errorStyle: isError
                ? TextStyle(color: Theme.of(context).errorColor)
                : TextStyle(color: Theme.of(context).colorScheme.primary),
            border: const OutlineInputBorder(
                borderSide: BorderSide(width: 0, style: BorderStyle.none)),
          ),
        ),
      ),
      Container(
        height: 59,
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
                    ? () {
                        widget.segmentedController.selection =
                            widget.options[buildIndex];
                        widget.onPressed();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: widget.segmentedController.selection ==
                          widget.options[buildIndex]
                      ? Theme.of(context).colorScheme.onPrimary
                      : isError
                          ? Theme.of(context).errorColor
                          : Theme.of(context).colorScheme.primary,
                  backgroundColor: widget.segmentedController.selection ==
                          widget.options[buildIndex]
                      ? isError
                          ? Theme.of(context).errorColor
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
                                ? Theme.of(context).errorColor
                                : Theme.of(context).colorScheme.primary
                            : isError
                                ? Theme.of(context).errorColor
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
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class PDTextField extends StatefulWidget {
  PDTextField({
    Key? key,
    required this.icon,
    required this.labelText,
    required this.helperText,
    required this.interval,
    required this.fractionDigits,
    required this.controller,
    required this.onPressed,
    required this.onChanged,
    required this.range,
    this.timer,
    this.enabled = true,
  }) : super(key: key);

  final String labelText;
  final Icon icon;
  final String helperText;
  final double interval;
  final int fractionDigits;
  final TextEditingController controller;
  final range;
  Function onPressed;
  Function onChanged;
  Function? onLongPressedStart;
  Function? onLongPressedEnd;
  bool enabled;
  Timer? timer;
  final Duration delay = Duration(milliseconds: 50);

  @override
  State<PDTextField> createState() => _PDTextFieldState();
}

class _PDTextFieldState extends State<PDTextField> {
  // final _textEditingController = TextEditingController();

  // dispose it when the widget is unmounted
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //this controls size of the plus & minus buttons
    double suffixIconConstraintsWidth = 84;
    double suffixIconConstraintsHeight = 59;

    var val = widget.fractionDigits > 0
        ? double.tryParse(widget.controller.text)
        : int.tryParse(widget.controller.text);

    bool isWithinRange =
        val != null ? val >= widget.range[0] && val <= widget.range[1] : false;
    bool isNumeric = widget.controller.text.isEmpty ? false : val != null;

    return Stack(alignment: Alignment.topRight, children: [
      TextField(
        onChanged: (val) {
          double? current = double.tryParse(val);
          if (current != null) {
            widget.onPressed();
          }
        },
        enabled: widget.enabled,
        style: TextStyle(
            color: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor),
        scrollPadding: EdgeInsets.all(48.0),
        onSubmitted: (val) {
          // double? current = double.tryParse(val);
          // if (current != null) {
          widget.onPressed();
          // }
        },
        controller: widget.controller,
        keyboardType: TextInputType.numberWithOptions(
            signed: true, decimal: widget.fractionDigits > 0 ? true : false),
        // keyboardType: TextInputType.numberWithOptions(
        //     signed: widget.fractionDigits > 0 ? true : false,
        //     decimal: widget.fractionDigits > 0 ? true : false),
        decoration: InputDecoration(
          errorText: widget.controller.text.isEmpty
              ? 'Please enter a value'
              : isNumeric
                  ? isWithinRange
                      ? null
                      : 'min: ${widget.range[0]} and max: ${widget.range[1]}'
                  : 'Please enter a value',
          prefixIcon: widget.icon,
          prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
          helperText: widget.helperText,
          labelText: widget.labelText,
          border: const OutlineInputBorder(),
        ),
      ),
      widget.controller.text.isNotEmpty
          ? Container(
              width: suffixIconConstraintsWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      width: suffixIconConstraintsWidth / 2,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0, style: BorderStyle.none)),
                      height: suffixIconConstraintsHeight,
                      child: Icon(
                        Icons.remove,
                        color: widget.enabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    onTap: widget.enabled
                        ? () {
                            double? prev =
                                double.tryParse(widget.controller.text);
                            if (prev != null && prev >= widget.range[0]) {
                              prev -= widget.interval;
                              prev >= widget.range[0]
                                  ? widget.controller.text = prev
                                      .toStringAsFixed(widget.fractionDigits)
                                  : widget.controller.text = widget.range[0]
                                      .toStringAsFixed(widget.fractionDigits);
                              widget.onPressed();
                            }
                          }
                        : null,
                    onLongPress: widget.enabled
                        ? () {
                            widget.timer = Timer.periodic(widget.delay, (t) {
                              double? prev =
                                  double.tryParse(widget.controller.text);
                              if (prev != null && prev >= widget.range[0]) {
                                prev -= widget.interval;
                                prev >= widget.range[0]
                                    ? widget.controller.text = prev
                                        .toStringAsFixed(widget.fractionDigits)
                                    : widget.controller.text = widget.range[0]
                                        .toStringAsFixed(widget.fractionDigits);
                              }
                            });
                          }
                        : null,
                    onLongPressEnd: (_) {
                      if (widget.timer != null) {
                        widget.timer!.cancel();
                        widget.onPressed();
                      }
                    },
                  ),
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      width: suffixIconConstraintsWidth / 2,
                      height: suffixIconConstraintsHeight,
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0, style: BorderStyle.none)),
                      child: Icon(
                        Icons.add,
                        color: widget.enabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    onTap: widget.enabled
                        ? () {
                            double? prev =
                                double.tryParse(widget.controller.text);
                            if (prev != null && prev <= widget.range[1]) {
                              prev += widget.interval;
                              prev <= widget.range[1]
                                  ? widget.controller.text = prev
                                      .toStringAsFixed(widget.fractionDigits)
                                  : widget.controller.text = widget.range[1]
                                      .toStringAsFixed(widget.fractionDigits);
                              widget.onPressed();
                            }
                          }
                        : null,
                    onLongPress: widget.enabled
                        ? () {
                            widget.timer = Timer.periodic(widget.delay, (t) {
                              double? prev =
                                  double.tryParse(widget.controller.text);
                              if (prev != null && prev <= widget.range[1]) {
                                prev += widget.interval;
                                prev <= widget.range[1]
                                    ? widget.controller.text = prev
                                        .toStringAsFixed(widget.fractionDigits)
                                    : widget.controller.text = widget.range[1]
                                        .toStringAsFixed(widget.fractionDigits);
                              }
                            });
                          }
                        : null,
                    onLongPressEnd: (_) {
                      if (widget.timer != null) {
                        widget.timer!.cancel();
                        widget.onPressed();
                      }
                    },
                  ),
                ],
              ),
            )
          : Container(
              width: 0,
              height: 0,
            )
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
    required this.icon,
    required this.labelTexts,
    required this.helperText,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  final Map<bool, String> labelTexts;
  final Icon icon;
  final String helperText;
  final PDSwitchController controller;
  final Function onChanged;
  bool enabled;

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
            prefixIcon: widget.icon,
            prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
            // suffixIconConstraints: BoxConstraints.tight(const Size(60, 59)),
            // suffixIcon:
            // Switch(
            //   activeColor: widget.enabled
            //       ? Theme.of(context).colorScheme.primary
            //       : Theme.of(context).disabledColor,
            //   activeTrackColor:
            //       Theme.of(context).colorScheme.primary.withOpacity(0.1),
            //   inactiveThumbColor: widget.enabled
            //       ? Theme.of(context).colorScheme.primary
            //       : Theme.of(context).disabledColor,
            //   inactiveTrackColor:
            //       Theme.of(context).colorScheme.primary.withOpacity(0.1),
            //   value: widget.controller.val,
            //   onChanged: (val) {
            //     setState(() {
            //       widget.controller.val = val;
            //     });
            //     widget.onChanged();
            //   },
            // ),
          ),
        ),
        Container(
          height: 59,
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
            onChanged: (val) {
              setState(() {
                widget.controller.val = val;
              });
              widget.onChanged();
            },
          ),
        ),
      ],
    );
  }
}
