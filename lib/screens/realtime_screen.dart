import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:propofol_dreams_app/models/infusion_regime_data.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/target.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as pd_sim;

import '../components/infusion_regime_table.dart';
import '../components/collapsible_input_card.dart';
import '../components/input_summary_display.dart';
import '../components/material3/m3_text_field.dart';
import '../utils/text_measurement.dart';

import 'package:propofol_dreams_app/components/legacy/PDSwitchController.dart';
import 'package:propofol_dreams_app/components/legacy/PDSwitchField.dart';
import 'package:propofol_dreams_app/components/legacy/PDAdvancedSegmentedController.dart';

// ── Layout constants ─────────────────────────────────────────

const double _kFieldHeight = 56;
const double _kErrorSlot = 24;
const double _kRowHeight = _kFieldHeight + _kErrorSlot;
const double _kSidebarMin = 320;
const double _kSidebarMax = 420;
const double _kSidebarRatio = 0.35;
const double _kBreakpointWide = 840;

// ── AdaptiveScreenLayout ──────────────────────────────────────

class AdaptiveScreenLayout extends StatelessWidget {
  final Widget sidePanel;
  final Widget mainContent;

  const AdaptiveScreenLayout({
    super.key,
    required this.sidePanel,
    required this.mainContent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= _kBreakpointWide;
      if (isWide) {
        final sidebarWidth =
            (constraints.maxWidth * _kSidebarRatio)
                .clamp(_kSidebarMin, _kSidebarMax);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: sidebarWidth, child: sidePanel),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: mainContent),
          ],
        );
      }
      return Column(children: [
        sidePanel,
        Expanded(child: mainContent),
      ]);
    });
  }
}

// ── RealtimeScreen ────────────────────────────────────────────

class RealtimeScreen extends StatefulWidget {
  const RealtimeScreen({super.key});

  @override
  State<RealtimeScreen> createState() => _RealtimeScreenState();
}

class _RealtimeScreenState extends State<RealtimeScreen> {
  Drug? selectedDrug;
  final PDAdvancedSegmentedController tciModelController =
      PDAdvancedSegmentedController();
  PDSwitchController sexController = PDSwitchController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  final ScrollController tableScrollController = ScrollController();
  final List<Model> modelOptions = [];

  InfusionRegimeData? infusionRegimeData;
  bool _isCalculating = false;

  late TimeOfDay _startTime;

  static const int _fixedDurationMinutes = 240;

