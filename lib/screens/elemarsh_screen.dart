import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:propofol_dreams_app/models/calculator.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:provider/provider.dart' hide Selector;
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../utils/intents.dart';

import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/target.dart';
import 'package:propofol_dreams_app/models/sex.dart';

import 'package:propofol_dreams_app/components/pk_field.dart';
import 'package:propofol_dreams_app/components/switch_field.dart';
import 'package:propofol_dreams_app/components/collapsible_input_section.dart';

import '../constants.dart';
import 'package:propofol_dreams_app/config/design_tokens.dart';

class EleMarshScreen extends StatefulWidget {
  EleMarshScreen({Key? key}) : super(key: key);

  @override
  State<EleMarshScreen> createState() => _EleMarshScreenState();
}

class _EleMarshScreenState extends State<EleMarshScreen> {
  bool _sexValue = false;
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();

  bool _isWakeFlow = false;
  bool _isEleveldModel = false;
  TextEditingController maintenanceCeController = TextEditingController();
  TextEditingController maintenanceSEController = TextEditingController();
  TextEditingController infusionRateController = TextEditingController();

  Timer _debounceTimer = Timer(Duration.zero, () {});
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  //Displays
  String weightBestGuess = "--";
  String adjustmentBolus = "--";
  String inductionCPTarget = "--";
  String manualBolus = "--";
  String BMI = "--";
  String predictedBIS = "--";
  String range = "--";
  String vial20mlTime = "--";
  String vial50mlTime = "--";

  /// True when the maintenance SE is outside the validated 21-60 range.
  /// Used by the help text and the wake-up range display colouring.
  /// (L3 migration: was a local variable in the old monolithic build method.)
  bool get isMaintenanceSEOutOfRange {
    final settings = context.read<Settings>();
    final se = settings.EMMaintenanceSE ?? 40;
    return !(se >= 21 && se <= 60);
  }

  @override
  void initState() {
    super.initState();
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
  }

  @override
  void dispose() {
    _debounceTimer.cancel();
    super.dispose();
  }

  void _setControllersFromSettings(Settings settings) {
    _sexValue = settings.EMSex == Sex.Female;
    ageController.text = settings.EMAge?.toString() ?? '40';
    heightController.text = settings.EMHeight?.toString() ?? '170';
    weightController.text = settings.EMWeight?.toString() ?? '70';
    targetController.text = settings.EMTarget?.toString() ?? '3.0';

    _isWakeFlow = settings.EMFlow == 'wake';
    _isEleveldModel = settings.EMWakeUpModel == Model.Eleveld;
    maintenanceCeController.text = settings.EMMaintenanceCe?.toString() ?? '3.0';
    maintenanceSEController.text = settings.EMMaintenanceSE?.toString() ?? '40';
    infusionRateController.text = settings.EMInfusionRate?.toString() ?? '';
    run(initState: true);
  }

  void updatePDTextEditingController() {
    run();
  }

