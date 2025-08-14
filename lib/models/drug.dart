import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'drug_unit.dart';
import 'target_unit.dart';
import '../l10n/generated/app_localizations.dart';

enum Drug {
  // Propofol concentrations
  propofol10mg(
    displayName: 'Propofol',
    concentration: 10.0,
    concentrationUnit: DrugUnit.mgPerMl,
    targetUnit: TargetUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.yellow,
    darkColor: Colors.yellowAccent,
  ),
  propofol20mg(
    displayName: 'Propofol',
    concentration: 20.0,
    concentrationUnit: DrugUnit.mgPerMl,
    targetUnit: TargetUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.yellow,
    darkColor: Colors.yellowAccent,
  ),

  // Remifentanil concentrations
  remifentanil20mcg(
    displayName: 'Remifentanil',
    concentration: 20.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    targetUnit: TargetUnit.ngPerMl,
    icon: Symbols.medication,
    lightColor: Colors.lightBlue,
    darkColor: Colors.lightBlueAccent,
  ),
  remifentanil40mcg(
    displayName: 'Remifentanil',
    concentration: 40.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    targetUnit: TargetUnit.ngPerMl,
    icon: Symbols.medication,
    lightColor: Colors.lightBlue,
    darkColor: Colors.lightBlueAccent,
  ),
  remifentanil50mcg(
    displayName: 'Remifentanil',
    concentration: 50.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    targetUnit: TargetUnit.ngPerMl,
    icon: Symbols.medication,
    lightColor: Colors.lightBlue,
    darkColor: Colors.lightBlueAccent,
  ),
  
  // Other drugs (single concentrations for now)
  dexmedetomidine(
    displayName: 'Dexmedetomidine',
    concentration: 4.0,
    concentrationUnit: DrugUnit.mcgPerMl,
    targetUnit: TargetUnit.ngPerMl,
    icon: Symbols.medication,
    lightColor: Colors.pink,
    darkColor: Colors.pinkAccent,
  ),
  remimazolam1mg(
    displayName: 'Remimazolam',
    concentration: 1.0,
    concentrationUnit: DrugUnit.mgPerMl,
    targetUnit: TargetUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.orange,
    darkColor: Colors.orangeAccent,
  ),
  remimazolam2mg(
    displayName: 'Remimazolam',
    concentration: 2.0,
    concentrationUnit: DrugUnit.mgPerMl,
    targetUnit: TargetUnit.mcgPerMl,
    icon: Symbols.medication,
    lightColor: Colors.orange,
    darkColor: Colors.orangeAccent,
  );

  const Drug({
    required this.displayName,
    required this.concentration,
    required this.concentrationUnit,
    required this.targetUnit,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
  });

  final String displayName;
  final double concentration;
  final DrugUnit concentrationUnit;
  final TargetUnit targetUnit;
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

/// Extension for drug localization
extension DrugLocalizationExtension on Drug {
  /// Get localized drug name from ARB files
  String toLocalizedString(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    switch (this) {
      case Drug.propofol10mg:
      case Drug.propofol20mg:
        return localizations.propofol;
      case Drug.remifentanil20mcg:
      case Drug.remifentanil40mcg:
      case Drug.remifentanil50mcg:
        return localizations.remifentanil;
      case Drug.dexmedetomidine:
        return localizations.dexmedetomidine;
      case Drug.remimazolam1mg:
      case Drug.remimazolam2mg:
        return localizations.remimazolam;
    }
  }
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