  final GlobalKey<State<CollapsibleInputCard>> _inputCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();

    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);

    modelOptions.addAll([
      Model.Eleveld, Model.Marsh, Model.Schnider, Model.Hannivoort, Model.Eleveld,
    ]);

    calculate();
  }

  void _setControllersFromSettings(Settings settings) {
    tciModelController.selection = settings.tciModel;
    selectedDrug = settings.tciDrug;
    sexController.val = settings.tciSex == Sex.Female ? true : false;
    ageController.text = settings.tciAge?.toString() ?? '40';
    heightController.text = settings.tciHeight?.toString() ?? '170';
    weightController.text = settings.tciWeight?.toString() ?? '70';
    final drugTarget = settings.getTciDrugTarget(selectedDrug);
    final targetProps = tciModelController.selection.getTargetProperties(selectedDrug);
    targetController.text = drugTarget?.toString() ?? targetProps.defaultValue.toString();
    durationController.text = '$_fixedDurationMinutes';
  }

  void _saveToSettings() {
    if (!mounted) return;
    final settings = Provider.of<Settings>(context, listen: false);
    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    Sex sex = sexController.val ? Sex.Female : Sex.Male;
    settings.tciSex = sex;
    settings.tciAge = age;
    settings.tciHeight = height;
    settings.tciWeight = weight;
    settings.setTciDrugTarget(selectedDrug, target);
  }

  void calculate() {
    if (_isCalculating) return;
    setState(() => _isCalculating = true);

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveToSettings();
      });

      final settings = Provider.of<Settings>(context, listen: false);
      final finalAge = int.tryParse(ageController.text) ?? 40;
      final finalHeight = int.tryParse(heightController.text) ?? 170;
      final finalWeight = int.tryParse(weightController.text) ?? 70;
      final finalTarget = double.tryParse(targetController.text) ?? 3.0;
      final sex = sexController.val ? Sex.Female : Sex.Male;
      final selectedModel = tciModelController.selection;

      final patient = Patient(
        weight: finalWeight, age: finalAge, height: finalHeight, sex: sex,
      );

      final pump = Pump(
        timeStep: Duration(seconds: settings.time_step),
        concentration: selectedDrug?.concentration ?? settings.propofol_concentration,
        maxPumpRate: settings.max_pump_rate,
        target: finalTarget,
        duration: Duration(minutes: _fixedDurationMinutes),
        drug: selectedDrug,
      );

      if (selectedModel != Model.None &&
          selectedModel.isRunnable(
            age: finalAge, height: finalHeight,
            weight: finalWeight, target: finalTarget,
            duration: _fixedDurationMinutes,
          )) {
        final simulation = pd_sim.Simulation(
          model: selectedModel, patient: patient, pump: pump,
        );

        var results = simulation.estimate;

        setState(() {
          infusionRegimeData = InfusionRegimeData.fromSimulation(
            times: results.times,
            pumpInfs: results.pumpInfs,
            cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
            density: 10,
            totalDuration: Duration(minutes: _fixedDurationMinutes),
            isEffectSiteTargeting: selectedModel.target == Target.EffectSite,
            drugConcentrationMgMl: selectedDrug?.concentration ?? 10.0,
          );
          _isCalculating = false;
        });
      } else {
        setState(() {
          infusionRegimeData = null;
          _isCalculating = false;
        });
      }
    } catch (e) {
      setState(() => _isCalculating = false);
    }
  }

  Model getModelForDrug(Drug? drug) {
    if (drug == null) return Model.Eleveld;
    if (drug.isDexmedetomidine) return Model.Hannivoort;
    return Model.Eleveld;
  }

  String _format12Hour(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);
    sexController.val = toDefault ? true : settings.tciSex == Sex.Female;
    ageController.text = toDefault ? '40' : (settings.tciAge?.toString() ?? '');
    heightController.text = toDefault ? '170' : (settings.tciHeight?.toString() ?? '');
    weightController.text = toDefault ? '70' : (settings.tciWeight?.toString() ?? '');
    final currentModel = getModelForDrug(selectedDrug);
    final targetProps = currentModel.getTargetProperties(selectedDrug);
    targetController.text = toDefault
        ? targetProps.defaultValue.toString()
        : settings.getTciDrugTarget(selectedDrug)?.toString() ?? targetProps.defaultValue.toString();
    durationController.text = '$_fixedDurationMinutes';
    calculate();
  }

  void _onCalculate() { calculate(); }

  bool _hasValidationErrors() {
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;
    final currentModel = tciModelController.selection is Model
        ? tciModelController.selection as Model : null;
    return currentModel != null &&
        tciModelController.hasValidationError(sex: sex, weight: weight, height: height, age: age);
  }

  String? _validationErrorText() {
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;
    final currentModel = tciModelController.selection is Model
        ? tciModelController.selection as Model : null;
    if (currentModel == null) return null;
    final hasErr = tciModelController.hasValidationError(
        sex: sex, weight: weight, height: height, age: age);
    if (!hasErr) return null;
    return tciModelController.getValidationErrorText(
        sex: sex, weight: weight, height: height, age: age);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final int age = int.tryParse(ageController.text) ?? 0;
    final bool isAdult = age >= 17;
    final bool heightTextFieldEnabled = getModelForDrug(selectedDrug).target != Target.Plasma;
    final bool sexSwitchControlEnabled = getModelForDrug(selectedDrug).target != Target.Plasma;
    final bool ageTextFieldEnabled = tciModelController.selection != Model.Marsh &&
        selectedDrug?.isDexmedetomidine != true;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AdaptiveScreenLayout(
        sidePanel: Column(
          children: [
            CollapsibleInputCard(
              key: _inputCardKey,
              title: 'Real-Time TCI',
              isInitiallyExpanded: true,
              showCalculateButton: true,
              expandedContent: _buildExpandedInputs(
                  context, settings, isAdult, heightTextFieldEnabled,
                  sexSwitchControlEnabled, ageTextFieldEnabled),
              collapsedSummary: _buildCollapsedSummary(context),
              onCalculate: _onCalculate,
              isCalculating: _isCalculating,
              hasValidationError: _hasValidationErrors(),
              forceExpanded: _hasValidationErrors(),
            ),
          ],
        ),
        mainContent: _buildResultsArea(context, settings),
      ),
    );
  }

  Widget _buildExpandedInputs(
    BuildContext context, Settings settings,
    bool isAdult, bool heightTextFieldEnabled,
    bool sexSwitchControlEnabled, bool ageTextFieldEnabled,
  ) {
    final validationErr = _validationErrorText();

    return Column(
      children: [
        // Start time
        _buildStartTimeField(context),
        const SizedBox(height: 12),

        // Drug + Reset
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDrugSelector(context, settings)),
            const SizedBox(width: 8),
            _buildResetButton(context),
          ],
        ),
        const SizedBox(height: 12),

        // Validation error
        if (validationErr != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              validationErr,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 10,
              ),
              maxLines: 2,
            ),
          ),
        ],

        // Sex + Age
        SizedBox(
          height: _kRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PDSwitchField(
                  labelText: AppLocalizations.of(context)!.sex,
                  prefixIcon: sexController.val == true
                      ? isAdult ? Icons.woman : Icons.girl
                      : isAdult ? Icons.man : Icons.boy,
                  controller: sexController,
                  switchTexts: {
                    true: isAdult
                        ? Sex.Female.toLocalizedString(context)
                        : Sex.Girl.toLocalizedString(context),
                    false: isAdult
                        ? Sex.Male.toLocalizedString(context)
                        : Sex.Boy.toLocalizedString(context)
                  },
                  onChanged: calculate,
                  height: _kFieldHeight,
                  enabled: sexSwitchControlEnabled,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3TextField(
                  prefixIcon: Icons.calendar_month,
                  labelText: AppLocalizations.of(context)!.age,
                  interval: 1.0,
                  fractionDigits: 0,
                  controller: ageController,
                  range: [
                    getModelForDrug(selectedDrug).minAge,
                    getModelForDrug(selectedDrug).maxAge,
                  ],
                  onPressed: calculate,
                  enabled: ageTextFieldEnabled,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Height + Weight
        SizedBox(
          height: _kRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: M3TextField(
                  prefixIcon: Icons.straighten,
                  labelText: '${AppLocalizations.of(context)!.height} (cm)',
                  interval: 1,
                  fractionDigits: 0,
                  controller: heightController,
                  range: [
                    getModelForDrug(selectedDrug).minHeight,
                    getModelForDrug(selectedDrug).maxHeight,
                  ],
                  onPressed: calculate,
                  enabled: heightTextFieldEnabled,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3TextField(
                  prefixIcon: Icons.monitor_weight_outlined,
                  labelText: '${AppLocalizations.of(context)!.weight} (kg)',
                  interval: 1.0,
                  fractionDigits: 0,
                  controller: weightController,
                  range: [
                    getModelForDrug(selectedDrug).minWeight,
                    getModelForDrug(selectedDrug).maxWeight,
                  ],
                  onPressed: calculate,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Target
        M3TextField(
          prefixIcon: getModelForDrug(selectedDrug).target.icon,
          labelText: getModelForDrug(selectedDrug).getTargetLabel(context, selectedDrug),
          interval: getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).interval,
          fractionDigits: 1,
          controller: targetController,
          range: [
            getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).min,
            getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).max,
          ],
          onPressed: calculate,
        ),
      ],
    );
  }

  Widget _buildCollapsedSummary(BuildContext context) {
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;
    final double target = double.tryParse(targetController.text) ?? 0.0;
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;

    return InputSummaryDisplay(
      calculatorType: CalculatorType.tci,
      age: age > 0 ? age : null,
      sex: sex,
      weight: weight > 0 ? weight : null,
      height: height > 0 ? height : null,
      drug: selectedDrug,
      model: tciModelController.selection as Model?,
      target: target > 0 ? target : null,
      duration: _fixedDurationMinutes,
    );
  }

  // ── Results Area ────────────────────────────────────────────

  Widget _buildResultsArea(BuildContext context, Settings settings) {
    if (infusionRegimeData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.schedule, size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Enter patient details and tap Calculate',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final data = infusionRegimeData!;
    final isMobile = MediaQuery.of(context).size.width < _kBreakpointWide;
    const double sectionGap = 8;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildPatientChips(context),
          const SizedBox(height: sectionGap),
          _buildDashboardCards(context, data, isMobile),
          const SizedBox(height: sectionGap),
          Expanded(
            flex: 3,
            child: _buildChartSection(context),
          ),
          const SizedBox(height: sectionGap),
          Expanded(
            flex: 2,
            child: _buildTableSection(context, data, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientChips(BuildContext context) {
    final int age = int.tryParse(ageController.text) ?? 0;
    final isMale = !sexController.val;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: Icon(isMale ? Icons.male : Icons.female, size: 18,
              color: isMale ? Colors.blue : Colors.pink),
          label: Text(isMale ? 'Male' : 'Female',
              style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.calendar_month, size: 18),
          label: Text('$age y', style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.straighten, size: 18),
          label: Text('${heightController.text} cm',
              style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.monitor_weight, size: 18),
          label: Text('${weightController.text} kg',
              style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: Icon(selectedDrug?.icon ?? Symbols.medication, size: 18,
              color: selectedDrug?.getColor(context)),
          label: Text(selectedDrug?.displayWithConcentration ?? 'Drug',
              style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.model_training, size: 18),
          label: Text(
            (tciModelController.selection is Model
                ? (tciModelController.selection as Model).toString()
                : 'Model'),
            style: const TextStyle(fontSize: 13),
          ),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: Icon(getModelForDrug(selectedDrug).target.icon, size: 18),
          label: Text(
            '${targetController.text} ${selectedDrug?.targetUnit.displayName ?? "\u03BCg/mL"}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          visualDensity: VisualDensity.compact,
          backgroundColor: Theme.of(context)
              .colorScheme.primaryContainer.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _buildDashboardCards(
      BuildContext context, InfusionRegimeData data, bool isMobile) {
    final theme = Theme.of(context);
    final bolusVal = data.totalBolus < 10
        ? data.totalBolus.toStringAsFixed(1)
        : data.totalBolus.toStringAsFixed(0);
    final maxRate = data.maxInfusionRate;
    final maxRateStr = maxRate >= 10
        ? maxRate.toStringAsFixed(0)
        : maxRate.toStringAsFixed(1);

    return Row(
      children: [
        _buildStatCard(context, 'Bolus', '$bolusVal mL',
            Icons.medication_liquid, theme.colorScheme.primary, isMobile),
        const SizedBox(width: 8),
        _buildStatCard(context, 'Max Rate', '$maxRateStr mL/hr',
            Icons.speed, theme.colorScheme.tertiary, isMobile),
        const SizedBox(width: 8),
        _buildStatCard(context, 'Total', '${data.totalVolume.toStringAsFixed(1)} mL',
            Icons.water_drop, theme.colorScheme.secondary, isMobile),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final data = infusionRegimeData!;
    final isMobile = MediaQuery.of(context).size.width < _kBreakpointWide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Rate (mL/hr)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: InfusionRateChart(
            data: data,
            startTime: _startTime,
          ),
        ),
      ],
    );
  }

  Widget _buildTableSection(
      BuildContext context, InfusionRegimeData data, Settings settings) {
    return _buildRealtimeTable(context, data, settings);
  }

  Widget _buildStatCard(
    BuildContext context, String label, String value,
    IconData icon, Color accentColor, bool isMobile,
  ) {
    return Expanded(
      child: Card(
        elevation: 1, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12, horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: isMobile ? 18 : 22, color: accentColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: isMobile ? 10 : 11,
                color: Theme.of(context).colorScheme.outline),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(
                fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w700, color: accentColor))),
          ]),
        ),
      ),
    );
  }

  Widget _buildRealtimeTable(
      BuildContext context, InfusionRegimeData data, Settings settings) {
    return DosageDataTable(
      data: data,
      maxVisibleRows: MediaQuery.of(context).size.width < _kBreakpointWide ? 5 : 8,
      selectedRowIndex: settings.selectedDosageTableRow,
      onRowTap: (index) {
        if (settings.selectedDosageTableRow == index) {
          settings.selectedDosageTableRow = null;
        } else {
          settings.selectedDosageTableRow = index;
        }
      },
      scrollController: tableScrollController,
      startTime: _startTime,
    );
  }

  // ── Start Time ──────────────────────────────────────────────

  Widget _buildStartTimeField(BuildContext context) {
    final displayText = _format12Hour(_startTime);

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _startTime,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _startTime = picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: _kFieldHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 20,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(displayText, style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }

  // ── Reset Button ────────────────────────────────────────────

  Widget _buildResetButton(BuildContext context) {
    return Container(
      width: _kFieldHeight,
      height: _kFieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1.0,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          await HapticFeedback.mediumImpact();
          reset(toDefault: true);
        },
        child: const Icon(Icons.restart_alt_outlined, size: 24),
      ),
    );
  }

  // ── Drug Selector ───────────────────────────────────────────

  Widget _buildDrugSelector(BuildContext context, Settings settings) {
    final currentModel = tciModelController.selection is Model
        ? tciModelController.selection as Model : null;
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;

    final hasValidationError = currentModel != null &&
        tciModelController.hasValidationError(sex: sex, weight: weight, height: height, age: age);

    final drugNames = [
      'Propofol', 'Remifentanil', 'Dexmedetomidine', 'Remimazolam',
      AppLocalizations.of(context)!.selectDrug,
    ];
    final textStyle = Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final dynamicWidth = TextMeasurement.calculateDrugSelectorWidth(
        context: context, drugNames: drugNames, textStyle: textStyle);

    return SizedBox(
      width: dynamicWidth,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            enabled: true,
            readOnly: true,
            controller: TextEditingController(
              text: selectedDrug?.toLocalizedString(context) ??
                  AppLocalizations.of(context)!.selectDrug,
            ),
            style: TextStyle(
              color: hasValidationError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              errorText: null,
              errorStyle: const TextStyle(fontSize: 0, height: 0),
              prefixIcon: Icon(
                selectedDrug?.icon ?? Symbols.graph_4,
                color: hasValidationError
                    ? Theme.of(context).colorScheme.error
                    : selectedDrug?.getColor(context) ?? Theme.of(context).colorScheme.primary,
              ),
              labelText: AppLocalizations.of(context)!.drug,
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
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
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
                tciModelController.showModelSelector(
                  context: context,
                  inAdultView: true,
                  sexController: sexController,
                  ageController: ageController,
                  heightController: heightController,
                  weightController: weightController,
                  targetController: targetController,
                  durationController: durationController,
                  isTCIScreen: true,
                  currentDrug: selectedDrug,
                  onModelSelected: (model) {
                    setState(() {
                      tciModelController.selection = model;
                      settings.tciModel = model;
                      final drugTarget = settings.getTciDrugTarget(selectedDrug);
                      final targetProps = model.getTargetProperties(selectedDrug);
                      targetController.text = drugTarget?.toString() ?? targetProps.defaultValue.toString();
                    });
                    calculate();
                  },
                  onDrugSelected: (drug) {
                    if (selectedDrug != null) {
                      final currentTarget = double.tryParse(targetController.text);
                      if (currentTarget != null) {
                        settings.setTciDrugTarget(selectedDrug, currentTarget);
                      }
                    }
                    Model requiredModel =
                        drug.isDexmedetomidine ? Model.Hannivoort : Model.Eleveld;
                    setState(() {
                      selectedDrug = drug;
                      tciModelController.selection = requiredModel;
                      settings.tciDrug = drug;
                      settings.tciModel = requiredModel;
                      final drugTarget = settings.getTciDrugTarget(drug);
                      final targetProps = requiredModel.getTargetProperties(drug);
                      targetController.text = drugTarget?.toString() ?? targetProps.defaultValue.toString();
                    });
                    calculate();
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
  void dispose() {
    super.dispose();
  }
}

// ── Infusion Rate Chart ────────────────────────────────────────

class InfusionRateChart extends StatefulWidget {
  final InfusionRegimeData data;
  final TimeOfDay? startTime;

  const InfusionRateChart({super.key, required this.data, this.startTime});

  @override
  State<InfusionRateChart> createState() => _InfusionRateChartState();
}

class _InfusionRateChartState extends State<InfusionRateChart> {
  int? _hoveredIndex;

  String _formatTooltipTime(int index) {
    final row = widget.data.rows[index];
    if (widget.startTime != null) {
      final elapsed = row.time.inMinutes;
      final totalMins = widget.startTime!.hour * 60 + widget.startTime!.minute + elapsed;
      final h = totalMins ~/ 60 % 24;
      final m = totalMins % 60;
      final p = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:${m.toString().padLeft(2, '0')} $p';
    }
    return row.timeString;
  }

  String _formatRate(double rate) {
    return rate >= 10 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(1);
  }

  int? _hitTest(Offset localPos, double leftPad, double chartW, int n) {
    if (n <= 1) return null;
    for (int i = 0; i < n; i++) {
      final x = leftPad + chartW * i / (n - 1);
      if ((localPos.dx - x).abs() <= 12) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final rates = widget.data.rows.map((r) => r.infusionRate).toList();
    final maxRate = rates.reduce((a, b) => a > b ? a : b);
    const leftPad = 40.0, rightPad = 12.0, topPad = 8.0, bottomPad = 20.0;

    final tooltipText = _hoveredIndex != null
        ? '${_formatTooltipTime(_hoveredIndex!)}  |  ${_formatRate(rates[_hoveredIndex!])} mL/hr'
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) {
          final size = context.size;
          if (size == null) return;
          final chartW = (size.width - leftPad - rightPad).clamp(0.0, double.infinity);
          final hit = _hitTest(event.localPosition, leftPad, chartW, rates.length);
          if (hit != _hoveredIndex) setState(() => _hoveredIndex = hit);
        },
        onExit: (_) { if (_hoveredIndex != null) setState(() => _hoveredIndex = null); },
        child: GestureDetector(
          onTapDown: (details) {
            final size = context.size;
            if (size == null) return;
            final chartW = (size.width - leftPad - rightPad).clamp(0.0, double.infinity);
            final hit = _hitTest(details.localPosition, leftPad, chartW, rates.length);
            if (hit != null) setState(() => _hoveredIndex = _hoveredIndex == hit ? null : hit);
          },
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _ChartPainter(
                  data: widget.data, maxRate: maxRate,
                  lineColor: theme.colorScheme.primary,
                  fillColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  labelColor: theme.colorScheme.outline,
                  hoveredIndex: _hoveredIndex,
                  leftPad: leftPad, rightPad: rightPad,
                  topPad: topPad, bottomPad: bottomPad,
                ),
              ),
              if (tooltipText != null)
                Positioned(top: 6, left: 0, right: 0,
                  child: Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tooltipText, style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onInverseSurface,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final InfusionRegimeData data;
  final double maxRate;
  final Color lineColor, fillColor, gridColor, labelColor;
  final int? hoveredIndex;
  final double leftPad, rightPad, topPad, bottomPad;

  _ChartPainter({
    required this.data, required this.maxRate,
    required this.lineColor, required this.fillColor,
    required this.gridColor, required this.labelColor,
    this.hoveredIndex,
    required this.leftPad, required this.rightPad,
    required this.topPad, required this.bottomPad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.rows.isEmpty || maxRate <= 0) return;
    final rates = data.rows.map((r) => r.infusionRate).toList();
    final n = rates.length;
    final chartW = math.max(0, size.width - leftPad - rightPad);
    final chartH = math.max(0, size.height - topPad - bottomPad);

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    final labelStyle = TextStyle(color: labelColor, fontSize: 9);
    for (int i = 0; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 3);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
      final val = (maxRate * i / 3);
      final label = val >= 10 ? val.toStringAsFixed(0) : val.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 4);
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = leftPad + chartW * i / (n - 1);
      final y = topPad + chartH * (1 - rates[i] / maxRate);
      points.add(Offset(x, y));
    }

    if (points.length >= 2) {
      final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) fillPath.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points.last.dx, topPad + chartH);
      fillPath.lineTo(points.first.dx, topPad + chartH);
      fillPath.close();
      canvas.drawPath(fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);
    }

    if (points.length >= 2) {
      final linePaint = Paint()..color = lineColor..strokeWidth = 2
        ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) linePath.lineTo(points[i].dx, points[i].dy);
      canvas.drawPath(linePath, linePaint);
    }

    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < points.length) {
      final hp = points[hoveredIndex!];
      canvas.drawLine(Offset(hp.dx, topPad), Offset(hp.dx, topPad + chartH),
          Paint()..color = lineColor.withValues(alpha: 0.3)..strokeWidth = 1..style = PaintingStyle.stroke);
      canvas.drawCircle(hp, 5, Paint()..color = lineColor..style = PaintingStyle.fill);
      canvas.drawCircle(hp, 5, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter o) =>
      data != o.data || maxRate != o.maxRate || hoveredIndex != o.hoveredIndex;
}
