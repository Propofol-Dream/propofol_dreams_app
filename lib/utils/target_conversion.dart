import '../models/target_unit.dart';

/// Utilities for converting between different target concentration units
class TargetConversion {
  /// Convert target value to standardized mcg/mL for internal calculations
  static double toStandardTarget(double value, TargetUnit unit) {
    return value * unit.toMcgPerMlFactor;
  }
  
  /// Convert from standardized mcg/mL to specified target unit
  static double fromStandardTarget(double mcgMlValue, TargetUnit unit) {
    return mcgMlValue / unit.toMcgPerMlFactor;
  }
  
  /// Convert between different target units directly
  static double convertBetweenTargetUnits(
    double value, 
    TargetUnit fromUnit, 
    TargetUnit toUnit,
  ) {
    if (fromUnit == toUnit) return value;
    
    // Convert to standard unit first, then to target unit
    final standardValue = toStandardTarget(value, fromUnit);
    return fromStandardTarget(standardValue, toUnit);
  }
  
  /// Format target value with appropriate precision for the unit
  static String formatTarget(double value, TargetUnit unit) {
    switch (unit) {
      case TargetUnit.mcgPerMl:
        return '${value.toStringAsFixed(1)} mcg/mL';
      case TargetUnit.ngPerMl:
        return '${value.toStringAsFixed(1)} ng/mL';
    }
  }
  
  /// Get appropriate interval for target input based on unit
  static double getTargetInterval(TargetUnit unit) {
    switch (unit) {
      case TargetUnit.mcgPerMl:
        return 0.5; // 0.5 mcg/mL increments
      case TargetUnit.ngPerMl:
        return 0.1; // 0.1 ng/mL increments
    }
  }
}

/// Utilities for converting between different drug concentration units
class DrugConcentrationConversion {
  /// Convert drug concentration to standardized mg/mL for internal calculations  
  static double toStandardConcentration(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'mg/ml':
        return value;
      case 'mcg/ml':
        return value / 1000.0; // Convert mcg to mg
      default:
        return value; // Assume mg/mL if unknown
    }
  }
  
  /// Smart rounding for different drug concentration ranges
  static double smartRoundConcentration(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'mg/ml':
        return value < 10 ? (value * 10).round() / 10 : value.round().toDouble();
      case 'mcg/ml':
        return value < 100 ? (value * 10).round() / 10 : value.round().toDouble();
      default:
        return value;
    }
  }
}