  run({initState = false, bool collapseInput = false}) async {
    final settings = Provider.of<Settings>(context, listen: false);

    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    Sex sex = _sexValue ? Sex.Female : Sex.Male;

    String flow = _isWakeFlow ? 'wake' : 'induce';
    Model m = _isEleveldModel ? Model.Eleveld : Model.EleMarsh;
    double? maintenanceCe = double.tryParse(maintenanceCeController.text);
    int? maintenanceSE = int.tryParse(maintenanceSEController.text);

    //Save all the settings
    if (initState == false) {
      settings.EMSex = sex;
      settings.EMAge = age;
      settings.EMHeight = height;
      settings.EMWeight = weight;
      settings.EMTarget = target;
      settings.EMFlow = flow;
      settings.EMWakeUpModel = m;
      settings.EMMaintenanceCe = maintenanceCe;
      settings.EMMaintenanceSE = maintenanceSE;
    }

    if (age != null &&
        height != null &&
        weight != null &&
        target != null &&
        maintenanceCe != null &&
        maintenanceSE != null) {
      switch (age) {
        case 5:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 40;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 132;
        case 6:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 55;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 140;
        case 7:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 75;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 148;
        case 8:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 90;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 156;
        case 9:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 110;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 165;
        case 10:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 140;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 170;
        case >= 11 && <= 13:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 200;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 200;
        case > 13:
          minWeightEleMarsh = 35;
          maxWeightEleMarsh = 350;
          minHeightEleMarsh = 100;
          maxHeightEleMarsh = 220;
        default:
          minWeightEleMarsh = 20;
          maxWeightEleMarsh = 350;
          minHeightEleMarsh = 85;
          maxHeightEleMarsh = 220;
      }

      if (age >= m.minAge &&
          age <= m.maxAge &&
          height >= minHeightEleMarsh &&
          height <= maxHeightEleMarsh &&
          weight >= minWeightEleMarsh &&
          weight <= maxWeightEleMarsh &&
          target >= 0.5 &&
          target <= 8.0 &&
          maintenanceCe >= 0.5 &&
          maintenanceCe <= 10 &&
          maintenanceSE >= 1 &&
          maintenanceSE <= 99) {
        DateTime start = DateTime.now();

        Model model = Model.Eleveld;
        Patient patient =
            Patient(weight: weight, height: height, age: age, sex: sex);
        Pump pump = Pump(
            timeStep: Duration(seconds: settings.time_step),
            concentration: settings.propofol_concentration,
            maxPumpRate: settings.max_pump_rate,
            target: target,
            duration: Duration(hours: 3));
        PDSim.Simulation simulation =
            PDSim.Simulation(model: model, patient: patient, pump: pump);

        EleMarsh elemarsh = EleMarsh(goldSimulation: simulation);

        var resultInduction = elemarsh.estimate(weightBound: 0, bolusBound: 0);

        Calculator calculator = Calculator();
        var resultWakeUp =
            calculator.calcWakeUpCE(ce: maintenanceCe, se: maintenanceSE, m: m);

        DateTime finish = DateTime.now();

        Duration calculationDuration = finish.difference(start);

        setState(() {
          weightBestGuess = resultInduction.weightBestGuess.toString();
          inductionCPTarget =
              resultInduction.inductionCPTarget.toStringAsFixed(1);
          int rawManualBolus = resultInduction.manualBolus.round();
          int roundedManualBolus10 = (rawManualBolus / 10).round() * 10;
          manualBolus = roundedManualBolus10.toString();
          adjustmentBolus = resultInduction.adjustmentBolus.round().toString();
          predictedBIS = resultInduction.predictedBIS.toStringAsFixed(0);
          BMI = patient.bmi.toStringAsFixed(1);

          String formatDuration(Duration? duration) {
            if (duration == null) return "--";
            int minutes = duration.inMinutes;
            int seconds = duration.inSeconds % 60;
            if (seconds > 30) {
              minutes += 1;
            }
            return "${minutes} min";
          }

          vial20mlTime = formatDuration(resultInduction.vial20mlTime);
          vial50mlTime = formatDuration(resultInduction.vial50mlTime);

          String lower = resultWakeUp.lower.toStringAsFixed(2);
          String upper = resultWakeUp.upper.toStringAsFixed(2);

          range = lower + ' - ' + upper;

          print({
            'weightBestGuess': weightBestGuess,
            'adjustmentBolus': adjustmentBolus,
            'settings.EMRSI': settings.EMRSI,
            'inductionCPTarget': inductionCPTarget,
            'manualBolus': manualBolus,
            'flow': flow,
            'range': range,
            'calculation time':
                '${calculationDuration.inMilliseconds.toString()} milliseconds'
          });
        });
        final statusInfo = flow == 'induce'
            ? 'ABW: $weightBestGuess kg · CeT: ${target.toStringAsFixed(1)}μg/mL'
            : 'Wake-up: $range μg/mL · Model: ${m.toString()}';
        if (initState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) settings.statusBarInfo = statusInfo;
          });
        } else {
          settings.statusBarInfo = statusInfo;
        }
      } else {
        setState(() {
          weightBestGuess = "--";
          adjustmentBolus = "--";
          inductionCPTarget = "--";
          manualBolus = "--";
          range = "--";
          vial20mlTime = "--";
          vial50mlTime = "--";
        });
        if (initState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) settings.statusBarInfo = null;
          });
        } else {
          settings.statusBarInfo = null;
        }
      }
    } else {
      setState(() {
        weightBestGuess = "--";
        adjustmentBolus = "--";
        inductionCPTarget = "--";
        manualBolus = "--";
        range = "--";
        vial20mlTime = "--";
        vial50mlTime = "--";
      });
      if (initState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) settings.statusBarInfo = null;
        });
      } else {
        settings.statusBarInfo = null;
      }
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    if (!_isWakeFlow) {
      _sexValue = toDefault
          ? true
          : settings.EMSex == Sex.Female
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
    } else {
      _isEleveldModel = toDefault
          ? false
          : settings.EMWakeUpModel == Model.EleMarsh
              ? false
              : true;
      maintenanceCeController.text = toDefault
          ? 3.0.toString()
          : settings.EMMaintenanceCe != null
              ? settings.EMMaintenanceCe.toString()
              : '';
      maintenanceSEController.text = toDefault
          ? 40.toString()
          : settings.EMMaintenanceSE != null
              ? settings.EMMaintenanceSE.toString()
              : '';
    }
    run();
  }

  int minWeightEleMarsh = 20;
  int maxWeightEleMarsh = 350;
  int minHeightEleMarsh = 85;
  int maxHeightEleMarsh = 220;

  List<String> _validate() {
    final errors = <String>[];
    final age = int.tryParse(ageController.text);
    final height = int.tryParse(heightController.text);
    final weight = int.tryParse(weightController.text);
    final target = double.tryParse(targetController.text);
    final maintenanceCe = double.tryParse(maintenanceCeController.text);
    final maintenanceSE = int.tryParse(maintenanceSEController.text);

    if (age != null && (age < Model.EleMarsh.minAge || age > Model.EleMarsh.maxAge)) {
      errors.add('Age ${Model.EleMarsh.minAge}-${Model.EleMarsh.maxAge}');
    }
    if (height != null && (height < minHeightEleMarsh || height > maxHeightEleMarsh)) {
      errors.add('Height $minHeightEleMarsh-$maxHeightEleMarsh cm');
    }
    if (weight != null && (weight < minWeightEleMarsh || weight > maxWeightEleMarsh)) {
      errors.add('Weight $minWeightEleMarsh-$maxWeightEleMarsh kg');
    }
    if (target != null && (target < 0.5 || target > 8.0)) {
      errors.add('Target 0.5-8.0 μg/mL');
    }
    if (maintenanceCe != null && (maintenanceCe < 0.5 || maintenanceCe > 10)) {
      errors.add('Maintenance Ce 0.5-10 μg/mL');
    }
    if (maintenanceSE != null && (maintenanceSE < 1 || maintenanceSE > 99)) {
      errors.add('Maintenance SE 1-99');
    }
    return errors;
  }

  Widget _buildErrorPanel(List<String> errors) {
    return SizedBox(
      height: 48,
      child: errors.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSp16, vertical: 8),
              child: Text(
                errors.first,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
    );
  }

  Widget _buildInputFields(Settings settings) {
    final theme = Theme.of(context);
    final errors = _validate();
    final age = int.tryParse(ageController.text);
    final isAdult = age == null || age >= 17;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildErrorPanel(errors),
        const SizedBox(height: kSp12),
        // Flow selector + Help/Reset buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: !_isWakeFlow ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                            foregroundColor: !_isWakeFlow ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(kRadius)),
                              side: BorderSide(color: theme.colorScheme.outline),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isWakeFlow = false);
                            settings.EMFlow = 'induce';
                            run();
                          },
                          child: Text(AppLocalizations.of(context)!.induce),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: _isWakeFlow ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                            foregroundColor: _isWakeFlow ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(kRadius)),
                              side: BorderSide(color: theme.colorScheme.outline),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _isWakeFlow = true);
                            settings.EMFlow = 'wake';
                            run();
                          },
                          child: Text(AppLocalizations.of(context)!.emerge),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: kSp8),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                  ),
                  onPressed: () => _isWakeFlow ? showWakeAlertDialog(context) : showInduceAlertDialog(context),
                  child: const Icon(Symbols.question_mark, size: 20),
                ),
              ),
              const SizedBox(width: kSp8),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                  ),
                  onPressed: () { HapticFeedback.mediumImpact(); reset(toDefault: true); },
                  child: const Icon(Icons.restart_alt_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // RSI/STD toggle (Induce only)
        if (!_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: !settings.EMRSI ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                        foregroundColor: !settings.EMRSI ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(kRadius)),
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                      ),
                      onPressed: () {
                        settings.EMRSI = false;
                        run();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_liquid, size: 18),
                          SizedBox(width: 6),
                          Text('STD'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: settings.EMRSI ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                        foregroundColor: settings.EMRSI ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(kRadius)),
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                      ),
                      onPressed: () {
                        settings.EMRSI = true;
                        run();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.front_hand, size: 18),
                          SizedBox(width: 6),
                          Text('RSI'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!_isWakeFlow) const SizedBox(height: kSp12),
        // Induce: Sex + Age
        if (!_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Row(
              children: [
                Expanded(
                  child: SwitchField(
                    labelText: AppLocalizations.of(context)!.sex,
                    prefixIcon: _sexValue
                        ? (isAdult ? Icons.woman : Icons.girl)
                        : (isAdult ? Icons.man : Icons.boy),
                    value: _sexValue,
                    switchLabels: {
                      true: isAdult ? Sex.Female.toLocalizedString(context) : Sex.Girl.toLocalizedString(context),
                      false: isAdult ? Sex.Male.toLocalizedString(context) : Sex.Boy.toLocalizedString(context),
                    },
                    onChanged: (v) { setState(() => _sexValue = v); run(); },
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
                    range: [Model.EleMarsh.minAge, Model.EleMarsh.maxAge],
                    onChanged: () { _debounceTimer.cancel(); _debounceTimer = Timer(_debounceDelay, run); },
                    hasError: errors.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
        if (!_isWakeFlow) const SizedBox(height: kSp12),
        // Induce: Height + Weight
        if (!_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Row(
              children: [
                Expanded(
                  child: PKField(
                    prefixIcon: Icons.straighten,
                    labelText: '${AppLocalizations.of(context)!.height} (cm)',
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: heightController,
                    range: [minHeightEleMarsh, maxHeightEleMarsh],
                    onChanged: () { _debounceTimer.cancel(); _debounceTimer = Timer(_debounceDelay, run); },
                    hasError: errors.isNotEmpty,
                  ),
                ),
                const SizedBox(width: kSp12),
                Expanded(
                  child: PKField(
                    prefixIcon: Icons.monitor_weight_outlined,
                    labelText: '${AppLocalizations.of(context)!.weight} (kg)',
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: weightController,
                    range: [minWeightEleMarsh, maxWeightEleMarsh],
                    onChanged: () { _debounceTimer.cancel(); _debounceTimer = Timer(_debounceDelay, run); },
                    hasError: errors.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
        if (!_isWakeFlow) const SizedBox(height: kSp12),
        // Induce: Target
        if (!_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Row(
              children: [
                Expanded(
                  child: PKField(
                    prefixIcon: Target.EffectSite.icon,
                    labelText: '${AppLocalizations.of(context)!.effectSiteTarget} (μg/mL)',
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: targetController,
                    range: const [0.5, 8],
                    onChanged: () { _debounceTimer.cancel(); _debounceTimer = Timer(_debounceDelay, run); },
                    hasError: errors.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
        if (!_isWakeFlow) const SizedBox(height: kSp12),
        // Emerge: Model
        if (_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Row(
              children: [
                Expanded(
                  child: SwitchField(
                    labelText: AppLocalizations.of(context)!.model,
                    prefixIcon: _isEleveldModel ? Icons.spoke_outlined : Icons.hub_outlined,
                    value: _isEleveldModel,
                    switchLabels: {
                      true: Model.Eleveld.toString(),
                      false: Model.EleMarsh.toString(),
                    },
                    onChanged: (v) { setState(() => _isEleveldModel = v); run(); },
                  ),
                ),
              ],
            ),
          ),
        if (_isWakeFlow) const SizedBox(height: kSp12),
        // Emerge: Maintenance SE
        if (_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Row(
              children: [
                Expanded(
                  child: PKField(
                    prefixIcon: Icons.monitor_heart_outlined,
                    labelText: AppLocalizations.of(context)!.maintenanceStateEntropy,
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: maintenanceSEController,
                    range: const [1, 99],
                    onChanged: () { _debounceTimer.cancel(); _debounceTimer = Timer(_debounceDelay, run); },
                    hasError: errors.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
        if (_isWakeFlow) const SizedBox(height: kSp12),
        // Emerge: Maintenance Ce
        if (_isWakeFlow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSp16),
            child: Row(
              children: [
                Expanded(
                  child: PKField(
                    prefixIcon: (_isEleveldModel ? Model.Eleveld : Model.EleMarsh).target.icon,
                    labelText: _isEleveldModel
                        ? AppLocalizations.of(context)!.maintenanceCe
                        : AppLocalizations.of(context)!.maintenanceCp,
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: maintenanceCeController,
                    range: const [0.5, 8],
                    onChanged: () { _debounceTimer.cancel(); _debounceTimer = Timer(_debounceDelay, run); },
                    hasError: errors.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
        if (_isWakeFlow) const SizedBox(height: kSp12),
      ],
    );
  }

  Widget _buildInputPanel(Settings settings) {
    final useMobile = ResponsiveHelper.shouldUseMobileLayout(context);
    if (!useMobile) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        child: _buildInputFields(settings),
      );
    }
    return CollapsibleInputSection(
      child: _buildInputFields(settings),
      collapsedChips: _buildCollapsedChips(),
    );
  }

  List<Widget> _buildCollapsedChips() {
    final errors = _validate();
    final theme = Theme.of(context);
    final ageText = ageController.text;
    final weightText = weightController.text;
    final heightText = heightController.text;
    final targetText = targetController.text;

    Widget chip({
      required String displayValue,
      required String emptyLabel,
      required IconData icon,
      required bool isEmpty,
      required bool hasError,
    }) {
      final chipColor = hasError
          ? theme.colorScheme.error
          : (isEmpty ? theme.colorScheme.outline : null);
      final bgColor = hasError
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
          : null;
      return Chip(
        avatar: Icon(hasError ? Icons.error_outline : icon, size: 16, color: chipColor),
        label: Text(isEmpty ? emptyLabel : displayValue,
            style: TextStyle(fontSize: 11, color: chipColor)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: bgColor,
      );
    }

    return [
      Chip(
        avatar: Icon(_isWakeFlow ? Icons.wb_sunny_outlined : Icons.nightlight_outlined, size: 16),
        label: Text(_isWakeFlow ? 'Wake' : 'Induce', style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      Chip(
        avatar: Icon(_sexValue ? Icons.female : Icons.male, size: 16),
        label: Text(_sexValue ? 'F' : 'M', style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      chip(
        displayValue: '${ageText}y',
        emptyLabel: 'Age',
        icon: Icons.calendar_month,
        isEmpty: ageText.isEmpty,
        hasError: errors.any((e) => e.startsWith('Age')),
      ),
      chip(
        displayValue: '${weightText}kg',
        emptyLabel: 'Weight',
        icon: Icons.monitor_weight,
        isEmpty: weightText.isEmpty,
        hasError: errors.any((e) => e.startsWith('Weight')),
      ),
      chip(
        displayValue: '${heightText}cm',
        emptyLabel: 'Height',
        icon: Icons.straighten,
        isEmpty: heightText.isEmpty,
        hasError: errors.any((e) => e.startsWith('Height')),
      ),
      if (!_isWakeFlow)
        chip(
          displayValue: '${targetText} μg/mL',
          emptyLabel: 'Target',
          icon: Icons.psychology,
          isEmpty: targetText.isEmpty,
          hasError: errors.any((e) => e.startsWith('Target')),
        ),
    ];
  }

  Widget _buildResultsSection(Settings settings) {
    final theme = Theme.of(context);
    final isInduceFlow = !_isWakeFlow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isInduceFlow) ...[
          Padding(
            padding: const EdgeInsets.only(left: kSp4, bottom: kSp8),
            child: Text(
              AppLocalizations.of(context)!.induce,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'EleMarsh ${AppLocalizations.of(context)!.abw}',
                  '$weightBestGuess',
                  'kg',
                  Icons.monitor_weight,
                  theme.colorScheme.primary,
                  theme,
                  valueFontSize: 32,
                  prominent: true,
                ),
              ),
              const SizedBox(width: kSp8),
              Expanded(
                child: _buildStatCard(
                  settings.EMRSI
                      ? AppLocalizations.of(context)!.manualBolus
                      : '${AppLocalizations.of(context)!.induction} CpT',
                  settings.EMRSI ? manualBolus : inductionCPTarget,
                  settings.EMRSI ? 'mg' : 'μg/mL',
                  settings.EMRSI ? Icons.medication_liquid : Icons.psychology,
                  settings.EMRSI
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                  theme,
                  valueFontSize: 32,
                  prominent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'eBIS',
                  predictedBIS,
                  '',
                  Icons.monitor_heart_outlined,
                  theme.colorScheme.onSurface,
                  theme,
                  valueFontSize: 18,
                ),
              ),
              const SizedBox(width: kSp8),
              Expanded(
                child: _buildStatCard(
                  'BMI',
                  BMI,
                  '',
                  Icons.monitor_weight,
                  theme.colorScheme.onSurface,
                  theme,
                  valueFontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSp8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '20 mL',
                  vial20mlTime,
                  'min',
                  Icons.schedule,
                  theme.colorScheme.onSurface,
                  theme,
                  valueFontSize: 18,
                ),
              ),
              const SizedBox(width: kSp8),
              Expanded(
                child: _buildStatCard(
                  '50 mL',
                  vial50mlTime,
                  'min',
                  Icons.schedule,
                  theme.colorScheme.onSurface,
                  theme,
                  valueFontSize: 18,
                ),
              ),
            ],
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(left: kSp4, bottom: kSp8),
            child: Text(
              AppLocalizations.of(context)!.wakeUpRange,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius),
              side: isMaintenanceSEOutOfRange
                  ? BorderSide(color: theme.colorScheme.error)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    range,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: isMaintenanceSEOutOfRange
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: kSp8),
                  Text(
                    'μg/mL',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMaintenanceSEOutOfRange)
            Padding(
              padding: const EdgeInsets.only(top: kSp8),
              child: Text(
                '*Accuracy reduced, min: 21 and max: 60',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    ThemeData theme, {
    double valueFontSize = 24,
    bool prominent = false,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: prominent
            ? BorderSide(color: accentColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: prominent ? 14 : 12,
          horizontal: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: kSp4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSp8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(width: kSp4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Settings settings) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalSidesPaddingPixel,
          right: horizontalSidesPaddingPixel,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12),
                child: _buildResultsSection(settings),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 393,
              child: _buildInputPanel(settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Settings settings) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: horizontalSidesPaddingPixel,
                      right: horizontalSidesPaddingPixel,
                      bottom: 12,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildResultsSection(settings),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: _buildInputPanel(settings),
          ),
        ],
      ),
    );
  }

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
    final isTabletLayout = ResponsiveHelper.isTablet(context) && !isDesktopLayout;

    final settings = context.watch<Settings>();

    if (isDesktopLayout) {
      return _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings));
    }
    if (isTabletLayout) {
      return _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings));
    }

    return _buildMobileLayout(settings);
  }

  // ─── Info dialogs (EleMarsh Algorithm) ───────────────────

  AlertDialog ja_std_induce_info(BuildContext context) {
    return AlertDialog(
      title: Text('EleMarshモデル使用手順 （標準）'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '目的：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: 'Marshモデルを用いて、Eleveldモデルの薬物投与挙動を正確にシミュレートする。\n\n'),
            TextSpan(
                text: '使用方法：\n',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: "（1）患者情報および希望するEleveld効果部位目標濃度を入力する。\n"),
            TextSpan(text: "（2）EleMarshアルゴリズムが調整体重および導入CpT（目標血漿濃度）を計算する。\n"),
            TextSpan(text: "（3）TCIポンプのMarshモデルの体重入力には、算出された調整体重を用いる。\n"),
            TextSpan(
                text:
                    "（4）導入CpTを初期の目標血漿濃度として設定する。ボーラス投与が完了したら、直ちに目標血漿濃度を維持濃度へと下げる。その後、ポンプのMarshモデルはEleveldモデルの薬物投与挙動を正確にシミュレートする。\n\n"),
            TextSpan(
                text: "文献:\n", style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275."),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog ja_rsi_induce_info(BuildContext context) {
    return AlertDialog(
      title: Text('EleMarshモデル使用手順 (迅速なシーケンス誘導)'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '目的：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: 'Marshモデルを用いて、Eleveldモデルの薬物投与挙動を正確にシミュレートする。\n\n'),
            TextSpan(
                text: '使用方法：\n',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: "（1）入力患者情報及び希望するEleveld効果部位目標濃度。\n"),
            TextSpan(text: "（2）EleMarshアルゴリズムが調整体重及び手動ボーラス投与量を算出。\n"),
            TextSpan(text: "（3）TCIポンプのMarshモデルの体重入力には、算出された調整体重を使用。\n"),
            TextSpan(
                text:
                    '（4）迅速導入（RSI）時には、まず算出された手動ボーラス投与量を迅速に静脈内投与する。投与終了後、直ちにTCIポンプを開始し、初期の血漿目標濃度を希望する効果部位目標濃度に設定する。維持期に入ると、TCIポンプ上のMarshモデルはEleveldモデルの薬物投与挙動を正確にシミュレートする。\n\n'),
            TextSpan(
                text: '文献:\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    'Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275.'),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog zh_std_induce_info(BuildContext context) {
    return AlertDialog(
      title: Text('EleMarsh模型使用指南 (标准）'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '目的：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '用Marsh模型精准模拟Eleveld模型的输注行为。\n\n'),
            TextSpan(
                text: '使用方法：\n',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '（1）输入患者信息及期望达到的Eleveld效应室靶浓度。\n'),
            TextSpan(text: '（2）EleMarsh算法将计算调整体重及诱导CpT(血浆靶浓度)。\n'),
            TextSpan(text: '（3）在TCI泵的Marsh模型中，将调整体重作为患者体重输入。\n'),
            TextSpan(
                text:
                    '（4）初始设置血浆靶浓度为诱导CpT。当诱导剂量推注完毕后，立即将血浆靶浓度降低至维持靶浓度。此后，泵上的Marsh模型将精准模拟Eleveld模型的输注行为。\n\n'),
            TextSpan(
                text: '文献:\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    'Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275.'),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog zh_rsi_induce_info(BuildContext context) {
    return AlertDialog(
      title: Text('EleMarsh模型使用指南（快速顺序诱导）'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '目的：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '使Marsh模型精准模拟Eleveld模型的输注行为。\n\n'),
            TextSpan(
                text: '使用方法：\n',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '（1）输入患者信息及期望达到的Eleveld效应室靶浓度。\n'),
            TextSpan(text: '（2）EleMarsh算法将计算调整体重及手动推注剂量。\n'),
            TextSpan(text: '（3）在TCI泵的Marsh模型中，将调整体重作为患者体重输入。\n'),
            TextSpan(
                text:
                    '（4）在快速顺序诱导时，先快速手动推注计算出的剂量，推注完成后立即启动TCI泵，初始血浆靶浓度设置为期望的效应室靶浓度。进入维持阶段后，泵上的Marsh模型即可精准模拟Eleveld模型的输注行为。\n\n'),
            TextSpan(
                text: '文献:\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    'Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275.'),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog en_std_induce_info(BuildContext context) {
    return AlertDialog(
      title: Text('EleMarsh Algorithm (Standard)'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: "Aim:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Accurately mimic the infusion behaviour of Eleveld model using Marsh model.\n\n"),
            TextSpan(
                text: "Usage:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "(1) Enter patient details and desired Eleveld Ce target\n"),
            TextSpan(
                text:
                    "(2) EleMarsh calculates the Adjusted Body Weight and Induction CpT\n"),
            TextSpan(
                text:
                    "(3) Use the Adjusted Body Weight as the input weight for Marsh model on TCI pump\n"),
            TextSpan(
                text:
                    "(4) Use the Induction CpT as the initial CpT setting. As soon as the bolus is finished, drop CpT down to the desired CeT for maintenance. The Marsh model on your pump will now accurately mimic the Eleveld model.\n\n"),
            TextSpan(
                text: "Reference:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275."),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog en_rsi_induce_info(BuildContext context) {
    return AlertDialog(
      title: Text('EleMarsh Algorithm (RSI)'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: "Aim:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Accurately mimic the infusion behaviour of Eleveld model using Marsh model.\n\n"),
            TextSpan(
                text: "Usage:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "(1) Enter patient details and desired Eleveld Ce target\n"),
            TextSpan(
                text:
                    "(2) EleMarsh calculates the Adjusted Body Weight and Manual Bolus\n"),
            TextSpan(
                text:
                    "(3) Use the Adjusted Body Weight as the input weight for Marsh model on TCI pump\n"),
            TextSpan(
                text:
                    "(4) During RSI, rapidly inject the Manual Bolus dose and immediately start the TCI pump with initial CpT set to the desired CeT. During maintenance phase, the Marsh model on your pump will accurately mimic the Eleveld model.\n\n"),
            TextSpan(
                text: "Reference:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Zhong G., Xu X. General purpose propofol target-controlled infusion using the Marsh model with adjusted body weight. J Anesth. 2024;38(2):275."),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  void showInduceAlertDialog(BuildContext context) {
    final settings = context.read<Settings>();
    settings.EMRSI
        ? showDialog(
            context: context,
            builder: (BuildContext context) {
              switch (Localizations.localeOf(context).languageCode) {
                case 'ja':
                  return ja_rsi_induce_info(context);
                case 'zh':
                  return zh_rsi_induce_info(context);
                default:
                  return en_rsi_induce_info(context);
              }
            },
          )
        : showDialog(
            context: context,
            builder: (BuildContext context) {
              switch (Localizations.localeOf(context).languageCode) {
                case 'ja':
                  return ja_std_induce_info(context);
                case 'zh':
                  return zh_std_induce_info(context);
                default:
                  return en_std_induce_info(context);
              }
            },
          );
  }

  AlertDialog ja_wake_info(BuildContext context) {
    return AlertDialog(
      title: Text('覚醒時血中濃度の推定'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '目的：\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '患者が全身麻酔から覚醒（音声刺激で開眼）する際のプロポフォール血漿中濃度（Cp）を推定する。\n\n',
              ),
              TextSpan(
                text: '使用方法：\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '（1）維持期におけるEleMarsh血漿中濃度を入力する（必ず定常状態に達していることを確認する）。\n',
              ),
              TextSpan(
                text: '（2）その時点での状態エントロピー（State Entropy, SE）の数値を入力する。\n',
              ),
              TextSpan(
                text:
                    '（3）アルゴリズムが患者個人のプロポフォール感受性に基づき、麻酔覚醒時の血漿中濃度の範囲を推定する。\n\n',
              ),
              TextSpan(
                text: '注意事項：\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    '（a）本アルゴリズムが推定する覚醒時Cpは、最小限の外的刺激を前提としている。実際の覚醒濃度は、刺激の強度、疼痛の程度、筋弛緩薬の使用状況、併用薬剤などによって影響を受ける可能性がある。\n',
              ),
              TextSpan(
                text:
                    '（b）本アルゴリズムは手術時間が60分を超える症例で検証されている。手術時間が短い場合、推定結果の精度が低下する可能性がある。\n\n',
              ),
              TextSpan(
                text: '文献:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'Zhong G., Tung AMS., Xu X. Simple model for predicting the awakening propofol plasma concentration during target-controlled infusion with the Marsh model. BJA. 2025;134(4):1253.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog zh_wake_info(BuildContext context) {
    return AlertDialog(
      title: Text('苏醒浓度估算'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '目的：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '估算患者从麻醉苏醒时的丙泊酚血浆浓度。\n\n'),
            TextSpan(
                text: '使用方法：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '（1）输入维持阶段的EleMarsh血浆浓度（请确认已达到稳态）。\n'),
            TextSpan(text: '（2）输入对应的状态熵（SE）数值。\n'),
            TextSpan(text: '（3）算法根据患者个体对丙泊酚的敏感性，推算出麻醉苏醒时的血浆浓度范围。\n\n'),
            TextSpan(
                text: '注意事项：\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    '（a）本算法推测的苏醒血浆浓度是假设患者受到最小外界刺激的情形下得出。实际苏醒浓度可能受到刺激强度、疼痛程度、肌松药物使用及辅助用药的影响。\n'),
            TextSpan(
                text:
                    '（b）本算法适用于手术时长超过60分钟的病例；对于手术时间较短者，估算结果可能存在偏差。\n\n'),
            TextSpan(
                text: '文献:\n', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    'Zhong G., Tung AMS., Xu X. Simple model for predicting the awakening propofol plasma concentration during target-controlled infusion with the Marsh model. BJA. 2025;134(4):1253.'),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  AlertDialog en_wake_info(BuildContext context) {
    return AlertDialog(
      title: Text('Wake Up Estimation'),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: "Aim:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Estimate the propofol Cp at which the patient emerges from general anaesthesia (i.e. eye open to voice).\n\n"),
            TextSpan(
                text: "Usage:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "(1) Enter the maintenance phase EleMarsh Cp (ensure steady state has been achieved).\n"),
            TextSpan(
                text:
                    "(2) Enter the corresponding state entropy (SE) observed.\n"),
            TextSpan(
                text:
                    "(3) The algorithm will derive the Cp range for anaesthesia emergence based on the individual's propofol sensitivity.\n\n"),
            TextSpan(
                text: "Limitations:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "(a) Wake up Cp estimate assumes minimal stimulus. Actual wake up Cp will depend on stimulus, pain, paralysis and adjuvants.\n"),
            TextSpan(
                text:
                    "(b) Validated for surgeries longer than 60 minutes. May be inaccurate for shorter procedures.\n\n"),
            TextSpan(
                text: "Reference:\n",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    "Zhong G., Tung AMS., Xu X. Simple model for predicting the awakening propofol plasma concentration during target-controlled infusion with the Marsh model. BJA. 2025;134(4):1253."),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }

  void showWakeAlertDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          switch (Localizations.localeOf(context).languageCode) {
            case 'ja':
              return ja_wake_info(context);
            case 'zh':
              return zh_wake_info(context);
            default:
              return en_wake_info(context);
          }
        });
  }
}
