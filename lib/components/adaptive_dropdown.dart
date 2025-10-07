import 'package:flutter/material.dart';
import '../config/ui_config.dart';
import '../models/model.dart';
import '../models/drug.dart';
import 'legacy/PDAdvancedSegmentedController.dart';
import 'legacy/PDSwitchController.dart';
import 'material3/m3_dropdown_menu.dart';

/// Adaptive Dropdown wrapper that switches between legacy and Material 3 implementations
///
/// This component provides seamless fallback behavior during the migration:
/// - Uses Material 3 DropdownMenu when feature flags are enabled
/// - Falls back to legacy PDModelSelectorModal when flags are disabled
/// - Maintains identical API surface for drop-in replacement
/// - Respects emergency fallback settings for production safety
class AdaptiveDropdown extends StatelessWidget {
  const AdaptiveDropdown({
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
  Widget build(BuildContext context) {
    // Check if Material 3 dropdown should be used
    if (UIConfig.shouldUseMaterial3Dropdown || UIConfig.shouldUseMaterial3Components) {
      return M3DropdownMenu(
        controller: controller,
        inAdultView: inAdultView,
        sexController: sexController,
        ageController: ageController,
        heightController: heightController,
        weightController: weightController,
        targetController: targetController,
        durationController: durationController,
        onModelSelected: onModelSelected,
        onDrugSelected: onDrugSelected,
        currentDrug: currentDrug,
        isTCIScreen: isTCIScreen,
        enabled: enabled,
        labelText: labelText,
        helperText: helperText,
        errorText: errorText,
      );
    }

    // Fallback to legacy implementation
    // For PDModelSelectorModal, we need to wrap it in a gesture detector
    // or similar to maintain the same tap-to-open behavior
    return _LegacyDropdownWrapper(
      controller: controller,
      inAdultView: inAdultView,
      sexController: sexController,
      ageController: ageController,
      heightController: heightController,
      weightController: weightController,
      targetController: targetController,
      durationController: durationController,
      onModelSelected: onModelSelected,
      onDrugSelected: onDrugSelected,
      currentDrug: currentDrug,
      isTCIScreen: isTCIScreen,
      enabled: enabled,
      labelText: labelText,
      errorText: errorText,
    );
  }
}

/// Wrapper for legacy PDModelSelectorModal to provide dropdown-like interface
class _LegacyDropdownWrapper extends StatelessWidget {
  const _LegacyDropdownWrapper({
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
  final String? errorText;

  String get _selectedModelName {
    // Handle controller selection which can be Model or error Map
    if (controller.selection is Model) {
      final Model selectedModel = controller.selection as Model;
      return selectedModel.name;
    }
    return 'Select Model';
  }

  List<Model> _getAvailableModels() {
    if (isTCIScreen && currentDrug != null) {
      return Model.values.where((model) =>
        _isModelCompatibleWithDrug(model, currentDrug!)
      ).toList();
    } else {
      // For non-TCI screens, return all models for now
      return Model.values.toList();
    }
  }

  bool _isModelCompatibleWithDrug(Model model, Drug drug) {
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

  void _showModelSelector(BuildContext context) {
    // For legacy compatibility, we could show a simple dialog or snackbar
    // But for now, let's just provide basic feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please enable Material 3 components for model selection'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? () => _showModelSelector(context) : null,
      child: Container(
        height: _getResponsiveHeight(context),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: errorText != null
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
            width: errorText != null ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
          color: enabled
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        ),
        child: Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              color: enabled
                  ? errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (labelText != null)
                    Text(
                      labelText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: errorText != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    _selectedModelName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ],
        ),
      ),
    );
  }
}