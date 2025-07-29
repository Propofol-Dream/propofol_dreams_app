import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'drug_unit.dart';

enum Drug {
  // Propofol concentrations
  propofol10mg(
    displayName: 'Propofol',
    concentration: 10.0,
    concentrationUnit: DrugUnit.mgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.amber,
    darkColor: Colors.amberAccent,
  ),
  propofol20mg(
    displayName: 'Propofol',
    concentration: 20.0,
    concentrationUnit: DrugUnit.mgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.amber,
    darkColor: Colors.amberAccent,
  ),

  // Remifentanil concentrations
  remifentanil20mcg(
    displayName: 'Remifentanil',
    concentration: 20.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.blue,
    darkColor: Colors.lightBlue,
  ),
  remifentanil40mcg(
    displayName: 'Remifentanil',
    concentration: 40.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.indigo,
    darkColor: Colors.lightBlueAccent,
  ),
  remifentanil50mcg(
    displayName: 'Remifentanil',
    concentration: 50.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.red,
    darkColor: Colors.redAccent,
  ),
  
  // Other drugs (single concentrations for now)
  dexmedetomidine(
    displayName: 'Dexmedetomidine',
    concentration: 4.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.green,
    darkColor: Colors.lightGreen,
  ),
  remimazolam1mg(
    displayName: 'Remimazolam',
    concentration: 1.0,
    concentrationUnit: DrugUnit.mgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.purple,
    darkColor: Colors.purpleAccent,
  ),
  remimazolam2mg(
    displayName: 'Remimazolam',
    concentration: 2.0,
    concentrationUnit: DrugUnit.mgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.purple,
    darkColor: Colors.purpleAccent,
  );

  const Drug({
    required this.displayName,
    required this.concentration,
    required this.concentrationUnit,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
  });

  final String displayName;
  final double concentration;
  final DrugUnit concentrationUnit;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  
  /// Get the appropriate color based on the current theme brightness
  Color getColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }
  
  /// Get display string with concentration and unit
  String get displayWithConcentration {
    final concentrationStr = concentration < 1 
        ? concentration.toStringAsFixed(1) 
        : concentration.toStringAsFixed(0);
    return '$displayName ($concentrationStr ${concentrationUnit.displayName})';
  }
  
  @override
  String toString() => displayName;
}

/// Extension for drug type checking
extension DrugTypeExtension on Drug {
  bool get isRemifentanil => this == Drug.remifentanil20mcg || 
                             this == Drug.remifentanil40mcg || 
                             this == Drug.remifentanil50mcg;
  
  bool get isPropofol => this == Drug.propofol10mg || this == Drug.propofol20mg;
  
  bool get isDexmedetomidine => this == Drug.dexmedetomidine;
  
  bool get isRemimazolam => this == Drug.remimazolam1mg || this == Drug.remimazolam2mg;
}

/// Helper class for drug concentration with unit
class DrugConcentration {
  final double value;
  final DrugUnit unit;
  
  const DrugConcentration({
    required this.value, 
    required this.unit,
  });
  
  
  /// Get display string with appropriate unit
  String get displayString {
    final displayValue = value < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
    return '$displayValue ${unit.displayName}';
  }
}