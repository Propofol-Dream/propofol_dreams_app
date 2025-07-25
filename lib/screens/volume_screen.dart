import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/target.dart';

import '../constants.dart';
import '../components/infusion_regime_table.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchController.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchField.dart';
import 'package:propofol_dreams_app/controllers/PDAdvancedSegmentedController.dart';
import 'package:propofol_dreams_app/controllers/PDAdvancedSegmentedControl.dart';


class _VolumeScreenState extends State<VolumeScreen> {
  final PDAdvancedSegmentedController adultModelController =
      PDAdvancedSegmentedController();
  final PDAdvancedSegmentedController pediatricModelController =
      PDAdvancedSegmentedController();
  PDSwitchController sexController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  final PDTableController tableController = PDTableController();
  final ScrollController scrollController = ScrollController();
  final ScrollController tableScrollController = ScrollController();
  final List<Model> modelOptions = [];
  Timer timer = Timer(Duration.zero, () {});
  Duration delay = const Duration(milliseconds: 500);
  bool _shouldAnimateTableExpansion = false;

  double targetInterval = 0.5;
  int durationInterval = 10; //in mins

  String result = '   mL';
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
    super.initState();
    
    // Settings are already loaded - initialize controllers with final values
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
    
    // Restore table scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (settings.volumeTableScrollPosition != null && tableScrollController.hasClients) {
        tableScrollController.jumpTo(settings.volumeTableScrollPosition!);
      }
    });
    
    // Add scroll listener to save position
    tableScrollController.addListener(() {
      if (tableScrollController.hasClients) {
        final settings = context.read<Settings>();
        settings.volumeTableScrollPosition = tableScrollController.offset;
      }
    });
    
    updateModelOptions(settings.inAdultView);
    run(initState: true);
  }

  void _setControllersFromSettings(Settings settings) {
    tableController.val = settings.isVolumeTableExpanded;

    if (settings.inAdultView) {
      adultModelController.selection = settings.adultModel;
      sexController.val = settings.adultSex == Sex.Female ? true : false;
      ageController.text = settings.adultAge?.toString() ?? '';
      heightController.text = settings.adultHeight?.toString() ?? '';
      weightController.text = settings.adultWeight?.toString() ?? '';
      targetController.text = settings.adultTarget?.toString() ?? '';
      durationController.text = settings.adultDuration?.toString() ?? '';
    } else {
      pediatricModelController.selection = settings.pediatricModel;
      sexController.val = settings.pediatricSex == Sex.Female ? true : false;
      ageController.text = settings.pediatricAge?.toString() ?? '';
      heightController.text = settings.pediatricHeight?.toString() ?? '';
      weightController.text = settings.pediatricWeight?.toString() ?? '';
      targetController.text = settings.pediatricTarget?.toString() ?? '';
      durationController.text = settings.pediatricDuration?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    tableScrollController.dispose();
    super.dispose();
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

      // Format time like infusion regime table: H:MM
      final duration = durations[index] as Duration;
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final timeString = '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}';
      resultDuration.add(timeString);
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

      // Format time like infusion regime table: H:MM
      final duration = durations[index] as Duration;
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final timeString = '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}';
      
      if (!resultDuration.contains(timeString)) {
        resultDuration.add(timeString);
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
    Sex sex = sexController.val ? Sex.Female : Sex.Male;

    if (initState == false) {
      if (settings.inAdultView) {
        settings.adultModel = adultModelController.selection;
        settings.adultSex = sex;
        settings.adultAge = age;
        settings.adultHeight = height;
        settings.adultWeight = weight;
        settings.adultTarget = target;
        settings.adultDuration = duration;
      } else {
        settings.pediatricModel = pediatricModelController.selection;
        settings.pediatricSex = sex;
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
                sex: sex)['assertion'] as bool) {
              // print('model pass constraints');

              DateTime start = DateTime.now();

              Patient patient = Patient(
                  weight: weight, age: age, height: height, sex: sex);

              Pump pump = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target,
                  duration: Duration(minutes: duration));

              Pump pump1 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target - targetInterval,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              Pump pump2 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              Pump pump3 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target + targetInterval,
                  duration: Duration(minutes: duration + 2 * durationInterval));

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

              // Get current propofol drug for display
              final propofolDrug = settings.getCurrentDrugVariant('Propofol');
              
              print({
                'screen': 'Volume',
                'model': model,
                'drug': propofolDrug.displayName,
                'drug_unit': '${propofolDrug.concentration.toStringAsFixed(propofolDrug.concentration == propofolDrug.concentration.roundToDouble() ? 0 : 1)} ${propofolDrug.concentrationUnit.displayName}',
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
      _shouldAnimateTableExpansion = true; // Enable animation for button tap
      controller.val = settings.isVolumeTableExpanded;
    });
    
    // Reset animation flag after a short delay to ensure it's used for this update only
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _shouldAnimateTableExpansion = false;
        });
      }
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
      sexController.val = toDefault
          ? true
          : settings.adultSex == Sex.Female
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
      sexController.val = toDefault
          ? true
          : settings.pediatricSex == Sex.Female
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

  List<ConfidenceIntervalRowData> _buildConfidenceIntervalData(bool modelIsRunnable) {
    final rows = modelIsRunnable ? PDTableRows : EmptyTableRows;
    return rows.map<ConfidenceIntervalRowData>((row) {
      final List<String> rowData = row.cast<String>();
      return ConfidenceIntervalRowData(
        rowData, 
        highlightValue: result.contains(rowData.length > 2 ? rowData[2] : '') ? rowData[2] : null,
      );
    }).toList();
  }

  int _calculateOptimalRowCount(double screenHeight, bool isTableExpanded) {
    // Be more conservative to prevent overflow
    if (screenHeight < 600) {
      return 3; // Small screens - keep it safe
    } else if (screenHeight < 800) {
      return 4; // Medium screens
    } else if (screenHeight < 1000) {
      return 5; // Large screens
    } else {
      return 6; // Very large screens
    }
  }

  Widget buildModelSelector(Settings settings, double UIHeight) {
    final currentModel = settings.inAdultView
        ? (adultModelController.selection is Model ? adultModelController.selection as Model : null)
        : (pediatricModelController.selection is Model ? pediatricModelController.selection as Model : null);
    
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;

    final hasValidationError = currentModel != null && 
        (settings.inAdultView ? adultModelController : pediatricModelController)
        .hasValidationError(sex: sex, weight: weight, height: height, age: age);

    final String? validationErrorText = hasValidationError
        ? (settings.inAdultView ? adultModelController : pediatricModelController)
            .getValidationErrorText(sex: sex, weight: weight, height: height, age: age)
        : null;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            enabled: true,
            readOnly: true,
            controller: TextEditingController(text: currentModel?.name ?? 'Select Model'),
            style: TextStyle(
              color: hasValidationError 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.onPrimary,
              helperText: '', // Reserve space to prevent layout shift
              helperStyle: const TextStyle(fontSize: 10),
              errorText: hasValidationError ? validationErrorText : null,
              errorStyle: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 10,
              ),
              prefixIcon: Icon(
                Symbols.graph_4,
                color: hasValidationError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
              labelText: AppLocalizations.of(context)!.model,
              labelStyle: TextStyle(
                color: hasValidationError 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: hasValidationError 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: hasValidationError 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () async {
                await HapticFeedback.lightImpact();
                final controller = settings.inAdultView ? adultModelController : pediatricModelController;
                controller.showModelSelector(
                  context: context,
                  inAdultView: settings.inAdultView,
                  sexController: sexController,
                  ageController: ageController,
                  heightController: heightController,
                  weightController: weightController,
                  targetController: targetController,
                  durationController: durationController,
                  onModelSelected: (model) {
                    setState(() {
                      if (settings.inAdultView) {
                        adultModelController.selection = model;
                        settings.adultModel = model;
                      } else {
                        pediatricModelController.selection = model;
                        settings.pediatricModel = model;
                      }
                    });
                    controller.selection = model;
                    updatePDSegmentedController(model);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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

    double density = settings.concentration;

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

    final bool sexSwitchControlEnabled = settings.inAdultView
        ? (adultModelController.selection as Model).target != Target.Plasma
        : (pediatricModelController.selection as Model).target != Target.Plasma;

    final ageTextFieldEnabled = !(settings.inAdultView &&
        adultModelController.selection == Model.Marsh);

    return Container(
      height: screenHeight,
      margin: const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
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
                            ? Icon(
                                Icons.face,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : Icon(
                                Icons.child_care_outlined,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        label: Text(
                          settings.inAdultView ? AppLocalizations.of(context)!.adult : AppLocalizations.of(context)!.paed,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
                                ? const Icon(Icons.expand_more)
                                : const Icon(Icons.expand_less))
                        : Container(),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.fastOutSlowIn,
                      style: TextStyle(
                        fontSize: tableController.val ? 34 : 60,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      child: Text(
                        modelIsRunnable ? result : emptyResult,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          mediaQuery.size.height >= screenBreakPoint1
              ? Consumer<Settings>(
                  builder: (context, settings, child) {
                    return AnimatedDataTable(
                      isExpanded: tableController.val,
                      data: _buildConfidenceIntervalData(modelIsRunnable),
                      headers: modelIsRunnable
                          ? [
                              (target! - targetInterval) >= 0
                                  ? 'Target ${(target - targetInterval).toStringAsFixed(1)}'
                                  : 'Target ${0.toStringAsFixed(1)}',
                              'Target ${target.toStringAsFixed(1)}',
                              'Target ${(target + targetInterval).toStringAsFixed(1)}'
                            ]
                          : ['Target --', 'Target --', 'Target --'],
                      maxVisibleRows: tableController.val ? _calculateOptimalRowCount(screenHeight, true) : 0,
                      selectedRowIndex: settings.selectedVolumeTableRow,
                       onRowTap: (index) {
                         // Toggle selection: if same row is tapped, deselect it
                         if (settings.selectedVolumeTableRow == index) {
                           settings.selectedVolumeTableRow = null;
                         } else {
                           settings.selectedVolumeTableRow = index;
                         }
                        },
                        scrollController: tableScrollController,
                        animate: _shouldAnimateTableExpansion,
                      );                  },
                )
              : const SizedBox(
                  height: 0,
                ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildModelSelector(settings, UIHeight),
                SizedBox(
                    height: UIHeight,
                    width: UIHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(0),
                        backgroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              // strokeAlign: StrokeAlign.outside, //depreicated in flutter 3.7
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(5))),
                      ),
                      onPressed: () async {
                        await HapticFeedback.mediumImpact();
                        reset(toDefault: true);
                      },
                      child: const Icon(Icons.restart_alt_outlined),
                    )),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          SizedBox(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: UIWidth,
                  child: PDSwitchField(
                    labelText: AppLocalizations.of(context)!.sex,
                    prefixIcon: sexController.val == true ?
                    settings.inAdultView ? Icons.woman : Icons.girl :
                    settings.inAdultView ? Icons.man : Icons.boy,
                    controller: sexController,
                    switchTexts: {
                      true: settings.inAdultView ? Sex.Female.toLocalizedString(context): Sex.Girl.toLocalizedString(context),
                      false: settings.inAdultView ? Sex.Male.toLocalizedString(context): Sex.Boy.toLocalizedString(context)
                    },
                    // helperText: '',
                    onChanged: run,
                    height: UIHeight,
                    enabled: sexSwitchControlEnabled,
                  ),
                ),
                const SizedBox(
                  width: 8,
                  height: 0,
                ),
                SizedBox(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.calendar_month,
                    labelText: AppLocalizations.of(context)!.age,
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
          SizedBox(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.straighten,
                    labelText: '${AppLocalizations.of(context)!.height} (cm)',
                    // helperText: '',
                    interval: 1,
                    fractionDigits: 0,
                    controller: heightController,
                    range: [selectedModel.minHeight, selectedModel.maxHeight],
                    onPressed: updatePDTextEditingController,
                    enabled: heightTextFieldEnabled,
                  ),
                ),
                const SizedBox(
                  width: 8,
                  height: 0,
                ),
                SizedBox(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.monitor_weight_outlined,
                    labelText: '${AppLocalizations.of(context)!.weight} (kg)',
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
          SizedBox(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText: selectedModel.target.toLocalizedString(context),
                    // helperText: '',
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: targetController,
                    range: const [kMinTarget, kMaxTarget],
                    onPressed: updatePDTextEditingController,
                    // onChanged: restart,
                  ),
                ),
                const SizedBox(
                  width: 8,
                  height: 0,
                ),
                SizedBox(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.schedule,
                    // labelText: 'Duration in minutes',
                    labelText: '${AppLocalizations.of(context)!.duration} (${AppLocalizations.of(context)!.min})',
                    // helperText: '',
                    interval: double.tryParse(durationController.text) != null
                        ? double.parse(durationController.text) >= 60
                            ? 10
                            : 5
                        : 1,
                    fractionDigits: 0,
                    controller: durationController,
                    range: const [kMinDuration, kMaxDuration],
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

class VolumeScreen extends StatefulWidget {
  const VolumeScreen({super.key});

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class PDTableController extends ChangeNotifier {
  PDTableController();

  bool _val = true;

  bool get val {
    return _val;
  }

  set val(bool v) {
    _val = v;
    notifyListeners();
  }
}






