import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/infusion_regime_data.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/parameters.dart';

void main() {
  group('Comprehensive Model/Drug Parameter Tests', () {
    // Standard test patient: 35 yo male, 70 kg, 170 cm
    const Sex sex = Sex.Male;
    const int weight = 70;
    const int height = 170;
    const int age = 35;
    const double target = 3.0;
    const int duration = 240; // 4 hours

    /// Test all model/drug combinations with their default concentrations
    final List<({Model model, Drug drug, double target})> modelDrugCombinations = [
      // Propofol models
      (model: Model.Marsh, drug: Drug.propofol10mg, target: 3.0),
      (model: Model.Schnider, drug: Drug.propofol10mg, target: 3.0),
      (model: Model.Eleveld, drug: Drug.propofol10mg, target: 3.0),
      (model: Model.Paedfusor, drug: Drug.propofol10mg, target: 3.0),
      (model: Model.Kataria, drug: Drug.propofol10mg, target: 3.0),
      
      // Remifentanil models
      (model: Model.Minto, drug: Drug.remifentanil50mcg, target: 3.0),
      
      // Dexmedetomidine models
      (model: Model.Hannivoort, drug: Drug.dexmedetomidine, target: 3.0),
      
      // Remimazolam models
      // Note: Remimazolam models need to be added to the Model enum first
    ];

    test('Output pharmacokinetic parameters (Vs, Ks, CLs) for all model/drug combinations', () {
      print('\n=== COMPREHENSIVE PHARMACOKINETIC PARAMETERS OUTPUT ===\n');
      
      for (final combination in modelDrugCombinations) {
        final model = combination.model;
        final drug = combination.drug;
        final testTarget = combination.target;
        
        try {
          // Calculate PK parameters
          final params = model.calculatePKParameters(
            sex: sex,
            weight: weight,
            height: height,
            age: age,
          );
          
          // Print detailed parameter output
          print('Model: ${model.name} | Drug: ${drug.displayName} (${drug.concentration}${drug.concentrationUnit.displayName})');
          print('  Target: ${model.target.name} targeting (${model.targetUnit.displayName})');
          print('  Patient: ${sex.name}, ${age}y, ${height}cm, ${weight}kg');
          print('  VOLUMES (L):');
          print('    V1 = ${params.V1.toStringAsFixed(4)}');
          print('    V2 = ${params.V2.toStringAsFixed(4)}');
          print('    V3 = ${params.V3.toStringAsFixed(4)}');
          print('  CLEARANCES (L/min):');
          print('    Cl1 = ${params.Cl1.toStringAsFixed(4)}');
          print('    Cl2 = ${params.Cl2.toStringAsFixed(4)}');
          print('    Cl3 = ${params.Cl3.toStringAsFixed(4)}');
          print('  RATE CONSTANTS (min⁻¹):');
          print('    k10 = ${params.k10.toStringAsFixed(4)}');
          print('    k12 = ${params.k12.toStringAsFixed(4)}');
          print('    k21 = ${params.k21.toStringAsFixed(4)}');
          print('    k13 = ${params.k13.toStringAsFixed(4)}');
          print('    k31 = ${params.k31.toStringAsFixed(4)}');
          print('    ke0 = ${params.ke0.toStringAsFixed(4)}');
          
          if (params.ce50 != null) {
            print('  BIS PARAMETERS:');
            print('    ce50 = ${params.ce50!.toStringAsFixed(4)}');
            print('    baseline BIS = ${params.baselineBIS!.toStringAsFixed(1)}');
            print('    delay BIS = ${params.delayBIS!.toStringAsFixed(1)}');
          }
          print('');
          
          // Verify parameters are not zero (quality check)
          expect(params.V1, greaterThan(0), reason: '$model V1 should be > 0');
          expect(params.Cl1, greaterThan(0), reason: '$model Cl1 should be > 0');
          expect(params.k10, greaterThan(0), reason: '$model k10 should be > 0');
          
        } catch (e) {
          print('ERROR calculating parameters for $model with ${drug.displayName}: $e');
        }
      }
    });

    test('TCI simulation results for all model/drug combinations', () {
      print('\n=== TCI SIMULATION RESULTS ===\n');
      
      for (final combination in modelDrugCombinations) {
        final model = combination.model;
        final drug = combination.drug;
        final testTarget = combination.target;
        
        try {
          // Check if model is runnable with test parameters
          final isRunnable = model.isRunnable(
            age: age,
            height: height,
            weight: weight,
            target: testTarget,
            duration: duration,
          );
          
          if (!isRunnable) {
            print('SKIPPED: $model with ${drug.displayName} - not runnable with test parameters');
            continue;
          }
          
          final patient = Patient(
            weight: weight,
            age: age,
            height: height,
            sex: sex,
          );

          final pump = Pump(
            timeStep: const Duration(seconds: 1),
            concentration: drug.concentration,
            maxPumpRate: 1200,
            target: testTarget,
            duration: const Duration(minutes: duration),
          );

          final simulation = PDSim.Simulation(
            model: model,
            patient: patient,
            pump: pump,
          );

          final results = simulation.estimate;

          // Create infusion regime data
          final infusionRegimeData = InfusionRegimeData.fromSimulation(
            times: results.times,
            pumpInfs: results.pumpInfs,
            cumulativeInfusedVolumes: results.cumulativeInfusedVolumes,
            density: drug.concentration.round(), // Legacy parameter
            totalDuration: const Duration(minutes: duration),
            isEffectSiteTargeting: model.target.name == 'EffectSite',
            drugConcentrationMgMl: drug.concentration,
          );

          // Print simulation results
          print('Model: ${model.name} | Drug: ${drug.displayName} (${drug.concentration}${drug.concentrationUnit.displayName})');
          print('  Target: $testTarget ${model.targetUnit.displayName} (${model.target.name})');
          print('  Total bolus: ${infusionRegimeData.totalBolus.toStringAsFixed(2)} mL');
          print('  Total volume: ${infusionRegimeData.totalVolume.toStringAsFixed(2)} mL');
          print('  Max rate: ${infusionRegimeData.maxInfusionRate.toStringAsFixed(2)} mL/hr');
          
          // Print first 15 minutes detail
          if (infusionRegimeData.rows.isNotEmpty) {
            final firstRow = infusionRegimeData.rows.first;
            print('  First 15min: Bolus ${firstRow.bolus.toStringAsFixed(2)} mL + Rate ${firstRow.infusionRate.toStringAsFixed(2)} mL/hr');
          }
          print('');

          // Verify simulation produces valid results
          expect(results.times.isNotEmpty, true);
          expect(results.pumpInfs.isNotEmpty, true);
          expect(results.cumulativeInfusedVolumes.isNotEmpty, true);
          expect(infusionRegimeData.rows.isNotEmpty, true);
          expect(infusionRegimeData.totalBolus, greaterThanOrEqualTo(0));
          expect(infusionRegimeData.totalVolume, greaterThan(0));
          
        } catch (e) {
          print('ERROR simulating $model with ${drug.displayName}: $e');
        }
      }
    });

    test('All model constraints and capabilities check', () {
      print('\n=== MODEL CONSTRAINTS AND CAPABILITIES ===\n');
      
      final allModels = [
        Model.Marsh, Model.Schnider, Model.Eleveld, Model.Paedfusor, 
        Model.Kataria, Model.Minto, Model.Hannivoort, Model.EleMarsh, Model.None
      ];
      
      for (final model in allModels) {
        if (model == Model.None) continue;
        
        print('Model: ${model.name}');
        print('  Age range: ${model.minAge}-${model.maxAge} years');
        print('  Height range: ${model.minHeight}-${model.maxHeight} cm');
        print('  Weight range: ${model.minWeight}-${model.maxWeight} kg');
        print('  Target: ${model.target.name} (${model.targetUnit.displayName})');
        
        // Check if model is enabled with test parameters
        final isEnabled = model.isEnable(age: age, height: height, weight: weight);
        final isRunnable = model.isRunnable(
          age: age, height: height, weight: weight, target: target, duration: duration
        );
        
        print('  Test patient compatibility: Enabled=$isEnabled, Runnable=$isRunnable');
        print('');
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