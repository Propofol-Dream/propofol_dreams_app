import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/infusion_regime_data.dart';

void main() {
  group('TCI Screen New Models Integration Test', () {
    // Test patient: 35 yo male, 70 kg, 170 cm
    const Sex sex = Sex.Male;
    const int weight = 70;
    const int height = 170;
    const int age = 35;
    const double target = 3.0; // mcg/mL for propofol, ng/mL for opioids
    const int duration = 240; // 4 hours

    test('Minto Remifentanil TCI simulation works', () {
      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      final pump = Pump(
        timeStep: const Duration(seconds: 1),
        density: 50, // 50 mg/mL for remifentanil
        maxPumpRate: 1200,
        target: target,
        duration: const Duration(minutes: duration),
      );

      final simulation = PDSim.Simulation(
        model: Model.MintoRemifentanil,
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
        isEffectSiteTargeting: Model.MintoRemifentanil.target.name == 'EffectSite',
        drugConcentrationMgMl: Model.MintoRemifentanil.drug.concentrationInMgPerMl,
      );

      // Verify infusion regime data is created
      expect(infusionRegimeData.rows.isNotEmpty, true);
      expect(infusionRegimeData.totalBolus, greaterThanOrEqualTo(0));
      expect(infusionRegimeData.totalVolume, greaterThan(0));

      print('Minto Remifentanil TCI Results:');
      print('Total bolus: ${infusionRegimeData.totalBolus.toStringAsFixed(2)} mL');
      print('Total volume: ${infusionRegimeData.totalVolume.toStringAsFixed(2)} mL');
      print('Max rate: ${infusionRegimeData.maxInfusionRate.toStringAsFixed(2)} mL/hr');
    });

    test('Eleveld Remifentanil TCI simulation works', () {
      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      final pump = Pump(
        timeStep: const Duration(seconds: 1),
        density: 50, // mcg/mL for Eleveld remifentanil  
        maxPumpRate: 1200,
        target: target,
        duration: const Duration(minutes: duration),
      );

      final simulation = PDSim.Simulation(
        model: Model.EleveldRemifentanil,
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
        isEffectSiteTargeting: Model.EleveldRemifentanil.target.name == 'EffectSite',
        drugConcentrationMgMl: Model.EleveldRemifentanil.drug.concentrationInMgPerMl,
      );

      // Verify infusion regime data is created
      expect(infusionRegimeData.rows.isNotEmpty, true);
      expect(infusionRegimeData.totalBolus, greaterThanOrEqualTo(0));
      expect(infusionRegimeData.totalVolume, greaterThan(0));

      print('Eleveld Remifentanil TCI Results:');
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
        density: 4, // mcg/mL for dexmedetomidine
        maxPumpRate: 1200,
        target: target,
        duration: const Duration(minutes: duration),
      );

      final simulation = PDSim.Simulation(
        model: Model.HannivoortDexmedetomidine,
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
        isEffectSiteTargeting: Model.HannivoortDexmedetomidine.target.name == 'EffectSite',
        drugConcentrationMgMl: Model.HannivoortDexmedetomidine.drug.concentrationInMgPerMl,
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

    test('Eleveld Remimazolam TCI simulation works', () {
      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      final pump = Pump(
        timeStep: const Duration(seconds: 1),
        density: 1, // mg/mL for remimazolam
        maxPumpRate: 1200,
        target: target,
        duration: const Duration(minutes: duration),
      );

      final simulation = PDSim.Simulation(
        model: Model.EleveldRemimazolam,
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
        density: 1,
        totalDuration: const Duration(minutes: duration),
        isEffectSiteTargeting: Model.EleveldRemimazolam.target.name == 'EffectSite',
        drugConcentrationMgMl: Model.EleveldRemimazolam.drug.concentrationInMgPerMl,
      );

      // Verify infusion regime data is created
      expect(infusionRegimeData.rows.isNotEmpty, true);
      expect(infusionRegimeData.totalBolus, greaterThanOrEqualTo(0));
      expect(infusionRegimeData.totalVolume, greaterThan(0));

      print('Eleveld Remimazolam TCI Results:');
      print('Total bolus: ${infusionRegimeData.totalBolus.toStringAsFixed(2)} mL');
      print('Total volume: ${infusionRegimeData.totalVolume.toStringAsFixed(2)} mL');
      print('Max rate: ${infusionRegimeData.maxInfusionRate.toStringAsFixed(2)} mL/hr');
    });

    test('All new models are selectable and work in TCI calculations', () {
      final newModels = [
        Model.MintoRemifentanil,
        Model.EleveldRemifentanil,
        Model.HannivoortDexmedetomidine,
        Model.EleveldRemimazolam,
      ];

      for (final model in newModels) {
        // Verify model is runnable with test parameters
        final isRunnable = model.isRunnable(
          age: age,
          height: height,
          weight: weight,
          target: target,
          duration: duration,
        );

        expect(isRunnable, true, reason: '$model should be runnable with test parameters');

        // Verify model has proper drug and target unit configuration
        expect(model.drug, isNotNull, reason: '$model should have associated drug');
        expect(model.targetUnit, isNotNull, reason: '$model should have target unit');
        
        print('✓ $model - Drug: ${model.drug.displayName}, Target: ${model.target.name} (${model.targetUnit.displayName})');
      }
    });
  });
}