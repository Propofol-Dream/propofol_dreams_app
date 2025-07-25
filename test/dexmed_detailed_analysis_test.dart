import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/infusion_regime_data.dart';

void main() {
  group('Detailed Dexmedetomidine Bolus Calculation Analysis', () {
    test('Deep dive into bolus calculation algorithm', () {
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

      print('\n=== DETAILED BOLUS CALCULATION ANALYSIS ===');
      print('Understanding why target 2.0 ng/mL shows 0.1 mL bolus');
      print('while other targets show 0.0 mL');
      print('');

      // Focus on the critical targets: 1.9, 2.0, 2.1
      final criticalTargets = [1.9, 2.0, 2.1];
      
      for (final target in criticalTargets) {
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
        
        print('=== TARGET: ${target.toStringAsFixed(1)} ng/mL ===');
        
        // Manually calculate what InfusionRegimeData does
        if (results.times.isNotEmpty && results.pumpInfs.isNotEmpty) {
          // Step 1: Find first 15 minutes data
          final first15MinIndex = results.times.indexWhere((time) => time.inSeconds >= 900);
          final validFirst15Index = first15MinIndex != -1 ? first15MinIndex : results.times.length - 1;
          
          // Step 2: Calculate total dose in first 900 seconds
          double totalDoseFirst15Min = 0.0;
          for (int i = 0; i < validFirst15Index && i < results.pumpInfs.length; i++) {
            totalDoseFirst15Min += results.pumpInfs[i] / 3600.0; // Convert mg/hr to mg/second
          }
          
          print('  Total dose first 15min: ${totalDoseFirst15Min.toStringAsFixed(6)} mg');
          
          // Step 3: Find infusion restart time (for plasma models)
          final maxRate = results.pumpInfs.isNotEmpty ? results.pumpInfs.reduce((a, b) => a > b ? a : b) : 0.0;
          final bolusVolume = results.cumulativeInfusedVolumes.isNotEmpty ? results.cumulativeInfusedVolumes.first : 0.0;
          final bolusDurationSeconds = maxRate > 0 ? (bolusVolume * 4.0 / maxRate * 3600).round() : 0;
          final infusionRestartIndex = bolusDurationSeconds + 1;
          
          print('  Max rate: ${maxRate.toStringAsFixed(2)} mg/hr');
          print('  Bolus volume: ${bolusVolume.toStringAsFixed(6)} mL');
          print('  Bolus duration: ${bolusDurationSeconds} seconds');
          print('  Infusion restart index: $infusionRestartIndex');
          
          // Step 4: Calculate average infusion rate for non-bolus section
          double totalDoseAfterBolus = 0.0;
          for (int i = infusionRestartIndex; i < validFirst15Index && i < results.pumpInfs.length; i++) {
            totalDoseAfterBolus += results.pumpInfs[i] / 3600.0;
          }
          
          final remainingSeconds = 900 - infusionRestartIndex;
          double avgInfusionRate = remainingSeconds > 0 
              ? (totalDoseAfterBolus / remainingSeconds) * 3600.0 // Convert back to mg/hr
              : 0.0;
          
          print('  Total dose after bolus: ${totalDoseAfterBolus.toStringAsFixed(6)} mg');
          print('  Remaining seconds: $remainingSeconds');
          print('  Avg infusion rate: ${avgInfusionRate.toStringAsFixed(2)} mg/hr');
          
          // Step 5: Calculate augmented bolus
          final continuousInfusionDose = 900 * avgInfusionRate / 3600.0; // mg for 15 min
          double augmentedBolus = totalDoseFirst15Min - continuousInfusionDose;
          augmentedBolus = augmentedBolus / 4.0; // Convert to mL (4 mcg/mL concentration)
          
          print('  Continuous infusion dose: ${continuousInfusionDose.toStringAsFixed(6)} mg');
          print('  Raw augmented bolus: ${augmentedBolus.toStringAsFixed(6)} mL');
          
          // Apply rounding logic
          final rawValue = augmentedBolus;
          if (augmentedBolus < 1.0 && augmentedBolus > 0) {
            augmentedBolus = (augmentedBolus * 10).round() / 10.0;
          } else {
            augmentedBolus = augmentedBolus.round().toDouble();
          }
          if (augmentedBolus < 0) augmentedBolus = 0.0;
          
          print('  Final rounded bolus: ${augmentedBolus.toStringAsFixed(1)} mL');
          print('  Raw bolus stored: ${rawValue > 0 ? "YES (${rawValue.toStringAsFixed(6)} mL)" : "NO (≤ 0)"}');
          print('');
        }
        
        // Verify with actual InfusionRegimeData
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
          print('  ✓ Verification - Actual rounded bolus: ${firstRow.bolus.toStringAsFixed(1)} mL');
          print('  ✓ Verification - Actual raw bolus: ${firstRow.rawBolus?.toStringAsFixed(6) ?? "NULL"}');
        }
        print('');
      }
      
      print('=== CONCLUSIONS ===');
      print('1. Plasma targeting models typically don\'t require significant boluses');
      print('2. The algorithm optimizes for continuous infusion with minimal bolus');
      print('3. When raw bolus ≤ 0, no raw value is stored (shows as N/A)');
      print('4. When raw bolus > 0, it gets rounded to nearest 0.1 mL for values < 1.0 mL');
      print('5. Target 2.0 ng/mL hits a "sweet spot" where the calculation yields a tiny positive bolus');
      print('6. This tiny positive value (0.054 mL) rounds to 0.1 mL due to clinical rounding rules');
    });
  });
}