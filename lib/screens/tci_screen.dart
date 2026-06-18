import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'package:propofol_dreams_app/models/target_unit.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;

import '../constants.dart';
import '../components/infusion_regime_table.dart';
import '../components/collapsible_input_card.dart';
import '../components/input_summary_display.dart';
import '../utils/text_measurement.dart';

import 'package:propofol_dreams_app/components/legacy/PDTextField.dart';
import 'package:propofol_dreams_app/components/legacy/PDSwitchController.dart';
import 'package:propofol_dreams_app/components/legacy/PDSwitchField.dart';
import 'package:propofol_dreams_app/components/legacy/PDAdvancedSegmentedController.dart';

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
  final CollapsibleInputCardController _inputCardController =
      CollapsibleInputCardController();

  @override
  void initState() {
    super.initState();
    
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
    
    // Removed automatic listeners - now using event-driven approach
    // tciModelController.addListener(calculate);
    // pediatricModelController.addListener(calculate);
    // sexController.addListener(calculate);
    // ageController.addListener(calculate);  // Removed - use onPressed events instead
    // heightController.addListener(calculate); // Removed - use onPressed events  
    // weightController.addListener(calculate); // Removed - use onPressed events
    // targetController.addListener(calculate); // Removed - use onPressed events
    // durationController.addListener(_onTextFieldChanged); // Removed - duration is hardcoded

    modelOptions.addAll([
      // Propofol models
      Model.Eleveld,
      Model.Marsh,
      Model.Schnider,
      
      // New drug models
      // Model.Minto, // Commented out - Eleveld handles Remifentanil
      Model.Hannivoort,
      Model.Eleveld,
    ]);

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

    // updateModelOptions(true); // Always adult view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculate();
    });
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
    targetController.text = drugTarget?.toStringAsFixed(1) ?? targetProps.defaultValue.toStringAsFixed(1);
    durationController.text = '255'; // Hardcoded to 4 hours and 15 minutes for modal compatibility
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

    // TCI model and drug are saved immediately in onModelSelected/onDrugSelected
    // No need to save them here to avoid duplicate settings updates
    settings.tciSex = sex;
    settings.tciAge = age;
    settings.tciHeight = height;
    settings.tciWeight = weight;
    // Save to TCI-specific drug target (separate from volume screen)
    settings.setTciDrugTarget(selectedDrug, target);
    // settings.adultDuration removed - duration is hardcoded to 255 minutes
  }

  // void updateModelOptions(bool inAdultView) {
  //   // Update model options based on adult/pediatric view
  // }


  void calculate({bool collapseInput = false}) {
    if (_isCalculating) return;
    _isCalculating = true;
    
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
      final finalDuration = 255; // Hardcoded to 4 hours and 15 minutes (ensures table shows up to 4:00)
      final sex = sexController.val ? Sex.Female : Sex.Male;
      
      // Get current model
      final selectedModel = tciModelController.selection;

      // Create patient object for debugging (similar to volume screen)
      final patient = Patient(
        weight: finalWeight, 
        age: finalAge, 
        height: finalHeight, 
        sex: sex
      );

      // Create pump configuration (matching volume screen pattern)
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

        // Run real pharmacokinetic simulation
        PDSim.Simulation simulation = PDSim.Simulation(
          model: selectedModel,
          patient: patient,
          pump: pump,
        );

        var results = simulation.estimate;
        
        setState(() {
          infusionRegimeData = InfusionRegimeData.fromSimulation(
            times: results.times,
            pumpInfs: results.pumpInfs,
            cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
            density: 10,
            totalDuration: Duration(minutes: finalDuration),
            isEffectSiteTargeting: selectedModel.target == Target.EffectSite,
            drugConcentrationMgMl: selectedDrug?.concentration ?? 10.0,
          );
        });
        if (collapseInput) _inputCardController.collapse();

        // Update status bar
        final conc = selectedDrug?.concentration ?? 10.0;
        final concStr = conc == conc.roundToDouble()
            ? conc.toStringAsFixed(0)
            : conc.toStringAsFixed(1);
        final unit = selectedDrug?.concentrationUnit.displayName ?? 'mg/mL';
        settings.statusBarInfo =
            'Model: ${selectedModel} · Drug: ${selectedDrug?.displayName ?? '—'} $concStr $unit · Pump: ${settings.max_pump_rate} mL/hr';
      } else {
        // Clear data if model is not runnable
        setState(() {
          infusionRegimeData = null;
        });
      }

      DateTime finish = DateTime.now();
      Duration calculationDuration = finish.difference(start);

      // Prepare enhanced output with first 15min details (same as volume screen - simple direct print)
      final outputData = {
        'screen': 'TCI',
        'model': selectedModel,
        'drug': selectedDrug?.displayName ?? 'Unknown',
        'drug_unit': '${selectedDrug?.concentration.toStringAsFixed(selectedDrug?.concentration == selectedDrug?.concentration.roundToDouble() ? 0 : 1)} ${selectedDrug?.concentrationUnit.displayName}',
        'patient': patient,
        'pump': {
          'timeStep': '${pump.timeStep}',
          'concentration': pump.concentration,
          'concentrationUnit': selectedDrug?.concentrationUnit.displayName ?? 'mg/ml',
          'maxPumpRate': pump.maxPumpRate,
          'maxPumpRateUnit': 'ml/hr',
          'maxInfusionRate': pump.concentration * pump.maxPumpRate,
          'maxInfusionRateUnit': 'mg/hr',
          'target': pump.target,
          'targetUnit': selectedDrug?.targetUnit.displayName ?? 'μg/mL',
          'targetType': selectedModel.target.toString(),
          'duration': '${pump.duration}',
          'drug': pump.drug?.displayName ?? 'Unknown'
        },
        'target': finalTarget,
        'duration': finalDuration,
        'calculation time': '${calculationDuration.inMilliseconds.toString()} milliseconds',
        'total_volume': infusionRegimeData?.totalVolume.toStringAsFixed(1) ?? '0.0',
        'max_rate': infusionRegimeData?.maxInfusionRate.toStringAsFixed(1) ?? '0.0',
      };
      
      // Add first 15 minutes detailed information
      // if (infusionRegimeData != null && infusionRegimeData!.rows.isNotEmpty) {
      //   final firstRow = infusionRegimeData!.rows.first;
      //   outputData['first_15min_bolus'] = '${firstRow.bolus.toStringAsFixed(2)} mL';
      //   outputData['first_15min_bolus_raw'] = firstRow.rawBolus != null ? '${firstRow.rawBolus!.toStringAsFixed(6)} mL' : 'N/A';
      //   outputData['first_15min_rate'] = '${firstRow.infusionRate.toStringAsFixed(2)} mL/hr';
      //   outputData['first_15min_total'] = '${firstRow.accumulatedVolume.toStringAsFixed(2)} mL';
      // } else {
      //   outputData['first_15min_bolus'] = '0.0 mL';
      //   outputData['first_15min_bolus_raw'] = 'N/A';
      //   outputData['first_15min_rate'] = '0.0 mL/hr';
      //   outputData['first_15min_total'] = '0.0 mL';
      // }
      
      print(outputData);
    } catch (e) {
      debugPrint('Calculation error: $e');
    } finally {
      _isCalculating = false;
    }
  }

  void updatePDTableController(PDTableController controller) {
    final settings = Provider.of<Settings>(context, listen: false);
    settings.isVolumeTableExpanded = !settings.isVolumeTableExpanded;
    setState(() {
      controller.val = settings.isVolumeTableExpanded;
    });
  }

  void updatePDTextEditingController() {
    // Always adult view now, no need to check age
    // updateModelOptions(true);
    calculate();
  }

  /// Get the appropriate model for the selected drug (hard-coded relationships)
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
    
    // Always use TCI defaults and settings
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
    final currentModel = tciModelController.selection is Model ? tciModelController.selection as Model : Model.Eleveld;
    final targetProps = currentModel.getTargetProperties(selectedDrug);
    
    targetController.text = toDefault
        ? targetProps.defaultValue.toStringAsFixed(1)
        : settings.getTciDrugTarget(selectedDrug)?.toStringAsFixed(1) ?? targetProps.defaultValue.toStringAsFixed(1);
    durationController.text = '255'; // Hardcoded to 4 hours and 15 minutes for modal compatibility

    // updateModelOptions(true); // Always adult view
    calculate();
  }

  Widget buildModelSelector(Settings settings, double UIHeight) {
    final currentModel = tciModelController.selection is Model ? tciModelController.selection as Model : null;
    
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final bool isAdult = age >= 17;
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
    
    // Get the text style used in the TextField
    final textStyle = Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    
    final dynamicWidth = TextMeasurement.calculateDrugSelectorWidth(
      context: context,
      drugNames: drugNames,
      textStyle: textStyle,
    );

    // L8: Constrain the model selector to the maximum of the dynamic width
    // (for mobile, where there's room) and the available parent width
    // (for tablet/desktop, where the card is narrow). This prevents the
    // field from overflowing the input card on tablet/desktop.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: dynamicWidth),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            enabled: true,
            readOnly: true,
            controller: TextEditingController(text: selectedDrug?.toLocalizedString(context) ?? AppLocalizations.of(context)!.selectDrug),
            style: TextStyle(
              color: hasValidationError 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
              overflow: TextOverflow.ellipsis,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.onPrimary,
              helperText: null,
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
                    inAdultView: true, // Always adult view now
                    sexController: sexController,
                    ageController: ageController,
                    heightController: heightController,
                    weightController: weightController,
                    targetController: targetController,
                    durationController: durationController, // Still needed for modal compatibility
                    isTCIScreen: true, // Identify this as dosage screen
                    currentDrug: selectedDrug, // Pass current selected drug
                    onModelSelected: (model) {
                      // Hard-coded model-drug combinations (no auto-correction)
                      setState(() {
                        tciModelController.selection = model;
                        settings.tciModel = model;
                        // Keep existing drug selection
                        
                        // Update target field with drug-specific value for new model
                        final drugTarget = settings.getTciDrugTarget(selectedDrug);
                        final targetProps = model.getTargetProperties(selectedDrug);
                        targetController.text = drugTarget?.toStringAsFixed(1) ?? targetProps.defaultValue.toStringAsFixed(1);
                      });
                      
                      // Calculate once after model change
                      calculate();
                    },
                    onDrugSelected: (drug) {
                      // FIRST: Save current target value to current drug before switching
                      if (selectedDrug != null) {
                        final currentTarget = double.tryParse(targetController.text);
                        if (currentTarget != null) {
                          settings.setTciDrugTarget(selectedDrug, currentTarget);
                        }
                      }
                      
                      // Hard-coded model-drug combinations (no auto-correction)
                      Model requiredModel;
                      if (drug.isDexmedetomidine) {
                        requiredModel = Model.Hannivoort;
                      } else if (drug.isRemifentanil) {
                        requiredModel = Model.Eleveld; // Eleveld handles Remifentanil
                      } else {
                        requiredModel = Model.Eleveld; // Default for propofol, remimazolam
                      }
                      
                      setState(() {
                        selectedDrug = drug;
                        settings.tciDrug = drug;
                        tciModelController.selection = requiredModel;
                        settings.tciModel = requiredModel;
                        
                        // THEN: Load target value for NEW drug
                        final newDrugTarget = settings.getTciDrugTarget(drug);
                        final targetProps = requiredModel.getTargetProperties(drug);
                        targetController.text = newDrugTarget?.toStringAsFixed(1) ?? targetProps.defaultValue.toStringAsFixed(1);
                      });
                      
                      // Calculate once after drug change
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
    // Note: PDSwitchController, PDAdvancedSegmentedController, and TextEditingControllers 
    // used with PD widgets are disposed by their respective widgets
    // Only dispose controllers that are not managed by PD widgets
    scrollController.dispose();
    tableScrollController.dispose();
    super.dispose();
  }

  /// Build the input fields widget used as [CollapsibleInputCard] expandedContent.
  Widget _buildInputFields(double UIHeight, Settings settings) {
    return Column(
      children: [
        // Model selector and reset button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // L8: Flexible lets the model selector shrink to fit the card
            // width on tablet/desktop, where the dynamic width can otherwise
            // exceed the card and clip the reset button.
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: buildModelSelector(settings, UIHeight),
            ),
            const SizedBox(width: 4),
            Container(
              height: UIHeight,
              width: UIHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(0),
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(8),
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
        const SizedBox(height: 8),
        // Sex and Age row
        SizedBox(
          height: UIHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildSexField(UIHeight)),
              const SizedBox(width: 8),
              Expanded(child: _buildAgeField(UIHeight)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Height and Weight row
        SizedBox(
          height: UIHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildHeightField(UIHeight)),
              const SizedBox(width: 8),
              Expanded(child: _buildWeightField(UIHeight)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Target row
        SizedBox(
          height: UIHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildTargetField(UIHeight)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSexField(double UIHeight) {
    final isAdult = (int.tryParse(ageController.text) ?? 0) >= 17;
    final sexSwitchEnabled = (tciModelController.selection as Model).target != Target.Plasma;
    return PDSwitchField(
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
            : Sex.Boy.toLocalizedString(context),
      },
      onChanged: calculate,
      height: UIHeight,
      enabled: sexSwitchEnabled,
    );
  }

  Widget _buildAgeField(double UIHeight) {
    final ageEnabled = tciModelController.selection != Model.Marsh &&
        selectedDrug?.isDexmedetomidine != true;
    return PDTextField(
      prefixIcon: Icons.calendar_month,
      labelText: AppLocalizations.of(context)!.age,
      interval: 1.0,
      fractionDigits: 0,
      controller: ageController,
      range: [getModelForDrug(selectedDrug).minAge, getModelForDrug(selectedDrug).maxAge],
      onPressed: updatePDTextEditingController,
      enabled: ageEnabled,
    );
  }

  Widget _buildHeightField(double UIHeight) {
    final heightEnabled = (tciModelController.selection as Model).target != Target.Plasma;
    return PDTextField(
      prefixIcon: Icons.straighten,
      labelText: AppLocalizations.of(context)!.height,
      interval: 1,
      fractionDigits: 0,
      controller: heightController,
      range: [getModelForDrug(selectedDrug).minHeight, getModelForDrug(selectedDrug).maxHeight],
      onPressed: updatePDTextEditingController,
      enabled: heightEnabled,
    );
  }

  Widget _buildWeightField(double UIHeight) {
    return PDTextField(
      prefixIcon: Icons.monitor_weight_outlined,
      labelText: AppLocalizations.of(context)!.weight,
      interval: 1.0,
      fractionDigits: 0,
      controller: weightController,
      range: [getModelForDrug(selectedDrug).minWeight, getModelForDrug(selectedDrug).maxWeight],
      onPressed: updatePDTextEditingController,
    );
  }

  Widget _buildTargetField(double UIHeight) {
    return PDTextField(
      prefixIcon: getModelForDrug(selectedDrug).target.icon,
      labelText: getModelForDrug(selectedDrug).getTargetLabel(context, selectedDrug),
      interval: getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).interval,
      fractionDigits: 1,
      controller: targetController,
      range: [
        getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).min,
        getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).max,
      ],
      onPressed: updatePDTextEditingController,
    );
  }

  /// Collapsible input card wrapping the TCI input fields.
  Widget _buildInputCard(double UIHeight, Settings settings) {
    final age = int.tryParse(ageController.text);
    final weight = int.tryParse(weightController.text);
    final height = int.tryParse(heightController.text);
    final target = double.tryParse(targetController.text);
    final sex = sexController.val ? Sex.Female : Sex.Male;

    return CollapsibleInputCard(
      title: AppLocalizations.of(context)!.tci,
      controller: _inputCardController,
      expandedContent: _buildInputFields(UIHeight, settings),
      collapsedSummary: InputSummaryDisplay(
        calculatorType: CalculatorType.tci,
        age: age,
        sex: sex,
        weight: weight,
        height: height,
        drug: selectedDrug,
        model: tciModelController.selection,
        target: target,
        duration: 255,
      ),
      onCalculate: () => calculate(collapseInput: true),
      isCalculating: _isCalculating,
    );
  }

  /// Results table section, or empty container when no data.
  Widget _buildResultsTable(Settings settings) {
    if (infusionRegimeData == null) return Container();
    return Consumer<Settings>(
      builder: (context, settings, child) {
        return DosageDataTable(
          data: infusionRegimeData!,
          maxVisibleRows: MediaQuery.of(context).size.height >= screenBreakPoint1 ? 5 : 3,
          selectedRowIndex: settings.selectedDosageTableRow,
          onRowTap: (index) {
            if (settings.selectedDosageTableRow == index) {
              settings.selectedDosageTableRow = null;
            } else {
              settings.selectedDosageTableRow = index;
              if (infusionRegimeData != null && index < infusionRegimeData!.rows.length) {
                final selectedRow = infusionRegimeData!.rows[index];
                settings.infusionUnit = InfusionUnit.mL_hr;
                settings.infusionRate = selectedRow.infusionRate;
              }
            }
          },
          scrollController: tableScrollController,
        );
      },
    );
  }

  /// Tablet 2-column layout: input card on left, results on right.
  Widget _buildTabletLayout(Settings settings, double UIHeight) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalSidesPaddingPixel,
        right: horizontalSidesPaddingPixel,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: _buildInputCard(UIHeight, settings),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildResultsTable(settings),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop 2-column layout: input card on left (360px), results on right.
  Widget _buildDesktopLayout(Settings settings, double UIHeight) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalSidesPaddingPixel,
        right: horizontalSidesPaddingPixel,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 360,
            child: _buildInputCard(UIHeight, settings),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildResultsTable(settings),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps [child] in a [Shortcuts] + [Actions] pair that catches Enter and
  /// invokes [calculate] — on desktop (≥ 1024px) and web only. On mobile and
  /// tablet, the wrapper is skipped (Enter keeps its default behaviour).
  ///
  /// Added in L6 (LAYOUT_MIGRATION_SPEC.md). The wrapping `Shortcuts` widget
  /// intercepts Enter *before* `PDTextField.onSubmitted` handles it, so the
  /// stepper-increment behaviour is suppressed in favour of calculate.
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
              calculate(collapseInput: true);
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

    final mediaQuery = MediaQuery.of(context);
    final double UIHeight =
        (mediaQuery.size.aspectRatio >= 0.455
            ? mediaQuery.size.height >= screenBreakPoint1
                ? 56
                : 48
            : 48) +
        (ResponsiveHelper.isAndroid() ? 4 : 0);

    final settings = context.watch<Settings>();

    if (isDesktopLayout) {
      return _wrapWithKeyboardShortcuts(_buildDesktopLayout(settings, UIHeight));
    }
    if (isTabletLayout) {
      return _wrapWithKeyboardShortcuts(_buildTabletLayout(settings, UIHeight));
    }

    // Mobile: single-column scrollable layout
    return _wrapWithKeyboardShortcuts(
      LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: EdgeInsets.only(
              left: horizontalSidesPaddingPixel,
              right: horizontalSidesPaddingPixel,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildResultsTable(settings),
                    const SizedBox(height: 16),
                    _buildInputCard(UIHeight, settings),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
