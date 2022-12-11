import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController depthController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final PDTableController tableController = PDTableController();
  final List<Model> modelOptions = [];
  Timer timer = Timer(Duration.zero, () {});
  Duration delay = const Duration(milliseconds: 500);

  int refreshRate = 10; //in secs
  int propofolDensity = 10;
  double depthInterval = 0.5;
  int durationInterval = 10; //in mins

  int? age;

  double result = 0;

  List PDTableHeader = [
    // PDIcon(
    //   icon: Icon(Icons.airline_seat_flat_outlined),
    //   text: Text('--'),
    // ),
    // PDIcon(
    //   icon: Icon(Icons.airline_seat_flat_outlined),
    //   text: Text('--'),
    // ),
    // PDIcon(
    //   icon: Icon(Icons.airline_seat_flat_outlined),
    //   text: Text('--'),
    // )
  ];

  List PDTableRows = [
    // [
    //   PDIcon(
    //     icon: Icon(Icons.schedule),
    //     text: Text('--'),
    //   ),
    //   Text('-- mL'),
    //   Text('-- mL'),
    //   Text('-- mL')
    // ],
    // [
    //   PDIcon(
    //     icon: Icon(Icons.schedule),
    //     text: Text('--'),
    //   ),
    //   Text('-- mL'),
    //   Text('-- mL'),
    //   Text('-- mL')
    // ],
    // [
    //   PDIcon(
    //     icon: Icon(Icons.schedule),
    //     text: Text('--'),
    //   ),
    //   Text('-- mL'),
    //   Text('-- mL'),
    //   Text('-- mL')
    // ],
  ];

  void updatePDSegmentedController(PDSegmentedController controller,
      dynamic s) {
    controller.selection = s;
    run();
  }

  void updatePDTableController(PDTableController controller) {
    setState(() {
      controller.val = !controller.val;
    });
  }

  // void onLongPressStartUpdatePDTextEditingController(Timer timer,
  //     TextEditingController controller, double interval, int fractionDigits) {
  //   timer = Timer.periodic(delay, (t) {
  //     print(t.tick);
  //     print('timer');
  //     print(timer.isActive);
  //     print('t');
  //     print(t.isActive);
  //     // updatePDTextEditingController(controller, interval, fractionDigits);
  //   });
  // }

  // void onLongPressCancelledPDTextEditingController(Timer timer){
  //   print(timer.isActive);
  //   timer.cancel();
  //   print(timer.isActive);
  // }

  // void updatePDTextEditingController(
  //     TextEditingController controller, double interval, int fractionDigits) {
  //   double? x = double.tryParse(controller.text);
  //
  //   if (x != null) {
  //     x += interval;
  //
  //     // setState(() {
  //     controller.text = x!.toStringAsFixed(fractionDigits);
  //     //Update modelOptions based on Age;
  //     if (controller == ageController) {
  //       updateModelOptions(int.parse(ageController.text));
  //     }
  //
  //     //If the current selected model is not found in the updated modelOptions,
  //     //select the first model in the updated modelOptions,
  //     // if (!modelOptions.contains(adultModelController.selection as Model)) {
  //     //   adultModelController.selection = modelOptions.first;
  //     // }
  //     // });
  //   }
  //   run();
  // }

  void updatePDTextEditingController() {
    updateModelOptions(age??0);
    run();
  }

  void updatePDTableHeader() {
    double? tryParseDepthController = double.tryParse(depthController.text);

    if (tryParseDepthController != null) {
      PDTableHeader = [
        PDIcon(
            icon: Icon(Icons.airline_seat_flat_outlined),
            text: Text(
                '${(tryParseDepthController - depthInterval).toStringAsFixed(
                    1)}')),
        PDIcon(
            icon: Icon(Icons.airline_seat_flat_outlined),
            text: Text('${(tryParseDepthController).toStringAsFixed(1)}')),
        PDIcon(
            icon: Icon(Icons.airline_seat_flat_outlined),
            text: Text(
                '${(tryParseDepthController + depthInterval).toStringAsFixed(
                    1)}')),
      ];
    } else {
      PDTableHeader = [
        Text(
          'Confidence\nInterval',
          style: TextStyle(fontSize: 10),
        ),
        PDIcon(
          icon: Icon(Icons.airline_seat_flat_outlined),
          text: Text('--'),
        ),
        PDIcon(
          icon: Icon(Icons.airline_seat_flat_outlined),
          text: Text('--'),
        ),
        PDIcon(
          icon: Icon(Icons.airline_seat_flat_outlined),
          text: Text('--'),
        )
      ];
    }
  }

  void updateRowsAndResult({cols, times}) {
    //updatePDTableRows
    List col2 = cols;
    List durations = times;
    double depth = double.parse(depthController.text);
    double depthPlusInterval = depth + depthInterval;
    double depthMinusInterval = depth - depthInterval;

    //TODO: check if depth == 0, if so, table should show empty state
    List col1 = col2.map((e) => e / depth * depthMinusInterval).toList();
    List col3 = col2.map((e) => e / depth * depthPlusInterval).toList();

    int durationPlusInterval =
        int.parse(durationController.text) + durationInterval;

    List<double> resultsCol1 = [];
    List<double> resultsCol2 = [];
    List<double> resultsCol3 = [];
    List<Duration> resultDuration = [];

    for (int i = durationPlusInterval; i >= 0; i -= durationInterval) {
      int index = durations.indexWhere((element) {
        if ((element as Duration).inSeconds == i * 60) {
          return true;
        }
        return false;
      });

      resultDuration.add(durations[index]);
      resultsCol1.add(col1[index]);
      resultsCol2.add(col2[index]);
      resultsCol3.add(col3[index]);

      if (i == durationPlusInterval - durationInterval) {
        setState(() {
          result = col2[index];
        });
      }
    }

    List resultRows = [];
    for (int i = 0; i < resultDuration.length; i++) {
      var row = [
        PDIcon(
          icon: Icon(Icons.schedule),
          text: Text('${resultDuration[i].inMinutes}'),
        ),
        Text('${resultsCol1[i].toStringAsFixed(0)} mL'),
        (resultDuration[i].inMinutes == durationPlusInterval - durationInterval)
            ? Container(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
                color: Color(
                    0xFF006c50)), //TODO: manullay adjust light/dark theme here
          ),
          child: Text(
            '${resultsCol2[i].toStringAsFixed(0)} mL',
            style: TextStyle(
                color: Color(
                    0xFF006c50)), //TODO: manullay adjust light/dark theme here
          ),
        )
            : Text('${resultsCol2[i].toStringAsFixed(0)} mL'),
        Text('${resultsCol3[i].toStringAsFixed(0)} mL'),
      ];
      resultRows.add(row);
    }
    PDTableRows = resultRows;
  }

  void run({int cycle = 1}) {
    print({
      'model': (age??0) > 17
          ? adultModelController.selection
          : pediatricModelController.selection,
      'gender': genderController.val ? Gender.Female : Gender.Male,
      'age': ageController.text,
      'height': heightController.text,
      'weight': weightController.text,
      'depth': depthController.text,
      'duration': durationController.text,
    });

    //check whether depth is empty and numeric
    updatePDTableHeader();

    //check all other inputs

    var results;

    DateTime start = DateTime.now();

    for (int i = 0; i < cycle; i++) {
      PDSim.Simulation sim = PDSim.Simulation(
        model: (age??0) > 17
            ? adultModelController.selection
            : pediatricModelController.selection,
        weight: int.parse(weightController.text),
        height: int.parse(heightController.text),
        age: (age??0),
        gender: genderController.val ? Gender.Female : Gender.Male,
        refresh_rate: refreshRate,
      );

      results = sim.simulate(
          depth: double.parse(depthController.text),
          duration: (int.parse(durationController.text) + durationInterval),
          propofol_density: propofolDensity);

      // print(sim.variables);
    }

    DateTime finish = DateTime.now();

    Duration calculationDuration = finish.difference(start);
    // print({'duration': calculationDuration.toString()});

    updateRowsAndResult(
        cols: results['accumulated_volumes'], times: results['times']);
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
    genderController.val = true;
    ageController.text = 40.toString();
    heightController.text = 170.toString();
    weightController.text = 70.toString();
    depthController.text = 3.0.toString();
    durationController.text = 60.toString();

    age = int.tryParse(ageController.text);

    updateModelOptions(age??0);

    // updateModelOptions(int.parse(ageController.text));
    // adultModelController.selection = modelOptions.first;
    run();
  }

  void restart() {
    updateModelOptions(age??0);
    // updateModelOptions(int.parse(ageController.text));

    // if (!modelOptions.contains(adultModelController.selection)) {
    //   adultModelController.selection = modelOptions.first;
    // }
    //TODO check all controller's text before run
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

    // modelOptions.clear();
    // if (age >= Model.Paedfusor.minAge && age <= Model.Paedfusor.maxAge) {
    //   modelOptions.add(Model.Paedfusor);
    // }
    //
    // if (age >= Model.Kataria.minAge && age <= Model.Kataria.maxAge) {
    //   modelOptions.add(Model.Kataria);
    // }
    //
    // if (age >= Model.Marsh.minAge && age <= Model.Marsh.maxAge) {
    //   modelOptions.add(Model.Marsh);
    // }
    //
    // if (age >= Model.Schnider.minAge && age <= Model.Schnider.maxAge) {
    //   modelOptions.add(Model.Schnider);
    // }
    //
    // if (age >= Model.Eleveld.minAge && age <= Model.Eleveld.maxAge) {
    //   modelOptions.add(Model.Eleveld);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    age = int.tryParse(ageController.text);

    updateModelOptions(age??0);

    final bool heightTextFieldEnabled = age == null ? false : age! >= 17
        ? adultModelController.selection != Model.Marsh
        : pediatricModelController.selection == Model.Eleveld;

    final bool genderSwitchControlEnabled = age == null ? false : age! >= 17
        ? adultModelController.selection != Model.Marsh
        : pediatricModelController.selection == Model.Eleveld;


    // final bool heightTextFieldEnabled = int.parse(ageController.text) >= 17
    //     ? adultModelController.selection != Model.Marsh
    //     : pediatricModelController.selection == Model.Eleveld;
    // final bool genderSwitchControlEnabled = int.parse(ageController.text) >= 17
    //     ? adultModelController.selection != Model.Marsh
    //     : pediatricModelController.selection == Model.Eleveld;

    return Scaffold(
      body: SingleChildScrollView(
        physics: mediaQuery.viewInsets.bottom <= 0
            ? NeverScrollableScrollPhysics()
            : BouncingScrollPhysics(),
        child: Container(
          height: mediaQuery.size.height - 90,
          margin: EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(),
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
                            '${result.toStringAsFixed(0)} mL',
                            style: TextStyle(fontSize: 60),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                child: PDTable(
                  header: PDTableHeader,
                  rows: PDTableRows,
                  controller: tableController,
                  // onPressed: updatePDTableController,
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              Container(
                width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
                height: 59,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PDSegmentedControl(
                      options: modelOptions,
                      // int.parse(ageController.text) > 17
                      //     ? [Model.Marsh, Model.Schnider, Model.Eleveld]
                      //     : [Model.Paedfusor, Model.Kataria, Model.Eleveld],
                      segmentedController: (age??0) > 16
                          ? adultModelController
                          : pediatricModelController,
                      onPressed: run,
                      assertValue: (age??0),
                    ),
                    Container(
                        height: 59,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                          ),
                          onPressed: reset,
                          child: Icon(Icons.restart_alt_outlined),
                        )),
                  ],
                ),
              ),
              const SizedBox(
                height: 32,
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
                      icon: const Icon(Icons.airline_seat_flat),
                      // labelText: 'Depth in mcg/mL',
                      labelText: 'Depth (mcg/mL)',
                      helperText: '',
                      interval: 0.5,
                      fractionDigits: 1,
                      controller: depthController,
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
                      interval: 1.0,
                      fractionDigits: 0,
                      controller: durationController,
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
      bottomNavigationBar: BottomNavigationBar(items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined), label: 'Volume'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Duration'),
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
  const PDTable({
    Key? key,
    required this.header,
    required this.rows,
    required this.controller,
    // required this.onPressed,
  }) : super(key: key);

  final header;
  final rows;
  final PDTableController controller;

  // final Function onPressed;

  @override
  State<PDTable> createState() => _PDTableState();
}

class _PDTableState extends State<PDTable> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double headerColWidth =
    ((mediaQuery.size.width - horizontalSidesPaddingPixel * 2) /
        (widget.header.length + 1));
    final double rowColWidth =
    ((mediaQuery.size.width - horizontalSidesPaddingPixel * 2) /
        (widget.header.length + 1));

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
                      'Confidence\nInterval',
                      style: TextStyle(fontSize: 10),
                    ),
                    // IconButton(
                    //   onPressed: () =>
                    //       widget.onPressed(widget.controller),
                    //   icon: Icon(Icons.expand_more),
                    // ),
                  ),
                ),
                Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.header.length,
                    itemBuilder: (buildContext, buildIndex) {
                      return Container(
                        width: headerColWidth,
                        // alignment: buildIndex == 0
                        //     ? Alignment.centerLeft
                        //     : Alignment.center,
                        child: Align(
                          child: widget.header[buildIndex],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Theme
                .of(context)
                .colorScheme
                .primary,
          ),
          Container(
            height: (20 + PDTableRowHeight) * 3 - 19,
            child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.rows.length,
                itemBuilder: (buildContext, buildIndexOutter) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        height: PDTableRowHeight,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.rows[buildIndexOutter].length,
                            itemBuilder: (buildContext, buildIndexInner) {
                              return Container(
                                width: rowColWidth,
                                alignment: buildIndexInner == 0
                                    ? Alignment.centerLeft
                                    : Alignment.center,
                                child: widget.rows[buildIndexOutter]
                                [buildIndexInner],
                              );
                            }),
                      ),
                      Divider(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .primary,
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
  const PDSegmentedControl({Key? key,
    required this.options,
    required this.segmentedController,
    required this.onPressed,
    required this.assertValue})
      : super(key: key);

  final List options;
  final PDSegmentedController segmentedController;
  final Function onPressed;
  final int assertValue;

  @override
  State<PDSegmentedControl> createState() => _PDSegmentedControlState();
}

class _PDSegmentedControlState extends State<PDSegmentedControl> {
  @override
  void dispose() {
    widget.segmentedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: widget.options.length,
      itemBuilder: (buildContext, buildIndex) {
        return SizedBox(
          child: ElevatedButton(
            onPressed: widget.options[buildIndex].enabled &&
                widget.options[buildIndex].withinAge(widget.assertValue)
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
                  ? Theme
                  .of(context)
                  .colorScheme
                  .onPrimary
                  : Theme
                  .of(context)
                  .colorScheme
                  .primary,
              backgroundColor: widget.segmentedController.selection ==
                  widget.options[buildIndex]
                  ? Theme
                  .of(context)
                  .colorScheme
                  .primary
                  : Theme
                  .of(context)
                  .colorScheme
                  .onPrimary,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: widget.options[buildIndex].enabled &&
                        widget.options[buildIndex]
                            .withinAge(widget.assertValue)
                        ? Theme
                        .of(context)
                        .colorScheme
                        .primary
                        : Theme
                        .of(context)
                        .disabledColor),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(buildIndex == 0 ? 5 : 0),
                    bottomLeft: Radius.circular(buildIndex == 0 ? 5 : 0),
                    topRight: Radius.circular(
                        buildIndex == widget.options.length - 1 ? 5 : 0),
                    bottomRight: Radius.circular(
                        buildIndex == widget.options.length - 1 ? 5 : 0)),
              ),
            ),
            child: Text(
              widget.options[buildIndex].toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
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
    // this.onLongPressedStart,
    // this.onLongPressedEnd,
    this.timer,
    this.enabled = true,
  }) : super(key: key);

  final String labelText;
  final Icon icon;
  final String helperText;
  final double interval;
  final int fractionDigits;
  final TextEditingController controller;
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

  // void dismissKeyboard() {
  //   FocusScope.of(context).requestFocus(new FocusNode());
  // }

  @override
  Widget build(BuildContext context) {
    //this controls size of the plus & minus buttons
    double suffixIconConstraintsWidth = 70;
    double suffixIconConstraintsHeight = 59;

    bool isNumeric(String s) {
      if (s.isEmpty) {
        return false;
      }
      return double.tryParse(s) != null;
    }

    return TextField(
      onChanged: (val) {
        widget.onChanged();
      },
      enabled: widget.enabled,
      style: TextStyle(
          color: widget.enabled
              ? Theme
              .of(context)
              .colorScheme
              .primary
              : Theme
              .of(context)
              .disabledColor),
      scrollPadding: EdgeInsets.all(48.0),
      onSubmitted: (val) =>
          widget.onPressed(widget.controller, 0.0, widget.fractionDigits),
      controller: widget.controller,
      keyboardType: TextInputType.numberWithOptions(
          signed: true, decimal: widget.fractionDigits > 0 ? true : false),
      // keyboardType: TextInputType.numberWithOptions(
      //     signed: widget.fractionDigits > 0 ? true : false,
      //     decimal: widget.fractionDigits > 0 ? true : false),
      decoration: InputDecoration(
        errorText: widget.controller.text.isEmpty
            ? null
            : isNumeric(widget.controller.text)
            ? null
            : 'Please enter digits only',
        prefixIcon: widget.icon,
        prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
        helperText: widget.helperText,
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIconConstraints: widget.controller.text.isEmpty
            ? BoxConstraints.tight(Size.zero)
            : BoxConstraints.tight(
            Size(suffixIconConstraintsWidth, suffixIconConstraintsHeight)),
        suffixIcon: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.controller.text.isNotEmpty)

              Container(
                alignment: Alignment.center,
                width: suffixIconConstraintsWidth / 2,
                height: suffixIconConstraintsHeight,
                child: GestureDetector(
                  child: Icon(
                    Icons.remove,
                  ),
                  onTap: () {
                    double? prev = double.tryParse(widget.controller.text);
                    if (prev != null) {
                      prev -= widget.interval;
                      widget.controller.text =
                          prev!.toStringAsFixed(widget.fractionDigits);
                      widget.onPressed();
                    }
                  },
                  onLongPress: () {
                    widget.timer = Timer.periodic(widget.delay, (t) {
                      double? prev = double.tryParse(widget.controller.text);
                      if (prev != null) {
                        prev -= widget.interval;
                        widget.controller.text =
                            prev!.toStringAsFixed(widget.fractionDigits);
                      }
                    });
                  },
                  onLongPressEnd: (_) {
                    if (widget.timer != null) {
                      widget.timer!.cancel();
                      widget.onPressed();
                    }
                  },
                ),
              ),

            Container(
              alignment: Alignment.center,
              width: suffixIconConstraintsWidth / 2,
              height: suffixIconConstraintsHeight,
              child: GestureDetector(
                child: Icon(
                  Icons.add,
                ),
                onTap: () {
                  double? prev = double.tryParse(widget.controller.text);
                  if (prev != null) {
                    prev += widget.interval;
                    widget.controller.text =
                        prev!.toStringAsFixed(widget.fractionDigits);
                    widget.onPressed();
                  }
                },
                onLongPress: () {
                  widget.timer = Timer.periodic(widget.delay, (t) {
                    double? prev = double.tryParse(widget.controller.text);
                    if (prev != null) {
                      prev += widget.interval;
                      widget.controller.text =
                          prev!.toStringAsFixed(widget.fractionDigits);
                    }
                  });
                },
                onLongPressEnd: (_) {
                  if (widget.timer != null) {
                    widget.timer!.cancel();
                    widget.onPressed();
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
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

    return TextField(
      enabled: widget.enabled,
      readOnly: true,
      controller: textEditingController,
      style: TextStyle(
          color: widget.enabled
              ? Theme
              .of(context)
              .colorScheme
              .primary
              : Theme
              .of(context)
              .disabledColor),
      decoration: InputDecoration(
        prefixIcon: widget.icon,
        prefixIconConstraints: BoxConstraints.tight(const Size(36, 36)),
        helperText: widget.helperText,
        border: const OutlineInputBorder(),
        suffixIconConstraints: BoxConstraints.tight(const Size(60, 59)),
        suffixIcon: Switch(
          activeColor: widget.enabled
              ? Theme
              .of(context)
              .colorScheme
              .primary
              : Theme
              .of(context)
              .disabledColor,
          activeTrackColor:
          Theme
              .of(context)
              .colorScheme
              .primary
              .withOpacity(0.1),
          inactiveThumbColor: widget.enabled
              ? Theme
              .of(context)
              .colorScheme
              .primary
              : Theme
              .of(context)
              .disabledColor,
          inactiveTrackColor:
          Theme
              .of(context)
              .colorScheme
              .primary
              .withOpacity(0.1),
          value: widget.controller.val,
          onChanged: (val) {
            setState(() {
              widget.controller.val = val;
            });
            widget.onChanged();
          },
        ),
      ),
    );
  }
}
