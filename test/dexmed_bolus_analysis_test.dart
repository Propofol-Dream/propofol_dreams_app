import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/infusion_regime_data.dart';

void main() {
  group('Dexmedetomidine Bolus Analysis', () {
    test('Analyze bolus calculation across different target concentrations', () {
      const Sex sex = Sex.Female;
      const int weight = 70;
      const int height = 170;
      const int age = 40;
      const int duration = 240;

      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      print('\n=== DEXMEDETOMIDINE BOLUS ANALYSIS ===');
      print('Model: ${Model.Hannivoort.name}');
      print('Drug: Dexmedetomidine 4 mcg/mL');
      print('Patient: ${sex.name}, ${age}y, ${height}cm, ${weight}kg');
      print('Target: ${Model.Hannivoort.target.name} targeting');
      print('');

      // Test various target concentrations
      final targetConcentrations = [1.0, 1.5, 1.8, 1.9, 2.0, 2.5, 3.0];
      
      for (final target in targetConcentrations) {
        final pump = Pump(
          timeStep: const Duration(seconds: 1),
          concentration: 4, // 4 mcg/mL for dexmedetomidine
          maxPumpRate: 1200,
          target: target,
          duration: const Duration(minutes: duration),
        );

        final simulation = PDSim.Simulation(
          model: Model.Hannivoort,
          patient: patient,
          pump: pump,
        );

        final results = simulation.estimate;

        final infusionRegimeData = InfusionRegimeData.fromSimulation(
          times: results.times,
          pumpInfs: results.pumpInfs,
          cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
          density: 4,
          totalDuration: const Duration(minutes: duration),
          isEffectSiteTargeting: Model.Hannivoort.target.name == 'EffectSite',
          drugConcentrationMgMl: 4.0,
        );

        if (infusionRegimeData.rows.isNotEmpty) {
          final firstRow = infusionRegimeData.rows.first;
          
          print('Target: ${target.toStringAsFixed(1)} ng/mL');
          print('  Rounded bolus: ${firstRow.bolus.toStringAsFixed(2)} mL');
          if (firstRow.rawBolus != null) {
            print('  Raw bolus: ${firstRow.rawBolus!.toStringAsFixed(6)} mL');
            print('  Difference: ${(firstRow.rawBolus! - firstRow.bolus).toStringAsFixed(6)} mL');
          } else {
            print('  Raw bolus: N/A');
          }
          print('  Infusion rate: ${firstRow.infusionRate.toStringAsFixed(2)} mL/hr');
          print('  Total volume: ${infusionRegimeData.totalVolume.toStringAsFixed(1)} mL');
          print('  Max rate: ${infusionRegimeData.maxInfusionRate.toStringAsFixed(1)} mL/hr');
          
          // Analyze the first few seconds of simulation to understand bolus behavior
          if (results.pumpInfs.length > 10) {
            final firstSecondRates = results.pumpInfs.take(10).toList();
            final maxInitialRate = firstSecondRates.reduce((a, b) => a > b ? a : b);
            final hasHighInitialRate = maxInitialRate > firstRow.infusionRate * 4.0; // Significantly higher than average
            print('  Initial rate pattern: ${hasHighInitialRate ? "Bolus-like" : "Continuous"}');
            print('  Max initial rate: ${maxInitialRate.toStringAsFixed(2)} mg/hr');
          }
          print('');
        }
      }

      print('=== ANALYSIS NOTES ===');
      print('1. Hannivoort model uses PLASMA targeting (not effect-site)');
      print('2. Bolus calculation depends on the optimization algorithm');
      print('3. Small raw bolus values (<1.0 mL) get rounded to 0.1 mL increments');
      print('4. Very small raw bolus values (<0.05 mL) get rounded to 0.0 mL');
      print('5. The threshold behavior explains the 0.0 vs 0.1 mL difference');
    });

    test('Examine the exact rounding logic', () {
      // Test the rounding logic used in InfusionRegimeData
      print('\n=== ROUNDING LOGIC ANALYSIS ===');
      
      final testValues = [0.01, 0.03, 0.05, 0.08, 0.12, 0.45, 0.51, 0.89, 1.23, 1.67];
      
      for (final rawValue in testValues) {
        double rounded = rawValue;
        
        // This is the exact logic from InfusionRegimeData.fromSimulation
        if (rounded < 1.0 && rounded > 0) {
          rounded = (rounded * 10).round() / 10.0; // Round to 0.1 mL
        } else {
          rounded = rounded.round().toDouble(); // Round to nearest mL
        }
        if (rounded < 0) rounded = 0.0;
        
        print('Raw: ${rawValue.toStringAsFixed(3)} mL → Rounded: ${rounded.toStringAsFixed(1)} mL');
      }
      
      print('');
      print('EXPLANATION:');
      print('- Values < 1.0 mL: Round to nearest 0.1 mL');
      print('- Values ≥ 1.0 mL: Round to nearest whole mL');
      print('- The 0.0 vs 0.1 mL difference occurs at the 0.05 mL threshold');
      print('- Raw values 0.000-0.049 → 0.0 mL');
      print('- Raw values 0.050-0.149 → 0.1 mL');
    });
  });
}

extension on InfusionRegimeData {
  /// Calculate maximum infusion rate across all intervals
  double get maxInfusionRate {
    if (rows.isEmpty) return 0.0;
    return rows.map((row) => row.infusionRate).reduce((a, b) => a > b ? a : b);
  }
}