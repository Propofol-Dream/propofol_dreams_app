import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/infusion_regime_data.dart';

void main() {
  group('Raw Bolus Demonstration', () {
    test('Show raw bolus vs rounded bolus comparison', () {
      const Sex sex = Sex.Male;
      const int weight = 70;
      const int height = 170;
      const int age = 35;
      const double target = 3.0;
      const int duration = 255;

      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      // Test with Schnider model (effect-site targeting with bolus)
      final pump = Pump(
        timeStep: const Duration(seconds: 1),
        concentration: 10, // 10 mg/mL propofol
        maxPumpRate: 1200,
        target: target,
        duration: const Duration(minutes: duration),
      );

      final simulation = PDSim.Simulation(
        model: Model.Schnider,
        patient: patient,
        pump: pump,
      );

      final results = simulation.estimate;

      final infusionRegimeData = InfusionRegimeData.fromSimulation(
        times: results.times,
        pumpInfs: results.pumpInfs,
        cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
        density: 10,
        totalDuration: const Duration(minutes: duration),
        isEffectSiteTargeting: Model.Schnider.target.name == 'EffectSite',
        drugConcentrationMgMl: 10.0,
      );

      print('\n=== RAW BOLUS DEMONSTRATION ===');
      print('Model: ${Model.Schnider.name}');
      print('Drug: Propofol 10 mg/mL');
      print('Target: $target mcg/mL (${Model.Schnider.target.name})');
      print('Patient: ${sex.name}, ${age}y, ${height}cm, ${weight}kg');
      print('');

      if (infusionRegimeData.rows.isNotEmpty) {
        final firstRow = infusionRegimeData.rows.first;
        
        print('BOLUS VALUES:');
        print('  Rounded bolus: ${firstRow.bolus.toStringAsFixed(2)} mL');
        if (firstRow.rawBolus != null) {
          print('  Raw bolus (unrounded): ${firstRow.rawBolus!.toStringAsFixed(6)} mL');
          print('  Difference: ${(firstRow.rawBolus! - firstRow.bolus).toStringAsFixed(6)} mL');
        } else {
          print('  Raw bolus: N/A (no bolus for this model/target combination)');
        }
        print('');
        
        print('FIRST 15 MINUTES:');
        print('  Bolus: ${firstRow.bolus.toStringAsFixed(2)} mL');
        print('  Infusion rate: ${firstRow.infusionRate.toStringAsFixed(2)} mL/hr');
        print('  Total volume: ${firstRow.accumulatedVolume.toStringAsFixed(2)} mL');
        print('');
        
        // This simulates what the TCI screen will now print
        print('TCI SCREEN OUTPUT FORMAT:');
        final outputData = {
          'screen': 'TCI',
          'model': Model.Schnider,
          'drug': 'Propofol',
          'drug_unit': '10 mg/mL',
          'patient': patient,
          'target': target,
          'duration': duration,
          'total_volume': infusionRegimeData.totalVolume.toStringAsFixed(1),
          'max_rate': infusionRegimeData.maxInfusionRate.toStringAsFixed(1),
          'first_15min_bolus': '${firstRow.bolus.toStringAsFixed(2)} mL',
          'first_15min_bolus_raw': firstRow.rawBolus != null ? '${firstRow.rawBolus!.toStringAsFixed(6)} mL' : 'N/A',
          'first_15min_rate': '${firstRow.infusionRate.toStringAsFixed(2)} mL/hr',
          'first_15min_total': '${firstRow.accumulatedVolume.toStringAsFixed(2)} mL',
        };
        print(outputData);
      }

      // Verify the functionality works
      expect(infusionRegimeData.rows.isNotEmpty, true);
      expect(infusionRegimeData.rows.first.rawBolus, isNotNull);
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