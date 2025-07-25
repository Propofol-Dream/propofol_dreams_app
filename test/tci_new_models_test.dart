import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/infusion_regime_data.dart';

void main() {
  group('TCI Screen Model Integration Test', () {
    // Test patient: 35 yo male, 70 kg, 170 cm
    const Sex sex = Sex.Male;
    const int weight = 70;
    const int height = 170;
    const int age = 35;
    const double target = 3.0; // mcg/mL for propofol, ng/mL for opioids
    const int duration = 255; // 4 hours and 15 minutes

    test('Minto Remifentanil TCI simulation works', () {
      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      final pump = Pump(
        timeStep: const Duration(seconds: 1),
        concentration: 50, // 50 mcg/mL for remifentanil
        maxPumpRate: 1200,
        target: target,
        duration: const Duration(minutes: duration),
      );

      final simulation = PDSim.Simulation(
        model: Model.Minto,
        patient: patient,
        pump: pump,
      );

      final results = simulation.estimate;

      // Verify simulation produces valid results
      expect(results.times.isNotEmpty, true);
      expect(results.pumpInfs.isNotEmpty, true);
      expect(results.cumulativeInfusedVolumes.isNotEmpty, true);

      // Create infusion regime data
      final infusionRegimeData = InfusionRegimeData.fromSimulation(
        times: results.times,
        pumpInfs: results.pumpInfs,
        cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
        density: 50,
        totalDuration: const Duration(minutes: duration),
        isEffectSiteTargeting: Model.Minto.target.name == 'EffectSite',
        drugConcentrationMgMl: 50.0,
      );

      // Verify infusion regime data is created
      expect(infusionRegimeData.rows.isNotEmpty, true);
      expect(infusionRegimeData.totalBolus, greaterThanOrEqualTo(0));
      expect(infusionRegimeData.totalVolume, greaterThan(0));

      print('Minto TCI Results:');
      print('Total bolus: ${infusionRegimeData.totalBolus.toStringAsFixed(2)} mL');
      print('Total volume: ${infusionRegimeData.totalVolume.toStringAsFixed(2)} mL');
      print('Max rate: ${infusionRegimeData.maxInfusionRate.toStringAsFixed(2)} mL/hr');
    });

    test('Hannivoort Dexmedetomidine TCI simulation works', () {
      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

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

      // Verify simulation produces valid results
      expect(results.times.isNotEmpty, true);
      expect(results.pumpInfs.isNotEmpty, true);
      expect(results.cumulativeInfusedVolumes.isNotEmpty, true);

      // Create infusion regime data
      final infusionRegimeData = InfusionRegimeData.fromSimulation(
        times: results.times,
        pumpInfs: results.pumpInfs,
        cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
        density: 4,
        totalDuration: const Duration(minutes: duration),
        isEffectSiteTargeting: Model.Hannivoort.target.name == 'EffectSite',
        drugConcentrationMgMl: 4.0,
      );

      // Verify infusion regime data is created
      expect(infusionRegimeData.rows.isNotEmpty, true);
      expect(infusionRegimeData.totalBolus, greaterThanOrEqualTo(0));
      expect(infusionRegimeData.totalVolume, greaterThan(0));

      print('Hannivoort Dexmedetomidine TCI Results:');
      print('Total bolus: ${infusionRegimeData.totalBolus.toStringAsFixed(2)} mL');
      print('Total volume: ${infusionRegimeData.totalVolume.toStringAsFixed(2)} mL');
      print('Max rate: ${infusionRegimeData.maxInfusionRate.toStringAsFixed(2)} mL/hr');
    });

    test('All available models are selectable and work in TCI calculations', () {
      final availableModels = [
        Model.Marsh,
        Model.Schnider, 
        Model.Eleveld,
        Model.Paedfusor,
        Model.Kataria,
        Model.Minto,
        Model.Hannivoort,
      ];

      for (final model in availableModels) {
        // Verify model is runnable with test parameters
        final isRunnable = model.isRunnable(
          age: age,
          height: height,
          weight: weight,
          target: target,
          duration: duration,
        );

        expect(isRunnable, true, reason: '$model should be runnable with test parameters');

        // Verify model has proper target unit configuration
        expect(model.targetUnit, isNotNull, reason: '$model should have target unit');
        
        print('✓ $model - Target: ${model.target.name} (${model.targetUnit.displayName})');
      }
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