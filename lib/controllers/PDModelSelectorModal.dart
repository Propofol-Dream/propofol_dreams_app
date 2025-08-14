import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/model.dart';
import '../models/drug.dart';
import '../models/sex.dart';
import '../providers/settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'PDAdvancedSegmentedController.dart';
import 'PDSwitchController.dart';

enum ModelAvailability {
  available,
  unavailable,
  warning,
}

class ModelEvaluationResult {
  final ModelAvailability availability;
  final String? reason;
  final ValidationResult? validation;

  const ModelEvaluationResult({
    required this.availability,
    this.reason,
    this.validation,
  });
}

class PDModelSelectorModal extends StatefulWidget {
  const PDModelSelectorModal({
    super.key,
    required this.controller,
    required this.inAdultView,
    required this.sexController,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.targetController,
    required this.durationController,
    required this.onModelSelected,
    this.onDrugSelected,
    this.currentDrug, // Current selected drug for TCI screen
    this.isTCIScreen = false, // New parameter to identify TCI screen
  });

  final PDAdvancedSegmentedController controller;
  final bool inAdultView;
  final PDSwitchController sexController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetController;
  final TextEditingController durationController;
  final Function(Model) onModelSelected;
  final Function(Drug)? onDrugSelected;
  final Drug? currentDrug; // Current selected drug
  final bool isTCIScreen;

  @override
  State<PDModelSelectorModal> createState() => _PDModelSelectorModalState();
}

class _PDModelSelectorModalState extends State<PDModelSelectorModal> {
  late Model? selectedModel;
  late Drug? selectedDrug;
  
  @override
  void initState() {
    super.initState();
    final currentSelection = widget.controller.selection;
    // Check if it's a valid Model (not the error Map)
    selectedModel = (currentSelection is Model) ? currentSelection : null;
    selectedDrug = widget.currentDrug; // Initialize with current drug if provided
  }

  List<Model> get availableModels {
    if (widget.inAdultView) {
      // Adult view: show adult + universal models for Volume screen
      return [
        Model.Marsh,
        Model.Schnider,
        Model.Eleveld,
      ];
    } else {
      // Pediatric view: show pediatric + universal models for Volume screen
      return [
        Model.Paedfusor,
        Model.Kataria,
        Model.Eleveld,
      ];
    }
  }

  List<Drug> get availableDrugs {
    // TCI screen: show drug types only (concentration set in Settings)
    // Return the currently selected concentration variant for each drug type
    final settings = Provider.of<Settings>(context, listen: false);
    
    return [
      // Get current variants for each drug type
      settings.getCurrentDrugVariant('Propofol'),
      settings.getCurrentDrugVariant('Remifentanil'),
      settings.getCurrentDrugVariant('Dexmedetomidine'),
      settings.getCurrentDrugVariant('Remimazolam'),
    ];
  }

  Model getOptimalModelForDrug(Drug drug) {
    // Simplified TCI model logic:
    // - Dexmedetomidine uses Hannivoort
    // - All other drugs use Eleveld
    switch (drug) {
      case Drug.dexmedetomidine:
        return Model.Hannivoort;
      default:
        // Propofol, Remifentanil, Remimazolam all use Eleveld
        return Model.Eleveld;
    }
  }

