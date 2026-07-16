import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Selector;
import 'package:propofol_dreams_app/l10n/generated/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../utils/responsive_helper.dart';
import '../utils/intents.dart';

import 'package:propofol_dreams_app/models/infusion_regime_data.dart';
import 'package:propofol_dreams_app/providers/settings.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/target.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;

import '../config/design_tokens.dart';
import '../constants.dart';
import '../components/infusion_regime_table.dart';
import '../components/pk_field.dart';
import '../components/switch_field.dart';
import '../components/selector.dart';
import '../components/infusion_rate_chart.dart';
import '../components/collapsible_input_section.dart';

class TCIScreenNew extends StatefulWidget {
  const TCIScreenNew({super.key});

  static Model modelForDrug(Drug? drug) {
    if (drug == null) return Model.Eleveld;
    if (drug.isDexmedetomidine) return Model.Hannivoort;
    if (drug.isRemimazolam) return Model.Schnider;
    return Model.Eleveld;
  }

  @override
  State<TCIScreenNew> createState() => _TCIScreenNewState();
}

class _TCIScreenNewState extends State<TCIScreenNew> {
  Drug? _selectedDrug;
  bool _sexValue = false;
  TimeOfDay _startTime = TimeOfDay.now();
  int? _syncedRowIndex;
  TimeOfDay? _syncedClockTime;
  bool _isTableSynced = false;

  static final _uniqueDrugs = () {
    final seen = <String>{};
    return Drug.values.where((d) => seen.add(d.displayName)).toList();
  }();
  final ScrollController tableScrollController = ScrollController();

  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final targetController = TextEditingController();

  InfusionRegimeData? infusionRegimeData;
  bool _isCalculating = false;
  static const int _fixedDurationMinutes = 240; // 4 hours

