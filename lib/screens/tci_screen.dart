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
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/target.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;

import '../constants.dart';
import '../components/infusion_regime_table.dart';

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
  String? _lastDebugOutput; // Track last debug output to avoid duplicates

  InfusionRegimeData? infusionRegimeData;
  String result = '';
  String emptyResult = '';

  @override
  void initState() {
    super.initState();
    
    final settings = context.read<Settings>();
    _setControllersFromSettings(settings);
    
    // Removed automatic listeners - now using event-driven approach
    // adultModelController.addListener(calculate);
    // pediatricModelController.addListener(calculate);
    // sexController.addListener(calculate);
    ageController.addListener(_onTextFieldChanged);
    heightController.addListener(_onTextFieldChanged);
    weightController.addListener(_onTextFieldChanged);
    targetController.addListener(_onTextFieldChanged);
    // durationController.addListener(_onTextFieldChanged); // Removed - duration is hardcoded

    modelOptions.addAll([
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

    updateModelOptions(true); // Always adult view
    calculate();
  }

  void _setControllersFromSettings(Settings settings) {
    tableController.val = true; // Always keep table expanded

    // Always use adult settings
    adultModelController.selection = settings.adultModel;
    sexController.val = settings.adultSex == Sex.Female ? true : false;
    ageController.text = settings.adultAge?.toString() ?? '40';
    heightController.text = settings.adultHeight?.toString() ?? '170';
    weightController.text = settings.adultWeight?.toString() ?? '70';
    targetController.text = settings.adultTarget?.toString() ?? '3.0';
    durationController.text = '240'; // Hardcoded to 4 hours for modal compatibility
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

    // Always save to adult settings
    settings.adultModel = adultModelController.selection;
    settings.adultSex = sex;
    settings.adultAge = age;
    settings.adultHeight = height;
    settings.adultWeight = weight;
    settings.adultTarget = target;
    // settings.adultDuration removed - duration is hardcoded to 240 minutes
  }

  void updateModelOptions(bool inAdultView) {
    // Update model options based on adult/pediatric view
  }

  void _onTextFieldChanged() {
    // Debounced timer: Cancel previous timer and start new one
    // This prevents calculate() from running on every keystroke
    timer.cancel();
    timer = Timer(delay, () {
      calculate(); // Only runs after user stops typing for 500ms
    });
  }

  void calculate() {
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
      final finalDuration = 240; // Hardcoded to 4 hours
      final sex = sexController.val ? Sex.Female : Sex.Male;
      
      // Get current model
      final model = adultModelController.selection;

      // Create patient object for debugging (similar to volume screen)
      final patient = Patient(
        weight: finalWeight, 
        age: finalAge, 
        height: finalHeight, 
        sex: sex
      );

      // Only calculate if we have a valid model and all required parameters
      if (model != Model.None && 
          model.isRunnable(
            age: finalAge,
            height: finalHeight,
            weight: finalWeight,
            target: finalTarget,
            duration: finalDuration,
          )) {
        
        // Create pump configuration (matching volume screen pattern)
        final pump = Pump(
          timeStep: Duration(seconds: settings.time_step),
          density: settings.density,
          maxPumpRate: settings.max_pump_rate,
          target: finalTarget,
          duration: Duration(minutes: finalDuration),
        );

        // Run real pharmacokinetic simulation
        PDSim.Simulation simulation = PDSim.Simulation(
          model: model,
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

      // Create debug output string
      final debugOutput = 'TCI: $model, Patient(${sex.name}, ${finalAge}y, ${finalHeight}cm, ${finalWeight}kg), Target: $finalTarget, Duration: ${finalDuration}min';
      
      // Only print if output has changed (avoid spam)
      if (_lastDebugOutput != debugOutput) {
        _lastDebugOutput = debugOutput;
        print({
          'screen': 'TCI',
          'model': model,
          'patient': patient,
          'target': finalTarget,
          'duration': finalDuration,
          'calculation time': '${calculationDuration.inMilliseconds.toString()} milliseconds',
          'bolus': infusionRegimeData?.totalBolus.toStringAsFixed(1) ?? '0.0',
          'total_volume': infusionRegimeData?.totalVolume.toStringAsFixed(1) ?? '0.0',
          'max_rate': infusionRegimeData?.maxInfusionRate.toStringAsFixed(1) ?? '0.0'
        });
      }
    } catch (e) {
      debugPrint('Calculation error: $e');
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
    updateModelOptions(true);
    calculate();
  }

  void reset({bool toDefault = false}) {
    final settings = Provider.of<Settings>(context, listen: false);
    
    // Always use adult defaults and settings
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
    durationController.text = '240'; // Hardcoded to 4 hours for modal compatibility

    updateModelOptions(true); // Always adult view
    calculate();
  }

  Widget buildModelSelector(Settings settings, double UIHeight) {
    final currentModel = adultModelController.selection is Model ? adultModelController.selection as Model : null;
    
    final Sex sex = sexController.val ? Sex.Female : Sex.Male;
    final int age = int.tryParse(ageController.text) ?? 0;
    final int height = int.tryParse(heightController.text) ?? 0;
    final int weight = int.tryParse(weightController.text) ?? 0;

    final hasValidationError = currentModel != null && 
        adultModelController.hasValidationError(sex: sex, weight: weight, height: height, age: age);

    final String? validationErrorText = hasValidationError
        ? adultModelController.getValidationErrorText(sex: sex, weight: weight, height: height, age: age)
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
                adultModelController.showModelSelector(
                    context: context,
                    inAdultView: true, // Always adult view now
                    sexController: sexController,
                    ageController: ageController,
                    heightController: heightController,
                    weightController: weightController,
                    targetController: targetController,
                    durationController: durationController, // Still needed for modal compatibility
                    isDosageScreen: true, // Identify this as dosage screen
                    onModelSelected: (model) {
                      setState(() {
                        adultModelController.selection = model;
                        settings.adultModel = model;
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
    // Note: PDSwitchController, PDAdvancedSegmentedController, and TextEditingControllers 
    // used with PD widgets are disposed by their respective widgets
    // Only dispose controllers that are not managed by PD widgets
    scrollController.dispose();
    tableScrollController.dispose();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
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
    
    adultModelController.selection = settings.adultModel;
    Model selectedModel = adultModelController.selection;
    
    // Check if model is runnable (kept for potential future use)
    // bool modelIsRunnable = selectedModel.isRunnable(
    //     age: age,
    //     height: height,
    //     weight: weight,
    //     target: target,
    //     duration: duration);
    
    final bool heightTextFieldEnabled = (adultModelController.selection as Model).target != Target.Plasma;
    final bool sexSwitchControlEnabled = (adultModelController.selection as Model).target != Target.Plasma;

    final ageTextFieldEnabled = adultModelController.selection != Model.Marsh;

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
          mediaQuery.size.height >= screenBreakPoint1
              ? Container(
                  child: infusionRegimeData != null
                    ? Consumer<Settings>(
                        builder: (context, settings, child) {
                          return DosageDataTable(
                            data: infusionRegimeData!,
                            maxVisibleRows: 5,
                            selectedRowIndex: settings.selectedDosageTableRow,
                            onRowTap: (index) {
                              // Toggle selection: if same row is tapped, deselect it
                              if (settings.selectedDosageTableRow == index) {
                                settings.selectedDosageTableRow = null;
                              } else {
                                settings.selectedDosageTableRow = index;
                              }
                            },
                            scrollController: tableScrollController,
                          );
                        },
                      )
                    : Container(),
                )
              : const SizedBox(
                  height: 0,
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
                    prefixIcon: sexController.val == true ? Icons.woman : Icons.man,
                    controller: sexController,
                    switchTexts: {
                      true: Sex.Female.toLocalizedString(context),
                      false: Sex.Male.toLocalizedString(context)
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
                    range: [17, selectedModel == Model.Schnider ? 100 : 105],
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
                    interval: 1.0,
                    fractionDigits: 0,
                    controller: weightController,
                    range: [selectedModel.minWeight, selectedModel.maxWeight],
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
                    prefixIcon: Icons.psychology_alt_outlined,
                    labelText: selectedModel.target.toLocalizedString(context),
                    interval: 0.5,
                    fractionDigits: 1,
                    controller: targetController,
                    range: const [kMinTarget, kMaxTarget],
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