  ModelEvaluationResult evaluateModel(Model model) {
    final Sex sex = widget.sexController.val ? Sex.Female : Sex.Male;
    final int? age = int.tryParse(widget.ageController.text);
    final int? height = int.tryParse(widget.heightController.text);
    final int? weight = int.tryParse(widget.weightController.text);
    final double? target = double.tryParse(widget.targetController.text);
    final int? duration = int.tryParse(widget.durationController.text);

    // Age group check based on inAdultView
    // Removed age < 17 restriction to allow lower ages for adult models
    if (!widget.inAdultView && age != null && age >= 17) {
      return const ModelEvaluationResult(
        availability: ModelAvailability.unavailable,
        reason: "Use adult models for age ≥17",
      );
    }

    // Basic constraint check
    if (age != null && height != null && weight != null) {
      if (!model.isEnable(age: age, height: height, weight: weight)) {
        return const ModelEvaluationResult(
          availability: ModelAvailability.unavailable,
          reason: "Age, height, or weight out of range",
        );
      }

      // Validation check
      final validation = model.validate(sex: sex, weight: weight, height: height, age: age);
      if (validation.hasError) {
        return ModelEvaluationResult(
          availability: ModelAvailability.warning,
          reason: validation.errorMessage,
          validation: validation,
        );
      }
    }

    // Completeness check
    if (!model.isRunnable(age: age, height: height, weight: weight, target: target, duration: duration)) {
      return const ModelEvaluationResult(
        availability: ModelAvailability.warning,
        reason: "Missing required parameters",
      );
    }

    return const ModelEvaluationResult(availability: ModelAvailability.available);
  }

  Widget buildModelButton(Model model) {
    final evaluation = evaluateModel(model);
    final bool isSelected = selectedModel == model;
    final bool isDisabled = evaluation.availability == ModelAvailability.unavailable;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: !isDisabled
              ? () async {
                  await HapticFeedback.mediumImpact();
                  // Directly select and close modal
                  widget.onModelSelected(model);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            minimumSize: const Size(double.infinity, 56), // Match UIHeight standard
            backgroundColor: isSelected 
                ? Theme.of(context).colorScheme.primary
                : evaluation.availability == ModelAvailability.warning
                    ? Colors.orange.shade50
                    : Theme.of(context).colorScheme.onPrimary,
            foregroundColor: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : isDisabled
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : evaluation.availability == ModelAvailability.warning
                      ? Colors.orange
                      : isDisabled
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Match other controls
            ),
          ),
          child: Text(
            model.name,
            textAlign: TextAlign.center,
          ),
        ),
        // Error text below button for unavailable models only
        if (isDisabled && evaluation.reason != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              evaluation.reason!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ] else ...[
          // Add consistent spacing for non-disabled items
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget buildDrugButton(Drug drug) {
    final model = getOptimalModelForDrug(drug);
    final evaluation = evaluateModel(model);
    final bool isSelected = selectedDrug == drug;
    final bool isDisabled = evaluation.availability == ModelAvailability.unavailable;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: !isDisabled
              ? () async {
                  await HapticFeedback.mediumImpact();
                  // Select drug and its optimal model
                  if (widget.onDrugSelected != null) {
                    widget.onDrugSelected!(drug);
                    // Don't call onModelSelected - onDrugSelected handles model selection
                  } else {
                    // Fallback for screens without drug selection (Volume screen)
                    widget.onModelSelected(model);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            minimumSize: const Size(double.infinity, 56), // Match UIHeight standard
            backgroundColor: isSelected 
                ? Theme.of(context).colorScheme.primary
                : evaluation.availability == ModelAvailability.warning
                    ? Colors.orange.shade50
                    : Theme.of(context).colorScheme.onPrimary,
            foregroundColor: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : isDisabled
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : evaluation.availability == ModelAvailability.warning
                      ? Colors.orange
                      : isDisabled
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Match other controls
            ),
          ),
          child: Text(
            drug.toLocalizedString(context), // Show localized drug name
            textAlign: TextAlign.center,
          ),
        ),
        // Error text below button for unavailable models only
        if (isDisabled && evaluation.reason != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              evaluation.reason!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ] else ...[
          // Add consistent spacing for non-disabled items
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 5),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Models list with title - compact layout
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title directly above first model
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isTCIScreen ? AppLocalizations.of(context)!.selectDrug : 'Select Model',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                // Models or drugs immediately below title
                if (widget.isTCIScreen) ...[
                  // TCI screen: show drugs
                  ...availableDrugs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final drug = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 8 : 16, // Small gap after title for first item
                      ),
                      child: buildDrugButton(drug),
                    );
                  }),
                ] else ...[
                  // Volume screen: show models
                  ...availableModels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final model = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 8 : 16, // Small gap after title for first item
                      ),
                      child: buildModelButton(model),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}