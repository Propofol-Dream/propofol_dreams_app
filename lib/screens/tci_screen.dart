import 'dart:async';
import 'dart:io' show Platform;
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
import 'package:propofol_dreams_app/models/target_unit.dart';
import 'package:propofol_dreams_app/models/InfusionUnit.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;

import '../constants.dart';
import '../components/infusion_regime_table.dart';
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


  void calculate() {
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
            density: 10, // LEGACY parameter name: kept for InfusionRegimeData backward compatibility
            totalDuration: Duration(minutes: finalDuration),
            isEffectSiteTargeting: selectedModel.target == Target.EffectSite,
            drugConcentrationMgMl: selectedDrug?.concentration ?? 10.0, // Use selected drug concentration or default
          );
        });
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
        ? targetProps.defaultValue.toString()
        : settings.getTciDrugTarget(selectedDrug)?.toString() ?? targetProps.defaultValue.toString();
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

    return SizedBox(
      width: dynamicWidth,
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
                        targetController.text = drugTarget?.toString() ?? targetProps.defaultValue.toString();
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
                        targetController.text = newDrugTarget?.toString() ?? targetProps.defaultValue.toString();
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double UIHeight = (mediaQuery.size.aspectRatio >= 0.455
        ? mediaQuery.size.height >= screenBreakPoint1
            ? 56
            : 48
        : 48) + (Platform.isAndroid ? 4 : 0);
    final double UIWidth =
        (mediaQuery.size.width - 2 * (horizontalSidesPaddingPixel + 4)) / 2;
    final double screenHeight = mediaQuery.size.height -
        (Platform.isAndroid
            ? 48
            : mediaQuery.size.height >= screenBreakPoint1
                ? 88
                : 56);
    
    final settings = context.watch<Settings>();
    
    // Controllers are managed directly by onModelSelected/onDrugSelected
    // No need to sync from settings here since we use hard-coded combinations
    Model selectedModel = tciModelController.selection;
    
    // Add age-based logic for girl/boy display
    final int age = int.tryParse(ageController.text) ?? 0;
    final bool isAdult = age >= 17;
    
    // Check if model is runnable (kept for potential future use)
    // bool modelIsRunnable = selectedModel.isRunnable(
    //     age: age,
    //     height: height,
    //     weight: weight,
    //     target: target,
    //     duration: duration);
    
    final bool heightTextFieldEnabled = (tciModelController.selection as Model).target != Target.Plasma;
    final bool sexSwitchControlEnabled = (tciModelController.selection as Model).target != Target.Plasma;

    final ageTextFieldEnabled = tciModelController.selection != Model.Marsh && 
                                selectedDrug?.isDexmedetomidine != true;

    return Container(
      height: screenHeight,
      margin: const EdgeInsets.symmetric(horizontal: horizontalSidesPaddingPixel),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Top half - Results area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(),
                ),
                // Removed adult/paed toggle
                // Expand button and result text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(), // Removed expand/collapse button
                    Container(), // Removed text display
                  ],
                ),
              ],
            ),
          ),
          // Infusion regime table (fixed position above inputs)
          Container(
            child: infusionRegimeData != null
              ? Consumer<Settings>(
                  builder: (context, settings, child) {
                    return DosageDataTable(
                      data: infusionRegimeData!,
                      maxVisibleRows: mediaQuery.size.height >= screenBreakPoint1 ? 5 : 3,
                      selectedRowIndex: settings.selectedDosageTableRow,
                      onRowTap: (index) {
                        // Toggle selection: if same row is tapped, deselect it
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
                    );
                  },
                )
              : Container(),
          ),
          const SizedBox(height: 16),
          // Bottom half - Fixed input area (doesn't move when table expands)
          SizedBox(
            width: mediaQuery.size.width - horizontalSidesPaddingPixel * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildModelSelector(settings, UIHeight),
                Row(
                  children: [
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
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(5))),
                          ),
                          onPressed: () async {
                            await HapticFeedback.mediumImpact();
                            reset(toDefault: true);
                          },
                          child: Icon(Icons.restart_alt_outlined),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sex and Age row
          SizedBox(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: UIWidth,
                  child: PDSwitchField(
                    labelText: AppLocalizations.of(context)!.sex,
                    prefixIcon: sexController.val == true 
                        ? isAdult 
                            ? Icons.woman 
                            : Icons.girl 
                        : isAdult 
                            ? Icons.man 
                            : Icons.boy,
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
                const SizedBox(
                  width: 8,
                  height: 0,
                ),
                SizedBox(
                  width: UIWidth,
                  child: PDTextField(
                    prefixIcon: Icons.calendar_month,
                    labelText: AppLocalizations.of(context)!.age,
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: ageController,
                    range: [getModelForDrug(selectedDrug).minAge, getModelForDrug(selectedDrug).maxAge],
                    onPressed: updatePDTextEditingController,
                    enabled: ageTextFieldEnabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Height and Weight row
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
                    interval: 1,
                    fractionDigits: 0,
                    controller: heightController,
                    range: [getModelForDrug(selectedDrug).minHeight, getModelForDrug(selectedDrug).maxHeight],
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
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: weightController,
                    range: [getModelForDrug(selectedDrug).minWeight, getModelForDrug(selectedDrug).maxWeight],
                    onPressed: updatePDTextEditingController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Target row (now full width)
          SizedBox(
            height: UIHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PDTextField(
                    prefixIcon: getModelForDrug(selectedDrug).target.icon,
                    labelText: getModelForDrug(selectedDrug).getTargetLabel(context, selectedDrug), // Dynamic unit display
                    interval: getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).interval, // Dynamic interval based on drug-model combination
                    fractionDigits: 1,
                    controller: targetController,
                    range: [getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).min, getModelForDrug(selectedDrug).getTargetProperties(selectedDrug).max], // Dynamic range based on drug-model combination
                    onPressed: updatePDTextEditingController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}