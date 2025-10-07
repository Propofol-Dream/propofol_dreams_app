import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/ui_config.dart';
import '../../models/model.dart';
import '../../models/drug.dart';
import '../../models/sex.dart';
import '../../providers/settings.dart';
import '../legacy/PDAdvancedSegmentedController.dart';
import '../legacy/PDSwitchController.dart';

/// Material 3 DropdownMenu replacement for PDModelSelectorModal
///
/// This component provides a modern Material 3 dropdown interface that matches
/// the existing functionality while offering enhanced UX features like:
/// - Searchable dropdown entries
/// - Improved keyboard navigation
/// - Better accessibility support
/// - Responsive sizing based on content
class M3DropdownMenu extends StatefulWidget {
  const M3DropdownMenu({
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
    this.currentDrug,
    this.isTCIScreen = false,
    this.enabled = true,
    this.labelText,
    this.helperText,
    this.errorText,
  });

  final PDAdvancedSegmentedController controller;
  final bool inAdultView;
  final PDSwitchController sexController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetController;
  final TextEditingController durationController;
  final VoidCallback onModelSelected;
  final VoidCallback? onDrugSelected;
  final Drug? currentDrug;
  final bool isTCIScreen;
  final bool enabled;
  final String? labelText;
  final String? helperText;
  final String? errorText;

  @override
  State<M3DropdownMenu> createState() => _M3DropdownMenuState();
}

class _M3DropdownMenuState extends State<M3DropdownMenu> {
  late TextEditingController _textController;
  Model? _selectedModel;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _updateSelectedModel();
  }

  @override
  void didUpdateWidget(M3DropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.selection != widget.controller.selection) {
      _updateSelectedModel();
    }
  }

  void _updateSelectedModel() {
    // Handle controller selection which can be Model or error Map
    if (widget.controller.selection is Model) {
      _selectedModel = widget.controller.selection as Model;
      _textController.text = _selectedModel?.name ?? '';
    } else {
      _selectedModel = null;
      _textController.text = '';
    }
  }

  List<Model> _getAvailableModels() {
    if (widget.isTCIScreen && widget.currentDrug != null) {
      // For TCI screen, filter models based on current drug
      return Model.values.where((model) =>
        _isModelCompatibleWithDrug(model, widget.currentDrug!)
      ).toList();
    } else {
      // For other screens, use adult/pediatric filtering
      // For non-TCI screens, return all models for now
      return Model.values.toList();
    }
  }

  bool _isModelCompatibleWithDrug(Model model, Drug drug) {
    // Define drug-model compatibility based on the existing logic
    switch (drug) {
      case Drug.propofol10mg:
      case Drug.propofol20mg:
        return [Model.Marsh, Model.Schnider, Model.Eleveld].contains(model);
      case Drug.remifentanil20mcg:
      case Drug.remifentanil40mcg:
      case Drug.remifentanil50mcg:
        // For now, only Eleveld is available for remifentanil
        return [Model.Eleveld].contains(model);
      case Drug.dexmedetomidine:
        return [Model.Hannivoort].contains(model);
      case Drug.remimazolam1mg:
      case Drug.remimazolam2mg:
        // For now, only Eleveld is available for remimazolam
        return [Model.Eleveld].contains(model);
    }
  }

  ModelEvaluationResult _evaluateModel(Model model) {
    final settings = context.read<Settings>();

    // Get patient data
    final age = int.tryParse(widget.ageController.text);
    final height = int.tryParse(widget.heightController.text);
    final weight = int.tryParse(widget.weightController.text);
    final sex = widget.sexController.val ? Sex.Female : Sex.Male;

    // Validate model with current patient data (only if all required data is available)
    if (age == null || height == null || weight == null) {
      return const ModelEvaluationResult(
        availability: ModelAvailability.available,
        reason: 'Patient data incomplete',
      );
    }

    final validation = model.validate(
      age: age,
      height: height,
      weight: weight,
      sex: sex,
    );

    if (!validation.isValid) {
      return ModelEvaluationResult(
        availability: ModelAvailability.unavailable,
        reason: validation.errorMessage,
        validation: validation,
      );
    }

    return const ModelEvaluationResult(
      availability: ModelAvailability.available,
    );
  }

  double _getResponsiveHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);

    // Base height calculation with responsive scaling
    double baseHeight = 56.0;

    // Adjust for screen width (mobile vs tablet vs desktop)
    if (screenWidth > 1200) {
      // Desktop: Larger touch targets
      baseHeight = 64.0;
    } else if (screenWidth > 600) {
      // Tablet: Medium touch targets
      baseHeight = 60.0;
    } else {
      // Mobile: Standard size but scale with text
      baseHeight = 56.0;
    }

    // Scale with accessibility text size
    baseHeight = baseHeight * textScale.clamp(1.0, 1.5);

    // Ensure minimum usable height for accessibility
    return baseHeight.clamp(56.0, 88.0);
  }

  @override
  Widget build(BuildContext context) {
    // Check if Material 3 dropdown should be used
    if (!UIConfig.shouldUseMaterial3Dropdown) {
      // Fallback to legacy component would go here
      // For now, we'll still render the M3 version for development
    }

    final models = _getAvailableModels();
    final theme = Theme.of(context);

    return SizedBox(
      height: _getResponsiveHeight(context),
      child: DropdownMenu<Model>(
      controller: _textController,
      enableFilter: true,
      enableSearch: true,
      enabled: widget.enabled,
      label: Text(widget.labelText ?? 'Select Model'),
      helperText: widget.helperText,
      errorText: widget.errorText,
      leadingIcon: const Icon(Icons.psychology_outlined),
      trailingIcon: const Icon(Icons.arrow_drop_down),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.0,
          ),
        ),
      ),
      menuStyle: MenuStyle(
        elevation: WidgetStateProperty.all(8.0),
        backgroundColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerLow,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      dropdownMenuEntries: models.map((model) {
        final evaluation = _evaluateModel(model);
        final isAvailable = evaluation.availability == ModelAvailability.available;

        return DropdownMenuEntry<Model>(
          value: model,
          label: model.name,
          enabled: isAvailable,
          leadingIcon: Icon(
            isAvailable ? Icons.check_circle : Icons.warning,
            color: isAvailable
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
            size: 20.0,
          ),
          trailingIcon: !isAvailable
            ? Icon(
                Icons.info_outline,
                color: theme.colorScheme.error,
                size: 16.0,
              )
            : null,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (!isAvailable) return theme.colorScheme.onSurface.withValues(alpha: 0.38);
              if (states.contains(WidgetState.hovered)) return theme.colorScheme.onSurfaceVariant;
              return theme.colorScheme.onSurface;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.colorScheme.secondaryContainer;
              }
              if (states.contains(WidgetState.hovered)) {
                return theme.colorScheme.surfaceContainerHighest;
              }
              return Colors.transparent;
            }),
          ),
        );
      }).toList(),
      onSelected: (Model? model) {
        if (model != null) {
          final evaluation = _evaluateModel(model);
          if (evaluation.availability == ModelAvailability.available) {
            setState(() {
              _selectedModel = model;
              widget.controller.selection = model;
            });
            widget.onModelSelected();
          } else {
            // Show snackbar for unavailable models instead of dialog
            _showModelUnavailableSnackbar(model, evaluation);
          }
        }
      },
      ),
    );
  }

  void _showModelUnavailableSnackbar(Model model, ModelEvaluationResult evaluation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${model.name}: ${evaluation.reason ?? 'Not available'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

// Legacy compatibility types
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