  Timer timer = Timer(Duration.zero, () {});
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (settings.dosageTableScrollPosition != null &&
          tableScrollController.hasClients) {
        tableScrollController.jumpTo(settings.dosageTableScrollPosition!);
      }
    });

    tableScrollController.addListener(() {
      if (tableScrollController.hasClients) {
        final settings = context.read<Settings>();
        settings.dosageTableScrollPosition = tableScrollController.offset;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculate();
    });
  }

  void _setControllersFromSettings(Settings settings) {
    _selectedDrug = _uniqueDrugs.firstWhere(
      (d) => d.displayName == settings.tciDrug.displayName,
      orElse: () => _uniqueDrugs.first,
    );
    _sexValue = settings.tciSex == Sex.Female;
    ageController.text = settings.tciAge?.toString() ?? '40';
    heightController.text = settings.tciHeight?.toString() ?? '170';
    weightController.text = settings.tciWeight?.toString() ?? '70';
    final drugTarget = settings.getTciDrugTarget(_selectedDrug);
    final model = _getModelForDrug(_selectedDrug);
    final targetProps = model.getTargetProperties(_selectedDrug);
    targetController.text = drugTarget?.toStringAsFixed(1) ??
        targetProps.defaultValue.toStringAsFixed(1);
  }

  void _saveToSettings() {
    if (!mounted) return;
    final settings = Provider.of<Settings>(context, listen: false);
    final age = int.tryParse(ageController.text);
    final height = int.tryParse(heightController.text);
    final weight = int.tryParse(weightController.text);
    final target = double.tryParse(targetController.text);
    final sex = _sexValue ? Sex.Female : Sex.Male;

    if (_selectedDrug != null) {
      settings.tciDrug =
          settings.getCurrentDrugVariant(_selectedDrug!.displayName);
    }
    settings.tciSex = sex;
    settings.tciAge = age;
    settings.tciHeight = height;
    settings.tciWeight = weight;
    settings.setTciDrugTarget(_selectedDrug, target);
  }

  Model _getModelForDrug(Drug? drug) => TCIScreenNew.modelForDrug(drug);

  void calculate() {
    if (_isCalculating) return;
    _isCalculating = true;

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveToSettings();
      });

      final settings = Provider.of<Settings>(context, listen: false);
      final resolvedDrug = _selectedDrug != null
          ? settings.getCurrentDrugVariant(_selectedDrug!.displayName)
          : null;
      final finalAge = int.tryParse(ageController.text) ?? 40;
      final finalHeight = int.tryParse(heightController.text) ?? 170;
      final finalWeight = int.tryParse(weightController.text) ?? 70;
      final finalTarget = double.tryParse(targetController.text) ?? 3.0;
      final sex = _sexValue ? Sex.Female : Sex.Male;

      final selectedModel = _getModelForDrug(resolvedDrug);

      final patient = Patient(
        weight: finalWeight,
        age: finalAge,
        height: finalHeight,
        sex: sex,
      );

      final pumpConcentration = resolvedDrug?.concentration ??
          settings.getDrugConcentration(Drug.propofol10mg);
      final pump = Pump(
        timeStep: Duration(seconds: settings.time_step),
        concentration: pumpConcentration,
        maxPumpRate: settings.max_pump_rate,
        target: finalTarget,
        duration: Duration(minutes: _fixedDurationMinutes),
        drug: resolvedDrug,
      );

      if (selectedModel != Model.None &&
          selectedModel.isRunnable(
            age: finalAge,
            height: finalHeight,
            weight: finalWeight,
            target: finalTarget,
            duration: _fixedDurationMinutes,
          )) {
        final simulation = PDSim.Simulation(
          model: selectedModel,
          patient: patient,
          pump: pump,
        );

        final results = simulation.estimate;

        setState(() {
          _isTableSynced = false;
          _syncedRowIndex = null;
          _syncedClockTime = null;
          infusionRegimeData = InfusionRegimeData.fromSimulation(
            times: results.times,
            pumpInfs: results.pumpInfs,
            cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
            density: 10,
            totalDuration: Duration(minutes: _fixedDurationMinutes),
            isEffectSiteTargeting: selectedModel.target == Target.EffectSite,
            drugConcentrationMgMl: pumpConcentration,
          );
        });

        final conc = pumpConcentration;
        final concStr = conc == conc.roundToDouble()
            ? conc.toStringAsFixed(0)
            : conc.toStringAsFixed(1);
        final unit = resolvedDrug?.concentrationUnit.displayName ?? 'mg/mL';
        settings.statusBarInfo =
            'Model: ${selectedModel} · Drug: ${resolvedDrug?.displayName ?? '—'} $concStr $unit · Pump: ${settings.max_pump_rate} mL/hr';
      } else {
        setState(() {
          infusionRegimeData = null;
        });
      }
    } catch (e) {
      debugPrint('TCI calculation error: $e');
    } finally {
      _isCalculating = false;
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);

    _sexValue = toDefault ? false : settings.tciSex == Sex.Female;
    ageController.text =
        toDefault ? '40' : (settings.tciAge?.toString() ?? '40');
    heightController.text =
        toDefault ? '170' : (settings.tciHeight?.toString() ?? '170');
    weightController.text =
        toDefault ? '70' : (settings.tciWeight?.toString() ?? '70');

    final model = _getModelForDrug(_selectedDrug);
    final targetProps = model.getTargetProperties(_selectedDrug);
    targetController.text = toDefault
        ? targetProps.defaultValue.toStringAsFixed(1)
        : (settings.getTciDrugTarget(_selectedDrug)?.toStringAsFixed(1) ??
            targetProps.defaultValue.toStringAsFixed(1));

    calculate();
  }

  List<String> _validate(Settings settings) {
    final errors = <String>[];
    final model = _getModelForDrug(_selectedDrug);
    final age = int.tryParse(ageController.text);
    final height = int.tryParse(heightController.text);
    final weight = int.tryParse(weightController.text);
    final target = double.tryParse(targetController.text);

    if (age != null && (age < model.minAge || age > model.maxAge)) {
      errors.add('Age ${model.minAge}-${model.maxAge}');
    }
    if (height != null &&
        (height < model.minHeight || height > model.maxHeight)) {
      errors.add('Height ${model.minHeight}-${model.maxHeight} cm');
    }
    if (weight != null &&
        (weight < model.minWeight || weight > model.maxWeight)) {
      errors.add('Weight ${model.minWeight}-${model.maxWeight} kg');
    }
    if (target != null) {
      final props = model.getTargetProperties(_selectedDrug);
      if (target < props.min || target > props.max) {
        errors.add('Target ${props.min}-${props.max}');
      }
    }
    return errors;
  }

  @override
  void dispose() {
    timer.cancel();
    tableScrollController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    targetController.dispose();
    super.dispose();
  }

  // ── Input Panel ──────────────────────────────────────────────

  Widget _buildErrorPanel(List<String> errors) {
    return SizedBox(
      height: 48,
      child: errors.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kSp16, vertical: 8),
              child: Text(
                errors.first,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
    );
  }

  Model get _currentModel => _getModelForDrug(_selectedDrug);

  Widget _buildInputFields(Settings settings) {
    final theme = Theme.of(context);
    final errors = _validate(settings);
    final model = _currentModel;
    final age = int.tryParse(ageController.text);
    final heightEnabled = model.target != Target.Plasma;
    final sexEnabled = model.target != Target.Plasma;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildErrorPanel(errors),
        const SizedBox(height: kSp12),
        // Drug selector + Reset button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              IntrinsicWidth(
                child: Selector<Drug>(
                  selectedItem: _selectedDrug,
                  items: _uniqueDrugs,
                  itemLabelBuilder: (d) => d.displayName,
                  itemIconBuilder: (d) => d.icon,
                  prefixIcon: _selectedDrug?.icon,
                  labelText: AppLocalizations.of(context)!.drug,
                  onItemSelected: (drug) {
                    final actualDrug =
                        settings.getCurrentDrugVariant(drug.displayName);
                    // Save current target before switching
                    if (_selectedDrug != null) {
                      final currentTarget =
                          double.tryParse(targetController.text);
                      if (currentTarget != null) {
                        settings.setTciDrugTarget(
                          settings.getCurrentDrugVariant(
                              _selectedDrug!.displayName),
                          currentTarget,
                        );
                      }
                    }
                    setState(() {
                      _selectedDrug = drug;
                      settings.tciDrug = actualDrug;
                      final newTarget = settings.getTciDrugTarget(actualDrug);
                      final props = model.getTargetProperties(actualDrug);
                      targetController.text = newTarget?.toStringAsFixed(1) ??
                          props.defaultValue.toStringAsFixed(1);
                    });
                    calculate();
                  },
                ),
              ),
              const Spacer(),
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
        if (_syncedRowIndex != null) ...[
          _buildSyncSection(),
          const SizedBox(height: kSp12),
        ],
        // Sex + Age
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: SwitchField(
                  labelText: AppLocalizations.of(context)!.sex,
                  prefixIcon: _sexValue
                      ? (age != null && age < 17 ? Icons.girl : Icons.woman)
                      : (age != null && age < 17 ? Icons.boy : Icons.man),
                  value: _sexValue,
                  switchLabels: {
                    true: Sex.Female.toLocalizedString(context),
                    false: Sex.Male.toLocalizedString(context),
                  },
                  onChanged: (v) {
                    setState(() => _sexValue = v);
                    calculate();
                  },
                  enabled: sexEnabled,
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
                  range: [model.minAge, model.maxAge],
                  onChanged: () {
                    timer.cancel();
                    timer = Timer(_debounceDelay, calculate);
                  },
                  enabled: true,
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Height + Weight
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: PKField(
                  labelText: AppLocalizations.of(context)!.height,
                  prefixIcon: Icons.straighten,
                  interval: 1.0,
                  fractionDigits: 0,
                  controller: heightController,
                  range: [model.minHeight, model.maxHeight],
                  onChanged: () {
                    timer.cancel();
                    timer = Timer(_debounceDelay, calculate);
                  },
                  enabled: heightEnabled,
                  hasError: errors.isNotEmpty,
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: PKField(
                  labelText: AppLocalizations.of(context)!.weight,
                  prefixIcon: Icons.monitor_weight_outlined,
                  interval: 1.0,
                  fractionDigits: 0,
                  controller: weightController,
                  range: [model.minWeight, model.maxWeight],
                  onChanged: () {
                    timer.cancel();
                    timer = Timer(_debounceDelay, calculate);
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
        // Target + Start time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSp16),
          child: Row(
            children: [
              Expanded(
                child: PKField(
                  labelText: model.getTargetLabel(context, _selectedDrug),
                  prefixIcon: model.target.icon,
                  interval: model.getTargetProperties(_selectedDrug).interval,
                  fractionDigits: 1,
                  controller: targetController,
                  range: [
                    model.getTargetProperties(_selectedDrug).min,
                    model.getTargetProperties(_selectedDrug).max,
                  ],
                  onChanged: () {
                    timer.cancel();
                    timer = Timer(_debounceDelay, calculate);
                  },
                  hasError: errors.isNotEmpty,
                ),
              ),
              const SizedBox(width: kSp12),
              Expanded(
                child: _buildStartTimeField(theme),
              ),
            ],
          ),
        ),
        const SizedBox(height: kSp12),
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
      collapsedChipRows: _buildCollapsedChips(settings),
    );
  }

  List<List<Widget>> _buildCollapsedChips(Settings settings) {
    final errors = _validate(settings);
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
        avatar: Icon(hasError ? Icons.error_outline : icon,
            size: 16, color: chipColor),
        label: Text(isEmpty ? emptyLabel : displayValue,
            style: TextStyle(fontSize: 11, color: chipColor)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: bgColor,
      );
    }

    return [
      [
        Chip(
          avatar: Icon(_selectedDrug?.icon ?? Icons.medication, size: 16),
          label: Text(_selectedDrug?.displayName ?? 'Drug',
              style: const TextStyle(fontSize: 11)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        chip(
          displayValue: '${targetText} μg/mL',
          emptyLabel: 'Target',
          icon: Icons.psychology,
          isEmpty: targetText.isEmpty,
          hasError: errors.any((e) => e.startsWith('Target')),
        ),
      ],
      [
        chip(
          displayValue: '${ageText}y',
          emptyLabel: 'Age',
          icon: Icons.calendar_month,
          isEmpty: ageText.isEmpty,
          hasError: errors.any((e) => e.startsWith('Age')),
        ),
        Chip(
          avatar: Icon(_sexValue ? Icons.female : Icons.male, size: 16),
          label:
              Text(_sexValue ? 'F' : 'M', style: const TextStyle(fontSize: 11)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
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
      ],
    ];
  }

  // ── Start Time ──────────────────────────────────────────────

  Widget _buildStartTimeField(ThemeData theme) {
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
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
          color: theme.colorScheme.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: kSp12),
        child: Row(
          children: [
            Icon(Icons.access_time,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: kSp8),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _startTime = TimeOfDay.now());
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Now', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  String _format12Hour(TimeOfDay time) {
    final p = time.period == DayPeriod.pm ? 'PM' : 'AM';
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$h:${time.minute.toString().padLeft(2, '0')} $p';
  }

  Widget _buildSyncSection() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSp16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(kRadius),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _syncedClockTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => _syncedClockTime = picked);
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: theme.colorScheme.outline),
                  color: theme.colorScheme.onPrimary,
                ),
                padding: const EdgeInsets.symmetric(horizontal: kSp12),
                alignment: Alignment.centerLeft,
                child: Text(
                  _syncedClockTime?.format(context) ?? 'Set clock time',
                  style: TextStyle(
                    fontSize: 16,
                    color: _syncedClockTime != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: kSp8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadius),
                ),
              ),
              onPressed: _syncedRowIndex != null && _syncedClockTime != null
                  ? () {
                      setState(() => _isTableSynced = true);
                    }
                  : null,
              child: const Text('Sync'),
            ),
          ),
          if (_isTableSynced) ...[
            const SizedBox(width: kSp8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onPrimary,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isTableSynced = false;
                    _syncedRowIndex = null;
                    _syncedClockTime = null;
                  });
                },
                child: const Text('Clear'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Results Area ─────────────────────────────────────────────

  Widget _buildPatientChips() {
    final age = int.tryParse(ageController.text) ?? 0;
    final isMale = !_sexValue;
    final model = _currentModel;
    final resolvedDrug = _selectedDrug != null
        ? context
            .read<Settings>()
            .getCurrentDrugVariant(_selectedDrug!.displayName)
        : null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: Icon(isMale ? Icons.male : Icons.female,
              size: 18, color: isMale ? Colors.blue : Colors.pink),
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
          avatar: Icon(resolvedDrug?.icon ?? Symbols.medication,
              size: 18, color: resolvedDrug?.getColor(context)),
          label: Text(resolvedDrug?.displayWithConcentration ?? 'Drug',
              style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.model_training, size: 18),
          label: Text(model.toString(), style: const TextStyle(fontSize: 13)),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: Icon(model.target.icon, size: 18),
          label: Text(
            '${targetController.text} ${_selectedDrug?.targetUnit.displayName ?? '\u03BCg/mL'}',
            style: const TextStyle(fontSize: 13),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildDashboardCards(InfusionRegimeData data, {bool compact = false}) {
    final theme = Theme.of(context);
    final bolusVal = data.totalBolus < 10
        ? data.totalBolus.toStringAsFixed(1)
        : data.totalBolus.toStringAsFixed(0);
    final maxRate = data.maxInfusionRate;
    final maxRateStr =
        maxRate >= 10 ? maxRate.toStringAsFixed(0) : maxRate.toStringAsFixed(1);

    return Row(
      children: [
        _buildStatCard('Bolus', '$bolusVal mL', Icons.medication_liquid,
            theme.colorScheme.primary,
            compact: compact),
        const SizedBox(width: kSp8),
        _buildStatCard('Max Rate', '$maxRateStr mL/hr', Icons.speed,
            theme.colorScheme.tertiary,
            compact: compact),
        const SizedBox(width: kSp8),
        _buildStatCard('Total', '${data.totalVolume.toStringAsFixed(1)} mL',
            Icons.water_drop, theme.colorScheme.secondary,
            compact: compact),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color accentColor,
      {bool compact = false}) {
    return Expanded(
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: compact ? 8 : 10, horizontal: compact ? 8 : 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: compact ? 14 : 18, color: accentColor),
            const SizedBox(height: kSp4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Theme.of(context).colorScheme.outline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: kSp2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: accentColor)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter patient details to see results',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContextSection(InfusionRegimeData data) {
    Widget chartCard() {
      return Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        child: Padding(
          padding: const EdgeInsets.all(kSp12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate (mL/hr)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: kSp8),
              Expanded(
                child: InfusionRateChart(
                  data: data,
                  startTime: _startTime,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget patientCard() {
      return Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        child: Padding(
          padding: const EdgeInsets.all(kSp12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient / model',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: kSp8),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildPatientChips(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            key: const ValueKey('tci-new-desktop-context-stacked'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chartCard()),
              const SizedBox(height: kSp12),
              Expanded(child: patientCard()),
            ],
          );
        }

        return Row(
          key: const ValueKey('tci-new-desktop-context-split'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: chartCard()),
            const SizedBox(width: kSp12),
            Expanded(flex: 2, child: patientCard()),
          ],
        );
      },
    );
  }

  Widget _buildTableSection(
    InfusionRegimeData data,
    Settings settings, {
    required int maxVisibleRows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isTableSynced && data.rows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: ((_syncedRowIndex ?? 0) + 1) / data.rows.length,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
        DosageDataTable(
          data: data,
          maxVisibleRows: maxVisibleRows,
          selectedRowIndex: settings.selectedDosageTableRow,
          onRowTap: (index) {
            setState(() => _syncedRowIndex = index);
          },
          scrollController: tableScrollController,
          startTime: _startTime,
          syncedRowIndex: _syncedRowIndex,
          isSynced: _isTableSynced,
        ),
      ],
    );
  }

  Widget _buildResults(InfusionRegimeData data, Settings settings,
      {bool showChips = true, bool showChart = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showChips) ...[
          _buildPatientChips(),
          const SizedBox(height: kSp12),
        ],
        _buildDashboardCards(data,
            compact: ResponsiveHelper.shouldUseMobileLayout(context)),
        const SizedBox(height: kSp12),
        if (showChart) ...[
          Padding(
            padding: const EdgeInsets.only(left: kSp4, bottom: kSp4),
            child: Text(
              'Rate (mL/hr)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(
            height: 250,
            child: InfusionRateChart(
              data: data,
              startTime: _startTime,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_isTableSynced && data.rows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              value: ((_syncedRowIndex ?? 0) + 1) / data.rows.length,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
        DosageDataTable(
          data: data,
          maxVisibleRows:
              ResponsiveHelper.shouldUseMobileLayout(context) ? 99 : 8,
          selectedRowIndex: settings.selectedDosageTableRow,
          onRowTap: (index) {
            setState(() => _syncedRowIndex = index);
          },
          scrollController: tableScrollController,
          startTime: _startTime,
          syncedRowIndex: _syncedRowIndex,
          isSynced: _isTableSynced,
        ),
      ],
    );
  }

  // ── Layouts ──────────────────────────────────────────────────

  Widget _buildDesktopResults(InfusionRegimeData data, Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDashboardCards(data),
        const SizedBox(height: kSp12),
        SizedBox(
          height: 250,
          child: _buildDesktopContextSection(data),
        ),
        const SizedBox(height: kSp12),
        Expanded(
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadius)),
            child: Padding(
              padding: const EdgeInsets.all(kSp12),
              child: SingleChildScrollView(
                child: _buildTableSection(data, settings, maxVisibleRows: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Settings settings) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalSidesPaddingPixel,
          right: horizontalSidesPaddingPixel,
          top: kSp12,
          bottom: MediaQuery.of(context).viewInsets.bottom + kSp12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Row(
              key: const ValueKey('tci-new-desktop-workstation'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  key: const ValueKey('tci-new-desktop-results-area'),
                  child: infusionRegimeData != null
                      ? _buildDesktopResults(infusionRegimeData!, settings)
                      : _buildEmptyResultsState(),
                ),
                const SizedBox(width: kSp12),
                SizedBox(
                  key: const ValueKey('tci-new-desktop-input-rail'),
                  width: 393,
                  child: _buildInputPanel(settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileResults(InfusionRegimeData data, Settings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDashboardCards(data, compact: true),
        const SizedBox(height: kSp12),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius)),
          child: Padding(
            padding: const EdgeInsets.all(kSp8),
            child: _buildTableSection(data, settings, maxVisibleRows: 99),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Settings settings) {
    return Scaffold(
      key: const ValueKey('tci-new-mobile-flow'),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            key: const ValueKey('tci-new-mobile-results-area'),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: horizontalSidesPaddingPixel,
                    right: horizontalSidesPaddingPixel,
                    top: kSp12,
                    bottom: kSp12,
                  ),
                  child: infusionRegimeData != null
                      ? _buildMobileResults(infusionRegimeData!, settings)
                      : SizedBox(
                          height: constraints.maxHeight - 100,
                          child: _buildEmptyResultsState(),
                        ),
                );
              },
            ),
          ),
          SafeArea(
            key: const ValueKey('tci-new-mobile-input-sheet'),
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
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): CalculateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          CalculateIntent: CallbackAction<CalculateIntent>(
            onInvoke: (intent) {
              calculate();
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

    final settings = context.watch<Settings>();

    if (isDesktopLayout) {
      return Material(
        child: _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings)),
      );
    }
    if (isTabletLayout) {
      return Material(
        child: _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings)),
      );
    }

    return _buildMobileLayout(settings);
  }
}
