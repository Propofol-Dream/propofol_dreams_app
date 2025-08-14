import 'package:flutter/material.dart';
import 'dart:math';
import '../models/model.dart';
import '../models/drug.dart';
import '../models/sex.dart';
import 'PDModelSelectorModal.dart';
import 'PDSwitchController.dart';

class PDAdvancedSegmentedController extends ChangeNotifier {
  PDAdvancedSegmentedController();

  dynamic _selection;
  ValidationResult? _cachedValidation;

  dynamic get selection {
    return _selection == null
        ? {'error': '_selectedOption == null'}
        : _selection!;
  }

  set selection(s) {
    _selection = s;
    _cachedValidation = null; // Clear cache when selection changes
    notifyListeners();
  }

  ValidationResult validateSelection({
    required Sex sex,
    required int weight,
    required int height,
    required int age,
  }) {
    if (_cachedValidation != null) {
      return _cachedValidation!;
    }
    
    if (_selection is Model) {
      final Model selectedModel = _selection as Model;
      _cachedValidation = selectedModel.validate(
        sex: sex,
        weight: weight,
        height: height,
        age: age,
      );
      return _cachedValidation!;
    }
    
    // Default to valid if no model selected
    return const ValidationResult(isValid: true, errorMessage: '');
  }

  bool hasValidationError({
    required Sex sex,
    required int weight,
    required int height,
    required int age,
  }) {
    return validateSelection(
      sex: sex,
      weight: weight,
      height: height,
      age: age,
    ).hasError;
  }

  String getValidationErrorText({
    required Sex sex,
    required int weight,
    required int height,
    required int age,
  }) {
    return validateSelection(
      sex: sex,
      weight: weight,
      height: height,
      age: age,
    ).errorMessage;
  }

  void showModelSelector({
    required BuildContext context,
    required bool inAdultView,
    required PDSwitchController sexController,
    required TextEditingController ageController,
    required TextEditingController heightController,
    required TextEditingController weightController,
    required TextEditingController targetController,
    required TextEditingController durationController,
    required Function(Model) onModelSelected,
    Function(Drug)? onDrugSelected,
    Drug? currentDrug, // Current selected drug
    bool isTCIScreen = false, // New parameter
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: max(
            MediaQuery.of(context).viewInsets.bottom,
            MediaQuery.of(context).viewPadding.bottom,
          ),
        ),
        child: PDModelSelectorModal(
          controller: this,
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
          isTCIScreen: isTCIScreen, // Pass the parameter
        ),
      ),
    );
  }
}