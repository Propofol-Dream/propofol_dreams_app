import 'package:flutter/material.dart';
import 'drug_unit.dart';

enum Drug {
  propofol(
    displayName: 'Propofol',
    concentration: 10.0,
    concentrationUnit: DrugUnit.mgPerMl,
    color: Colors.blue,
  ),
  remifentanilMinto(
    displayName: 'Remifentanil (Minto)',
    concentration: 50.0,
    concentrationUnit: DrugUnit.mgPerMl,
    color: Colors.red,
  ),
  remifentanilEleveld(
    displayName: 'Remifentanil (Eleveld)',
    concentration: 50.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    color: Colors.orange,
  ),
  dexmedetomidine(
    displayName: 'Dexmedetomidine',
    concentration: 4.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    color: Colors.green,
  ),
  remimazolam(
    displayName: 'Remimazolam',
    concentration: 1.0,
    concentrationUnit: DrugUnit.mgPerMl,
    color: Colors.purple,
  );

  const Drug({
    required this.displayName,
    required this.concentration,
    required this.concentrationUnit,
    required this.color,
  });

  final String displayName;
  final double concentration;
  final DrugUnit concentrationUnit;
  final Color color;
  
  /// Get concentration in standardized mg/mL for internal calculations
  double get concentrationInMgPerMl {
    return concentration * concentrationUnit.toMgPerMlFactor;
  }
  
  @override
  String toString() => displayName;
}

/// Helper class for drug concentration with unit
class DrugConcentration {
  final double value;
  final DrugUnit unit;
  
  const DrugConcentration({
    required this.value, 
    required this.unit,
  });
  
  /// Get concentration in standardized mg/mL for calculations
  double get concentrationInMgPerMl => value * unit.toMgPerMlFactor;
  
  /// Get display string with appropriate unit
  String get displayString {
    final displayValue = value < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
    return '$displayValue ${unit.displayName}';
  }
}