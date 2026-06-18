import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../utils/intents.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/target.dart';

import '../config/design_tokens.dart';
import '../constants.dart';
import '../components/infusion_regime_table.dart';
import '../components/pk_field.dart';
import '../components/switch_field.dart';
import '../components/selector_row.dart';


class _VolumeScreenState extends State<VolumeScreen> {
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  Model _selectedModel = Model.Marsh;
  bool _sexValue = false; // false=Male, true=Female
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
      if (settings.volumeTableScrollPosition != null &&
          tableScrollController.hasClients) {
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
    _selectedModel = settings.inAdultView ? settings.adultModel : settings.pediatricModel;
    _sexValue = settings.inAdultView
        ? settings.adultSex == Sex.Female
        : settings.pediatricSex == Sex.Female;

    if (settings.inAdultView) {
      ageController.text = settings.adultAge?.toString() ?? '';
      heightController.text = settings.adultHeight?.toString() ?? '';
      weightController.text = settings.adultWeight?.toString() ?? '';
      targetController.text = settings.propofolTarget?.toStringAsFixed(1) ?? '';
      durationController.text = settings.adultDuration?.toString() ?? '';
    } else {
      ageController.text = settings.pediatricAge?.toString() ?? '';
      heightController.text = settings.pediatricHeight?.toString() ?? '';
      weightController.text = settings.pediatricWeight?.toString() ?? '';
      targetController.text =
          settings.pediatricTarget?.toStringAsFixed(1) ?? '';
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
      final timeString =
          '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}';
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
      final timeString =
          '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}';

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

  void run({initState = false, bool collapseInput = false}) {
    final settings = Provider.of<Settings>(context, listen: false);
    if (initState) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.statusBarInfo = null;
      });
    } else {
      settings.statusBarInfo = null;
    }

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    int? duration = int.tryParse(durationController.text);
    Sex sex = _sexValue ? Sex.Female : Sex.Male;

