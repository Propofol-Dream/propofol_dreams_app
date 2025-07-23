import 'sex.dart';
import 'target.dart';
import 'drug.dart';
import 'target_unit.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errorMessage,
  });

  final bool isValid;
  final String errorMessage;

  factory ValidationResult.fromMap(Map<String, Object> map) {
    return ValidationResult(
      isValid: map['assertion'] as bool,
      errorMessage: map['text'] as String,
    );
  }

  bool get hasError => !isValid;
}

enum Model {
  // EXISTING PROPOFOL MODELS - Enhanced with drug and target unit
  Marsh(
      minAge: 17,
      maxAge: 105,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 150,
      target: Target.Plasma,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl),
  Schnider(
      minAge: 17,
      maxAge: 100,
      minHeight: 140,
      maxHeight: 210,
      minWeight: 0,
      maxWeight: 165,
      target: Target.EffectSite,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl),
  Eleveld(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.EffectSite,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl),
  Paedfusor(
      minAge: 1,
      maxAge: 16,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 5,
      maxWeight: 61,
      target: Target.Plasma,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl),
  Kataria(
      minAge: 3,
      maxAge: 16,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 15,
      maxWeight: 61,
      target: Target.Plasma,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl),
  EleMarsh(
      minAge: 5,
      maxAge: 105,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 999,
      target: Target.Plasma,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl),
  
  // NEW DRUG MODELS
  MintoRemifentanil(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.EffectSite,
      drug: Drug.remifentanilMinto,
      targetUnit: TargetUnit.ngPerMl),
  EleveldRemifentanil(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.EffectSite,
      drug: Drug.remifentanilEleveld,
      targetUnit: TargetUnit.ngPerMl),
  HannivoortDexmedetomidine(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.Plasma,
      drug: Drug.dexmedetomidine,
      targetUnit: TargetUnit.ngPerMl),
  EleveldRemimazolam(
      minAge: 1,
      maxAge: 105,
      minHeight: 50,
      maxHeight: 210,
      minWeight: 1,
      maxWeight: 250,
      target: Target.EffectSite,
      drug: Drug.remimazolam,
      targetUnit: TargetUnit.mcgPerMl),
  
  // KEEP NONE FOR COMPATIBILITY
  None(
      minAge: 0,
      maxAge: 999,
      minHeight: 0,
      maxHeight: 999,
      minWeight: 0,
      maxWeight: 999,
      target: Target.EffectSite,
      drug: Drug.propofol,
      targetUnit: TargetUnit.mcgPerMl);

  @override
  String toString() {
    return name;
  }

  bool withinAge(int age) {
    if (age > maxAge || age < minAge) {
      return false;
    } else {
      return true;
    }
  }

  bool withinHeight(int height) {
    if (height > maxHeight || height < minHeight) {
      return false;
    } else {
      return true;
    }
  }

  bool withinWeight(int weight) {
    if (weight > maxWeight || weight < minWeight) {
      return false;
    } else {
      return true;
    }
  }

  bool isEnable({required int age, required int height, required int weight}) {
    return target == Target.Plasma
        ? (withinAge(age) && withinWeight(weight))
        : (withinAge(age) && withinHeight(height) && withinWeight(weight));
  }

  bool isRunnable(
      {required int? age,
        required int? height,
        required int? weight,
        required double? target,
        required int? duration}) {
    return this.target == Target.Plasma
        ? (age != null) &&
        (weight != null) &&
        (target != null) &&
        (duration != null)
        : (age != null) &&
        (weight != null) &&
        (target != null) &&
        (duration != null) &&
        (height != null);
  }

  double bmi(int weight, int height) {
    return (weight / pow((height / 100), 2));
  }

  Map<String, Object> checkConstraints({
    required int weight,
    required int height,
    required int age,
    required Sex sex,
  }) {
    bool isAssertive = true;
    String text = '';
    if (this == Model.Marsh ||
        this == Model.Paedfusor ||
        this == Model.Kataria) {
      // text = 'Plasma';
      return {'assertion': isAssertive, 'text': text};
    } else if (this == Model.Schnider) {
      double tmpBMI = bmi(weight, height);
      double minBMI = 14;
      double maxBMI = sex == Sex.Male ? 42 : 39;
      isAssertive = tmpBMI >= minBMI && tmpBMI <= maxBMI;
      text = isAssertive ? '' : '[BMI] min: $minBMI and max: $maxBMI';
      return {'assertion': isAssertive, 'text': text};
    } else if (this == Model.Eleveld) {
      // text = 'Effect Site';
      return {'assertion': isAssertive, 'text': text};
    }
    return {'assertion': isAssertive, 'text': text};
  }

  ValidationResult validate({
    required int weight,
    required int height,
    required int age,
    required Sex sex,
  }) {
    return ValidationResult.fromMap(
      checkConstraints(
        weight: weight,
        height: height,
        age: age,
        sex: sex,
      ),
    );
  }

  final int minAge;
  final int maxAge;
  final int minHeight;
  final int maxHeight;
  final int minWeight;
  final int maxWeight;
  final Target target;
  final Drug drug;
  final TargetUnit targetUnit;

  const Model({
    required this.minAge,
    required this.maxAge,
    required this.minHeight,
    required this.maxHeight,
    required this.minWeight,
    required this.maxWeight,
    required this.target,
    required this.drug,
    required this.targetUnit,
  });
  
  /// Get target label for UI display
  String getTargetLabel(BuildContext context) {
    return '${target.toLocalizedString(context)} (${targetUnit.displayName})';
  }
}