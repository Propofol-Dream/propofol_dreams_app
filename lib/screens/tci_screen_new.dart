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
import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as pd_sim;

import '../components/infusion_regime_table.dart';
import '../components/collapsible_input_card.dart';
import '../components/input_summary_display.dart';
import '../utils/text_measurement.dart';

import 'package:propofol_dreams_app/controllers/PDTextField.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchController.dart';
import 'package:propofol_dreams_app/controllers/PDSwitchField.dart';
import 'package:propofol_dreams_app/controllers/PDAdvancedSegmentedController.dart';

class TCIScreen extends StatefulWidget {
  const TCIScreen({super.key});

  @override
  State<TCIScreen> createState() => _TCIScreenState();
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

class _TCIScreenState extends State<TCIScreen> {
  Drug? selectedDrug; // Track selected drug for concentration
  final PDAdvancedSegmentedController tciModelController =
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

  InfusionRegimeData? infusionRegimeData;
  String result = '';
  String emptyResult = '';
  bool _isCalculating = false;

  // Collapsible card state
  final GlobalKey<State<CollapsibleInputCard>> _inputCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
    
    // Restore table scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (settings.dosageTableScrollPosition != null && tableScrollController.hasClients) {
        tableScrollController.jumpTo(settings.dosageTableScrollPosition!);
      }
    });
    
    // Add scroll listener to save position
    tableScrollController.addListener(() {
      if (tableScrollController.hasClients) {
        final settings = context.read<Settings>();
        settings.dosageTableScrollPosition = tableScrollController.offset;
      }
    });

    modelOptions.addAll([
      Model.Eleveld,
      Model.Marsh,
      Model.Schnider,
      Model.Hannivoort,
      Model.Eleveld,
    ]);

    calculate();
  }

  void _setControllersFromSettings(Settings settings) {
    tableController.val = true; // Always keep table expanded

    // Use TCI model (separate from volume screen)
    tciModelController.selection = settings.tciModel;
    // Load selected drug from settings
    selectedDrug = settings.tciDrug;
    sexController.val = settings.tciSex == Sex.Female ? true : false;
    ageController.text = settings.tciAge?.toString() ?? '40';
    heightController.text = settings.tciHeight?.toString() ?? '170';
    weightController.text = settings.tciWeight?.toString() ?? '70';
    // Load drug-specific target value
    final drugTarget = settings.getTciDrugTarget(selectedDrug);
    final targetProps = tciModelController.selection.getTargetProperties(selectedDrug);
    targetController.text = drugTarget?.toString() ?? targetProps.defaultValue.toString();
    durationController.text = '255'; // Hardcoded to 4 hours and 15 minutes
  }

  void _saveToSettings() {
    if (!mounted) return;
    
    final settings = Provider.of<Settings>(context, listen: false);
    
    // Save current values to settings
    int? age = int.tryParse(ageController.text);
    int? height = int.tryParse(heightController.text);
    int? weight = int.tryParse(weightController.text);
    double? target = double.tryParse(targetController.text);
    Sex sex = sexController.val ? Sex.Female : Sex.Male;

    settings.tciSex = sex;
    settings.tciAge = age;
    settings.tciHeight = height;
    settings.tciWeight = weight;
    // Save to TCI-specific drug target
    settings.setTciDrugTarget(selectedDrug, target);
  }

  void calculate() {
    if (_isCalculating) return;
    setState(() => _isCalculating = true);
    
    try {
      // Defer settings updates to avoid build phase conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveToSettings();
      });

      DateTime start = DateTime.now();

      final settings = Provider.of<Settings>(context, listen: false);
      final finalAge = int.tryParse(ageController.text) ?? 40;
      final finalHeight = int.tryParse(heightController.text) ?? 170;
      final finalWeight = int.tryParse(weightController.text) ?? 70;
      final finalTarget = double.tryParse(targetController.text) ?? 3.0;
      final finalDuration = 255; // Hardcoded to 4 hours and 15 minutes
      final sex = sexController.val ? Sex.Female : Sex.Male;
      
      // Get current model
      final selectedModel = tciModelController.selection;

      // Create patient object
      final patient = Patient(
        weight: finalWeight, 
        age: finalAge, 
        height: finalHeight, 
        sex: sex
      );

      // Create pump configuration (matching the original API)
      final pump = Pump(
        timeStep: Duration(seconds: settings.time_step),
        concentration: selectedDrug?.concentration ?? settings.propofol_concentration,
        maxPumpRate: settings.max_pump_rate,
        target: finalTarget,
        duration: Duration(minutes: finalDuration),
        drug: selectedDrug,
      );

      // Only calculate if we have a valid model and all required parameters
      if (selectedModel != Model.None &&
          selectedModel.isRunnable(
            age: finalAge,
            height: finalHeight,
            weight: finalWeight,
            target: finalTarget,
            duration: finalDuration,
          )) {

        // Calculate infusion regime using the existing API
        final simulation = pd_sim.Simulation(
          model: selectedModel,
          patient: patient,
          pump: pump,
        );

        var results = simulation.estimate;
        
        setState(() {
          // Create infusion regime data for table display
          infusionRegimeData = InfusionRegimeData.fromSimulation(
            times: results.times,
            pumpInfs: results.pumpInfs,
            cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
            density: 10, // LEGACY parameter
            totalDuration: Duration(minutes: finalDuration),
            isEffectSiteTargeting: selectedModel.target == Target.EffectSite,
            drugConcentrationMgMl: selectedDrug?.concentration ?? 10.0,
          );
          _isCalculating = false;
        });
      } else {
        // Clear data if model is not runnable
        setState(() {
          infusionRegimeData = null;
          _isCalculating = false;
        });
      }

      DateTime end = DateTime.now();
      print('Calculation took: ${end.difference(start).inMilliseconds}ms');
      
    } catch (e) {
      print('Calculation error: $e');
      setState(() => _isCalculating = false);
    }
  }

  Model getModelForDrug(Drug? drug) {
    if (drug == null) return Model.Eleveld;
    
    if (drug.isDexmedetomidine) {
      return Model.Hannivoort;
    } else {
      return Model.Eleveld; // Default for propofol, remifentanil, remimazolam
    }
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);
    
    sexController.val = toDefault
        ? true
        : settings.tciSex == Sex.Female
            ? true
            : false;
    ageController.text = toDefault
        ? 40.toString()
        : settings.tciAge != null
            ? settings.tciAge.toString()
            : '';
    heightController.text = toDefault
        ? 170.toString()
        : settings.tciHeight != null
            ? settings.tciHeight.toString()
            : '';
    weightController.text = toDefault
        ? 70.toString()
        : settings.tciWeight != null
            ? settings.tciWeight.toString()
            : '';
    
    // Get current model and drug for drug-specific default
    final currentModel = tciModelController.selection is Model 
        ? tciModelController.selection as Model 
        : Model.Eleveld;
    final targetProps = currentModel.getTargetProperties(selectedDrug);
    
    targetController.text = toDefault
        ? targetProps.defaultValue.toString()
        : settings.getTciDrugTarget(selectedDrug)?.toString() ?? targetProps.defaultValue.toString();
    durationController.text = '255';

    calculate();
  }

  void _onCalculate() {
    calculate();
    // Note: Auto-collapse is handled by the CollapsibleInputCard itself
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    
    // Add age-based logic for girl/boy display
    final int age = int.tryParse(ageController.text) ?? 0;
    final bool isAdult = age >= 17;
    
    final bool heightTextFieldEnabled = (tciModelController.selection as Model).target != Target.Plasma;
    final bool sexSwitchControlEnabled = (tciModelController.selection as Model).target != Target.Plasma;
    final bool ageTextFieldEnabled = tciModelController.selection != Model.Marsh && 
                                selectedDrug?.isDexmedetomidine != true;

    final isMobile = MediaQuery.of(context).size.width < 840;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: isMobile 
          ? _buildMobileLayout(context, settings, isAdult, heightTextFieldEnabled, sexSwitchControlEnabled, ageTextFieldEnabled)
          : _buildDesktopLayout(context, settings, isAdult, heightTextFieldEnabled, sexSwitchControlEnabled, ageTextFieldEnabled),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Settings settings,
    bool isAdult,
    bool heightTextFieldEnabled,
    bool sexSwitchControlEnabled,
    bool ageTextFieldEnabled,
  ) {
    return Column(
      children: [
        // Collapsible Input Card
        CollapsibleInputCard(
          key: _inputCardKey,
          title: AppLocalizations.of(context)?.tci ?? 'TCI Calculator',
          expandedContent: _buildExpandedInputs(
            context,
            settings,
            isAdult,
            heightTextFieldEnabled,
            sexSwitchControlEnabled,
            ageTextFieldEnabled,
          ),
          collapsedSummary: _buildCollapsedSummary(context),
          onCalculate: _onCalculate,
          isCalculating: _isCalculating,
          calculateButtonText: 'Calculate', // Use plain string since 'calculate' key might not exist
          hasValidationError: _hasValidationErrors(),
          forceExpanded: _hasValidationErrors(),
        ),
        
        // Results Area
        Expanded(
          child: _buildResultsArea(context, settings),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Settings settings,
    bool isAdult,
    bool heightTextFieldEnabled,
    bool sexSwitchControlEnabled,
    bool ageTextFieldEnabled,
  ) {
    return Row(
      children: [
        // Left panel - Input card (fixed width)
        SizedBox(
          width: 400,
          child: Column(
            children: [
              CollapsibleInputCard(
                key: _inputCardKey,
                title: AppLocalizations.of(context)?.tci ?? 'TCI Calculator',
                expandedContent: _buildExpandedInputs(
                  context,
                  settings,
                  isAdult,
                  heightTextFieldEnabled,
                  sexSwitchControlEnabled,
                  ageTextFieldEnabled,
                ),
                collapsedSummary: _buildCollapsedSummary(context),
                onCalculate: _onCalculate,
                isCalculating: _isCalculating,
                calculateButtonText: 'Calculate', // Use plain string since 'calculate' key might not exist
                hasValidationError: _hasValidationErrors(),
                forceExpanded: _hasValidationErrors(),
                isInitiallyExpanded: true, // Keep expanded on desktop by default
              ),
              const Spacer(),
            ],
          ),
        ),
        
        // Right panel - Results (expandable)
        Expanded(
          child: _buildResultsArea(context, settings),
        ),
      ],
    );
  }

  Widget _buildExpandedInputs(
    BuildContext context,
    Settings settings,
    bool isAdult,
    bool heightTextFieldEnabled,
    bool sexSwitchControlEnabled,
    bool ageTextFieldEnabled,
  ) {
    const double UIWidth = 125;
    const double UIHeight = 56;

    return Column(
      children: [
        // Drug Selector Row
        Row(
          children: [
            Expanded(child: _buildDrugSelector(context, settings, UIHeight)),
            const SizedBox(width: 16),
            SizedBox(
              width: UIHeight,
              height: UIHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                ),
                onPressed: () async {
                  await HapticFeedback.mediumImpact();
                  reset(toDefault: true);
                },
                child: const Icon(Icons.restart_alt_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Sex and Age Row
        Row(
          children: [
            SizedBox(
              width: UIWidth,
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
                height: UIHeight,
                enabled: sexSwitchControlEnabled,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: UIWidth,
              child: PDTextField(
                prefixIcon: Icons.calendar_month,
                labelText: AppLocalizations.of(context)!.age,
                interval: 1.0,
                fractionDigits: 0,
                controller: ageController,
                range: [getModelForDrug(selectedDrug).minAge, getModelForDrug(selectedDrug).maxAge],
                onPressed: calculate,
                enabled: ageTextFieldEnabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Height and Weight Row
        Row(
          children: [
            SizedBox(
              width: UIWidth,
              child: PDTextField(
                prefixIcon: Icons.straighten,
                labelText: '${AppLocalizations.of(context)!.height} (cm)',
                interval: 1,
                fractionDigits: 0,
                controller: heightController,
                range: [getModelForDrug(selectedDrug).minHeight, getModelForDrug(selectedDrug).maxHeight],
                onPressed: calculate,
                enabled: heightTextFieldEnabled,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: UIWidth,
              child: PDTextField(
                prefixIcon: Icons.monitor_weight_outlined,
                labelText: '${AppLocalizations.of(context)!.weight} (kg)',
                interval: 1.0,
                fractionDigits: 0,
                controller: weightController,
                range: [getModelForDrug(selectedDrug).minWeight, getModelForDrug(selectedDrug).maxWeight],
                onPressed: calculate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Target Row
        PDTextField(
          prefixIcon: getModelForDrug(selectedDrug).target.icon,
          labelText: getModelForDrug(selectedDrug).getTargetLabel(context, selectedDrug),
          interval: getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).interval,
          fractionDigits: 1,
          controller: targetController,
          range: [
            getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).min,
            getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).max
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
      duration: 255, // Fixed duration for TCI
    );
  }

  Widget _buildResultsArea(BuildContext context, Settings settings) {
    if (infusionRegimeData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.ssid_chart,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
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

    return Column(
      children: [
        // Results Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TCI Results',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  // Display patient and calculation info (simplified since InfusionRegimeData doesn't have these fields)
                  Text(
                    'Patient: ${ageController.text}y ${sexController.val ? "F" : "M"}, ${weightController.text}kg, ${heightController.text}cm',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${selectedDrug?.displayWithConcentration ?? "Unknown Drug"} • ${tciModelController.selection}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Target: ${targetController.text} ${selectedDrug?.targetUnit.displayName ?? "μg/mL"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Results Table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DosageDataTable(
              data: infusionRegimeData!,
              maxVisibleRows: MediaQuery.of(context).size.width < 840 ? 5 : 8,
              selectedRowIndex: settings.selectedDosageTableRow,
              onRowTap: (index) {
                if (settings.selectedDosageTableRow == index) {
                  settings.selectedDosageTableRow = null;
                } else {
                  settings.selectedDosageTableRow = index;
                  
                  // Sync selected row's infusion rate to duration screen
                  if (infusionRegimeData != null && index < infusionRegimeData!.rows.length) {
                    final selectedRow = infusionRegimeData!.rows[index];
                    settings.infusionUnit = InfusionUnit.mL_hr;
                    settings.infusionRate = selectedRow.infusionRate;
                  }
                }
              },
              scrollController: tableScrollController,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrugSelector(BuildContext context, Settings settings, double UIHeight) {
    final currentModel = tciModelController.selection is Model ? tciModelController.selection as Model : null;
    
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;

    final hasValidationError = currentModel != null && 
        tciModelController.hasValidationError(sex: sex, weight: weight, height: height, age: age);

    final String? validationErrorText = hasValidationError
        ? tciModelController.getValidationErrorText(sex: sex, weight: weight, height: height, age: age)
        : null;

    // Calculate dynamic width based on drug names
    final drugNames = [
      'Propofol',
      'Remifentanil', 
      'Dexmedetomidine', // Longest name
      'Remimazolam',
      AppLocalizations.of(context)!.selectDrug, // Default text
    ];
    
    final textStyle = Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final dynamicWidth = TextMeasurement.calculateDrugSelectorWidth(
      context: context,
      drugNames: drugNames,
      textStyle: textStyle,
    );

    return SizedBox(
      width: dynamicWidth,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            enabled: true,
            readOnly: true,
            controller: TextEditingController(
              text: selectedDrug?.toLocalizedString(context) ?? AppLocalizations.of(context)!.selectDrug
            ),
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
                    // Save current target value to current drug before switching
                    if (selectedDrug != null) {
                      final currentTarget = double.tryParse(targetController.text);
                      if (currentTarget != null) {
                        settings.setTciDrugTarget(selectedDrug, currentTarget);
                      }
                    }
                    
                    // Hard-coded model-drug combinations
                    Model requiredModel;
                    if (drug.isDexmedetomidine) {
                      requiredModel = Model.Hannivoort;
                    } else if (drug.isRemifentanil) {
                      requiredModel = Model.Eleveld;
                    } else {
                      requiredModel = Model.Eleveld; // Default for propofol, remimazolam
                    }
                    
                    setState(() {
                      selectedDrug = drug;
                      tciModelController.selection = requiredModel;
                      settings.tciDrug = drug;
                      settings.tciModel = requiredModel;
                      
                      // Load drug-specific target value
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

  bool _hasValidationErrors() {
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;
    
    final currentModel = tciModelController.selection is Model 
        ? tciModelController.selection as Model 
        : null;
    
    return currentModel != null && 
        tciModelController.hasValidationError(sex: sex, weight: weight, height: height, age: age);
  }

  @override
  void dispose() {
    super.dispose();
  }
}