    if (initState == false) {
      if (settings.inAdultView) {
        settings.adultModel = _selectedModel;
        settings.adultSex = sex;
        settings.adultAge = age;
        settings.adultHeight = height;
        settings.adultWeight = weight;
        settings.propofolTarget = target;
        settings.adultDuration = duration;
      } else {
        settings.pediatricModel = _selectedModel;
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

              Patient patient =
                  Patient(weight: weight, age: age, height: height, sex: sex);

              Pump pump = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.propofol_concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target,
                  duration: Duration(minutes: duration));

              Pump pump1 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.propofol_concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target - targetInterval,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              Pump pump2 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.propofol_concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              Pump pump3 = Pump(
                  timeStep: Duration(seconds: settings.time_step),
                  concentration: settings.propofol_concentration,
                  maxPumpRate: settings.max_pump_rate,
                  target: target + targetInterval,
                  duration: Duration(minutes: duration + 2 * durationInterval));

              PDSim.Simulation sim1 =
                  PDSim.Simulation(model: model, patient: patient, pump: pump1);

              PDSim.Simulation sim2 =
                  PDSim.Simulation(model: model, patient: patient, pump: pump2);

              PDSim.Simulation sim3 =
                  PDSim.Simulation(model: model, patient: patient, pump: pump3);

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
                'drug_unit':
                    '${propofolDrug.concentration.toStringAsFixed(propofolDrug.concentration == propofolDrug.concentration.roundToDouble() ? 0 : 1)} ${propofolDrug.concentrationUnit.displayName}',
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
              final statusInfo =
                  'Pump: ${pump.maxPumpRate} mL/hr · Duration: ${pump.duration.inMinutes}min';
              if (initState) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) settings.statusBarInfo = statusInfo;
                });
              } else {
                settings.statusBarInfo = statusInfo;
              }
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
      _sexValue = toDefault
          ? true
          : settings.adultSex == Sex.Female;
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
          ? 3.0.toStringAsFixed(1)
          : settings.propofolTarget != null
              ? settings.propofolTarget!.toStringAsFixed(1)
              : '';
      durationController.text = toDefault
          ? 60.toString()
          : settings.adultDuration != null
              ? settings.adultDuration.toString()
              : '';
    } else {
      _sexValue = toDefault
          ? true
          : settings.pediatricSex == Sex.Female;
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
          ? 3.0.toStringAsFixed(1)
          : settings.pediatricTarget != null
              ? settings.pediatricTarget!.toStringAsFixed(1)
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

  void _handleAgeChange() {
    final settings = Provider.of<Settings>(context, listen: false);
    final age = int.tryParse(ageController.text);
    if (age != null && age >= 1) {
      if (age >= 17 != settings.inAdultView) {
        if (settings.inAdultView) {
          settings.pediatricAge = age;
        } else {
          settings.adultAge = age;
        }
        settings.inAdultView = age >= 17;
        if (age < 17) {
          _selectedModel = settings.pediatricModel;
        } else {
          _selectedModel = settings.adultModel;
        }
      }
    }
    updateModelOptions(settings.inAdultView);
    run();
  }

  List<String> _validate(Settings settings) {
    final errors = <String>[];
    final age = int.tryParse(ageController.text);
    final height = int.tryParse(heightController.text);
    final weight = int.tryParse(weightController.text);
    final duration = int.tryParse(durationController.text);

    final model = settings.inAdultView
        ? settings.adultModel
        : settings.pediatricModel;

    if (model == Model.None) {
      errors.add('No model selected');
      return errors;
    }

    final bool hasNulls = age == null || weight == null || duration == null;
    final bool targetNull =
        double.tryParse(targetController.text) == null;
    final bool hasMissingFields = hasNulls || targetNull ||
        (model.target != Target.Plasma && height == null);

    if (hasMissingFields) {
      errors.add('Fill in all required fields');
    }

    if (age != null && !model.withinAge(age)) {
      errors.add('Age ${model.minAge}-${model.maxAge} for ${model.name}');
    }
    if (weight != null && !model.withinWeight(weight)) {
      errors.add('Weight ${model.minWeight}-${model.maxWeight} kg for ${model.name}');
    }
    if (height != null && !model.withinHeight(height)) {
      errors.add('Height ${model.minHeight}-${model.maxHeight} cm for ${model.name}');
    }

    return errors;
  }

  Widget _buildErrorPanel(List<String> errors) {
    return SizedBox(
      height: 48,
      child: errors.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errors.first,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  if (errors.length > 1)
                    Text(
                      '+${errors.length - 1} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputFields(Settings settings) {
    final theme = Theme.of(context);
    final age = int.tryParse(ageController.text);
    final model = settings.inAdultView ? settings.adultModel : settings.pediatricModel;
    final errors = _validate(settings);
    final sexSwitchEnabled = model.target != Target.Plasma;
    final heightEnabled = model.target != Target.Plasma;
    final ageEnabled = !(settings.inAdultView && model == Model.Marsh);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildErrorPanel(errors),
        const SizedBox(height: kSp12),
        // Model selector, adult/paed toggle, and reset button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectorRow(
                          selectedModel: _selectedModel,
                          models: modelOptions,
                          onModelSelected: (m) {
                            setState(() {
                              _selectedModel = m;
                              if (settings.inAdultView) {
                                settings.adultModel = m;
                              } else {
                                settings.pediatricModel = m;
                              }
                            });
                            run();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(kRadius),
                        ),
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              settings.inAdultView ? Icons.face : Icons.child_care_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              settings.inAdultView
                                  ? AppLocalizations.of(context)!.adult
                                  : AppLocalizations.of(context)!.paed,
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(width: 2),
                            Switch(
                              value: settings.inAdultView,
                              activeThumbColor: theme.colorScheme.primary,
                              activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
                              inactiveTrackColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                              onChanged: (v) {
                                HapticFeedback.lightImpact();
                                if (v != settings.inAdultView) {
                                  if (settings.inAdultView) {
                                    settings.adultAge = int.tryParse(ageController.text);
                                    settings.adultHeight = int.tryParse(heightController.text);
                                    settings.adultWeight = int.tryParse(weightController.text);
                                    settings.propofolTarget = double.tryParse(targetController.text);
                                    settings.adultDuration = int.tryParse(durationController.text);
                                    settings.adultSex = _sexValue ? Sex.Female : Sex.Male;
                                  } else {
                                    settings.pediatricAge = int.tryParse(ageController.text);
                                    settings.pediatricHeight = int.tryParse(heightController.text);
                                    settings.pediatricWeight = int.tryParse(weightController.text);
                                    settings.pediatricTarget = double.tryParse(targetController.text);
                                    settings.pediatricDuration = int.tryParse(durationController.text);
                                    settings.pediatricSex = _sexValue ? Sex.Female : Sex.Male;
                                  }
                                  settings.inAdultView = v;
                                  ageController.text = settings.inAdultView
                                      ? (settings.adultAge?.toString() ?? '')
                                      : (settings.pediatricAge?.toString() ?? '');
                                  heightController.text = settings.inAdultView
                                      ? (settings.adultHeight?.toString() ?? '')
                                      : (settings.pediatricHeight?.toString() ?? '');
                                  weightController.text = settings.inAdultView
                                      ? (settings.adultWeight?.toString() ?? '')
                                      : (settings.pediatricWeight?.toString() ?? '');
                                  targetController.text = settings.inAdultView
                                      ? (settings.propofolTarget?.toStringAsFixed(1) ?? '')
                                      : (settings.pediatricTarget?.toStringAsFixed(1) ?? '');
                                  durationController.text = settings.inAdultView
                                      ? (settings.adultDuration?.toString() ?? '')
                                      : (settings.pediatricDuration?.toString() ?? '');
                                  _sexValue = settings.inAdultView
                                      ? settings.adultSex == Sex.Female
                                      : settings.pediatricSex == Sex.Female;
                                  _selectedModel = settings.inAdultView
                                      ? settings.adultModel
                                      : settings.pediatricModel;
                                  updateModelOptions(settings.inAdultView);
                                  run();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    reset(toDefault: true);
                  },
                  child: const Icon(Icons.restart_alt_outlined),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Sex and Age row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: SwitchField(
                  labelText: AppLocalizations.of(context)!.sex,
                  prefixIcon: _sexValue
                      ? (settings.inAdultView ? Icons.woman : Icons.girl)
                      : (settings.inAdultView ? Icons.man : Icons.boy),
                  value: _sexValue,
                  switchLabels: {
                    true: settings.inAdultView
                        ? Sex.Female.toLocalizedString(context)
                        : Sex.Girl.toLocalizedString(context),
                    false: settings.inAdultView
                        ? Sex.Male.toLocalizedString(context)
                        : Sex.Boy.toLocalizedString(context),
                  },
                  onChanged: (v) {
                    setState(() => _sexValue = v);
                    if (settings.inAdultView) {
                      settings.adultSex = v ? Sex.Female : Sex.Male;
                    } else {
                      settings.pediatricSex = v ? Sex.Female : Sex.Male;
                    }
                    run();
                  },
                  enabled: sexSwitchEnabled,
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: PKField(
                  labelText: AppLocalizations.of(context)!.age,
                  prefixIcon: Icons.calendar_month,
                  interval: 1.0,
                  fractionDigits: 0,
                  controller: ageController,
                  range: age != null
                      ? (age >= 17
                          ? [17, model == Model.Schnider ? 100 : 105]
                          : [1, 16])
                      : [1, 16],
                  onChanged: _handleAgeChange,
                  enabled: ageEnabled,
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Height and Weight row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: PKField(
                  labelText: '${AppLocalizations.of(context)!.height} (cm)',
                  prefixIcon: Icons.straighten,
                  interval: 1,
                  fractionDigits: 0,
                  controller: heightController,
                  range: [model.minHeight, model.maxHeight],
                  onChanged: () {
                    final s = Provider.of<Settings>(context, listen: false);
                    if (settings.inAdultView) {
                      s.adultHeight = int.tryParse(heightController.text);
                    } else {
                      s.pediatricHeight = int.tryParse(heightController.text);
                    }
                    run();
                  },
                  enabled: heightEnabled,
                  hasError: errors.isNotEmpty,
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: PKField(
                  labelText: '${AppLocalizations.of(context)!.weight} (kg)',
                  prefixIcon: Icons.monitor_weight_outlined,
                  interval: 1.0,
                  fractionDigits: 0,
                  controller: weightController,
                  range: [model.minWeight, model.maxWeight],
                  onChanged: () {
                    final s = Provider.of<Settings>(context, listen: false);
                    if (settings.inAdultView) {
                      s.adultWeight = int.tryParse(weightController.text);
                    } else {
                      s.pediatricWeight = int.tryParse(weightController.text);
                    }
                    run();
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Target and Duration row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: PKField(
                  labelText: model.target.toLocalizedString(context),
                  prefixIcon: model.target.icon,
                  interval: 0.5,
                  fractionDigits: 1,
                  controller: targetController,
                  range: const [kMinTarget, kMaxTarget],
                  onChanged: () {
                    final s = Provider.of<Settings>(context, listen: false);
                    final t = double.tryParse(targetController.text);
                    if (settings.inAdultView) {
                      s.propofolTarget = t;
                    } else {
                      s.pediatricTarget = t;
                    }
                    run();
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: PKField(
                  labelText: AppLocalizations.of(context)!.duration,
                  prefixIcon: Icons.schedule,
                  interval: 5,
                  fractionDigits: 0,
                  controller: durationController,
                  range: const [kMinDuration, kMaxDuration],
                  onChanged: () {
                    final d = int.tryParse(durationController.text);
                    final s = Provider.of<Settings>(context, listen: false);
                    if (settings.inAdultView) {
                      s.adultDuration = d;
                    } else {
                      s.pediatricDuration = d;
                    }
                    run();
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
      ],
    );
  }

  Widget _buildInputPanel(Settings settings) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: _buildInputFields(settings),
    );
  }

  List<ConfidenceIntervalRowData> _buildConfidenceIntervalData(
      bool modelIsRunnable) {
    final rows = modelIsRunnable ? PDTableRows : EmptyTableRows;
    return rows.map<ConfidenceIntervalRowData>((row) {
      final List<String> rowData = row.cast<String>();
      return ConfidenceIntervalRowData(
        rowData,
        highlightValue: result.contains(rowData.length > 2 ? rowData[2] : '')
            ? rowData[2]
            : null,
      );
    }).toList();
  }

  int _calculateOptimalRowCount(double screenHeight, bool isTableExpanded) {
    if (screenHeight < 600) {
      return 3;
    } else if (screenHeight < 800) {
      return 4;
    } else if (screenHeight < 1000) {
      return 5;
    } else {
      return 6;
    }
  }

  /// Results section: data table only (result label is pinned below).
  Widget _buildResultsSection(Settings settings, double screenHeight,
      double? target, bool modelIsRunnable, {bool showTable = true}) {
    final mediaQuery = MediaQuery.of(context);
    return Column(
      children: [
        // Data table
        if (showTable)
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
                            'Target ${(target + targetInterval).toStringAsFixed(1)}',
                          ]
                        : ['Target --', 'Target --', 'Target --'],
                    maxVisibleRows: tableController.val
                        ? _calculateOptimalRowCount(screenHeight, true)
                        : 0,
                    selectedRowIndex: settings.selectedVolumeTableRow,
                    onRowTap: (index) {
                      if (settings.selectedVolumeTableRow == index) {
                        settings.selectedVolumeTableRow = null;
                      } else {
                        settings.selectedVolumeTableRow = index;
                      }
                    },
                    scrollController: tableScrollController,
                    animate: _shouldAnimateTableExpansion,
                  );
                },
              )
            : const SizedBox(height: 0),
      ],
    );
  }

  Widget _buildDesktopResults(Settings settings, double screenHeight,
      double? target, bool modelIsRunnable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            modelIsRunnable ? result : emptyResult,
            style: TextStyle(
              fontSize: 60,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<Settings>(
            builder: (context, settings, child) {
              return AnimatedDataTable(
                isExpanded: true,
                data: _buildConfidenceIntervalData(modelIsRunnable),
                headers: modelIsRunnable
                    ? [
                        (target! - targetInterval) >= 0
                            ? 'Target ${(target - targetInterval).toStringAsFixed(1)}'
                            : 'Target ${0.toStringAsFixed(1)}',
                        'Target ${target.toStringAsFixed(1)}',
                        'Target ${(target + targetInterval).toStringAsFixed(1)}',
                      ]
                    : ['Target --', 'Target --', 'Target --'],
                maxVisibleRows: 100,
                selectedRowIndex: settings.selectedVolumeTableRow,
                onRowTap: (index) {
                  if (settings.selectedVolumeTableRow == index) {
                    settings.selectedVolumeTableRow = null;
                  } else {
                    settings.selectedVolumeTableRow = index;
                  }
                },
                scrollController: tableScrollController,
                animate: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(Settings settings, double UIHeight,
      double screenHeight, double? target, bool modelIsRunnable) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: horizontalSidesPaddingPixel,
          right: horizontalSidesPaddingPixel,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildDesktopResults(
                  settings, screenHeight, target, modelIsRunnable),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 393,
              child: _buildInputPanel(settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Settings settings, double UIHeight,
      double screenHeight, double? target, bool modelIsRunnable) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: horizontalSidesPaddingPixel,
          right: horizontalSidesPaddingPixel,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildDesktopResults(
                  settings, screenHeight, target, modelIsRunnable),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 393,
              child: _buildInputPanel(settings),
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps [child] in [Shortcuts] + [Actions] for Enter=run() on desktop/web.
  Widget _wrapWithKeyboardShortcuts(Widget child) {
    final enable = ResponsiveHelper.isDesktop(context) || kIsWeb;
    if (!enable) return child;
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): CalculateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          CalculateIntent: CallbackAction<CalculateIntent>(
            onInvoke: (intent) {
              run();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = ResponsiveHelper.isDesktop(context);
    final isTabletLayout =
        ResponsiveHelper.isTablet(context) && !isDesktopLayout;

    final mediaQuery = MediaQuery.of(context);
    final double UIHeight = (mediaQuery.size.aspectRatio >= 0.455
            ? mediaQuery.size.height >= screenBreakPoint1
                ? 56
                : 48
            : 48) +
        (ResponsiveHelper.isAndroid() ? 4 : 0);

    final double screenHeight = mediaQuery.size.height -
        (ResponsiveHelper.isAndroid()
            ? 48
            : mediaQuery.size.height >= screenBreakPoint1
                ? 88
                : 56);

    final settings = context.watch<Settings>();

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    int? duration = int.tryParse(durationController.text);
    double? target = double.tryParse(targetController.text);

    _selectedModel = settings.inAdultView ? settings.adultModel : settings.pediatricModel;

    bool modelIsRunnable = _selectedModel.isRunnable(
        age: age,
        height: height,
        weight: weight,
        target: target,
        duration: duration);

    if (isDesktopLayout) {
      return _wrapWithKeyboardShortcuts(
        _buildDesktopLayout(
            settings, UIHeight, screenHeight, target, modelIsRunnable),
      );
    }
    if (isTabletLayout) {
      return _wrapWithKeyboardShortcuts(
        _buildTabletLayout(
            settings, UIHeight, screenHeight, target, modelIsRunnable),
      );
    }

    // Mobile: fixed-bottom input panel with scrollable results above
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _wrapWithKeyboardShortcuts(
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: horizontalSidesPaddingPixel,
                      right: horizontalSidesPaddingPixel,
                      top: 12,
                    ),
                    child: _buildResultsSection(
                        settings, screenHeight, target, modelIsRunnable, showTable: false),
                  );
                },
              ),
            ),
            // Result label + arrow pinned just above input panel
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await HapticFeedback.mediumImpact();
                          updatePDTableController(tableController);
                        },
                        icon: tableController.val
                            ? const Icon(Icons.expand_more)
                            : const Icon(Icons.expand_less),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.fastOutSlowIn,
                        style: TextStyle(
                          fontSize: tableController.val ? 34 : 60,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        child: Text(modelIsRunnable ? result : emptyResult),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Data table (expands between result label and input panel)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              alignment: Alignment.topCenter,
              child: tableController.val && mediaQuery.size.height >= screenBreakPoint1
                  ? Consumer<Settings>(
                      builder: (context, settings, child) {
                        return AnimatedDataTable(
                          isExpanded: true,
                          data: _buildConfidenceIntervalData(modelIsRunnable),
                          headers: modelIsRunnable
                              ? [
                                  (target! - targetInterval) >= 0
                                      ? 'Target ${(target - targetInterval).toStringAsFixed(1)}'
                                      : 'Target ${0.toStringAsFixed(1)}',
                                  'Target ${target.toStringAsFixed(1)}',
                                  'Target ${(target + targetInterval).toStringAsFixed(1)}',
                                ]
                              : ['Target --', 'Target --', 'Target --'],
                          maxVisibleRows: _calculateOptimalRowCount(screenHeight, true),
                          selectedRowIndex: settings.selectedVolumeTableRow,
                          onRowTap: (index) {
                            if (settings.selectedVolumeTableRow == index) {
                              settings.selectedVolumeTableRow = null;
                            } else {
                              settings.selectedVolumeTableRow = index;
                            }
                          },
                          scrollController: tableScrollController,
                          animate: _shouldAnimateTableExpansion,
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              child: SafeArea(
                top: false,
                child: _buildInputPanel(settings),
              ),
            ),
          ],
        ),
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
