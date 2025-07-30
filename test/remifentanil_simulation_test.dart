import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/drug.dart';
import 'package:propofol_dreams_app/models/parameters.dart';

/// Configurable simulation test parameters
class SimulationTestConfig {
  final String testName;
  final Model model;
  final Drug drug;
  final Sex sex;
  final int age;
  final int height;
  final int weight;
  final double target;
  final int durationMinutes;
  final int maxPumpRate;
  final int timeStepSeconds;

  const SimulationTestConfig({
    required this.testName,
    required this.model,
    required this.drug,
    required this.sex,
    required this.age,
    required this.height,
    required this.weight,
    required this.target,
    this.durationMinutes = 15,
    this.maxPumpRate = 1200,
    this.timeStepSeconds = 5,
  });
}

void main() {
  group('Configurable Simulation Tests', () {
    
    /// Helper function to run simulation with any configuration
    void runSimulationTest(SimulationTestConfig config) {
      test(config.testName, () {
        print('\n=== ${config.testName.toUpperCase()} ===\n');
      
        // Create patient with configurable parameters
        final patient = Patient(
          sex: config.sex,
          age: config.age,
          height: config.height,
          weight: config.weight,
        );

        // Create pump with configurable drug and settings
        final pump = Pump(
          timeStep: Duration(seconds: config.timeStepSeconds),
          concentration: config.drug.concentration,
          maxPumpRate: config.maxPumpRate,
          target: config.target,
          duration: Duration(minutes: config.durationMinutes),
          drug: config.drug,
        );

        // Create simulation with configurable model
        final simulation = Simulation(
          model: config.model,
          patient: patient,
          pump: pump,
        );

        print('SIMULATION CONFIGURATION:');
        print('Model: ${config.model}');
        print('Drug: ${config.drug.displayName}');
        print('Concentration: ${config.drug.concentration} ${config.drug.concentrationUnit.displayName}');
        print('Patient: ${config.sex.name}, ${config.age}yo, ${config.height}cm, ${config.weight}kg');
        print('BMI: ${patient.bmi.toStringAsFixed(1)}');
        print('Target: ${config.target} ${config.drug.targetUnit.displayName} (${config.model.target})');
        print('Duration: ${config.durationMinutes} minutes');
        print('Time Step: ${config.timeStepSeconds} seconds');
        print('Max Pump Rate: ${config.maxPumpRate} ml/hr');
        print('Max Infusion Rate: ${(config.drug.concentration * config.maxPumpRate).toStringAsFixed(0)} ${config.drug.concentrationUnit.displayName}/hr');
        
        // Print pharmacokinetic parameters
        final pkParams = simulation.variables;
        print('\nPHARMACOKINETIC PARAMETERS:');
        print('V1: ${pkParams.V1.toStringAsFixed(3)} L');
        print('V2: ${pkParams.V2.toStringAsFixed(3)} L');
        print('V3: ${pkParams.V3.toStringAsFixed(3)} L');
        print('Cl1: ${pkParams.Cl1.toStringAsFixed(3)} L/min');
        print('Cl2: ${pkParams.Cl2.toStringAsFixed(3)} L/min');
        print('Cl3: ${pkParams.Cl3.toStringAsFixed(3)} L/min');
        print('k10: ${pkParams.k10.toStringAsFixed(4)} min⁻¹');
        print('k12: ${pkParams.k12.toStringAsFixed(4)} min⁻¹');
        print('k21: ${pkParams.k21.toStringAsFixed(4)} min⁻¹');
        print('k13: ${pkParams.k13.toStringAsFixed(4)} min⁻¹');
        print('k31: ${pkParams.k31.toStringAsFixed(4)} min⁻¹');
        print('ke0: ${pkParams.ke0.toStringAsFixed(4)} min⁻¹');
        if (pkParams.ce50 != null) print('ce50: ${pkParams.ce50!.toStringAsFixed(2)} ${config.drug.targetUnit.displayName}');
        if (pkParams.baselineBIS != null) print('baselineBIS: ${pkParams.baselineBIS!.toStringAsFixed(1)}');

        // Get simulation results
        final results = simulation.estimate;
        
        print('\nSIMULATION RESULTS:');
        print('Total Steps: ${results.steps.length}');
        print('Final Plasma Concentration: ${results.concentrations.last.toStringAsFixed(3)} ${config.drug.targetUnit.displayName}');
        print('Final Effect Concentration: ${results.concentrationsEffect.last.toStringAsFixed(3)} ${config.drug.targetUnit.displayName}');
        print('Final Cumulative Dose: ${results.cumulativeInfusedDosages.last.toStringAsFixed(3)} mg (pump units)');
        print('Final Cumulative Volume: ${results.cumulativeInfusedVolumes.last.toStringAsFixed(3)} ml');
        print('Average Pump Rate: ${(results.pumpInfs.reduce((a, b) => a + b) / results.pumpInfs.length).toStringAsFixed(2)} mg/hr (pump units)');
        
        // Generate CSV output
        print('\n=== CSV OUTPUT ===');
        final csvData = simulation.toCsv();
        print(csvData);
        
        // Print first few rows for verification
        print('\n=== FIRST 10 TIME POINTS (VERIFICATION) ===');
        print('Time(s)\tPump(mg/hr)\tCe(${config.drug.targetUnit.displayName})\tCp(${config.drug.targetUnit.displayName})\tCumVol(ml)');
        for (int i = 0; i < 10 && i < results.steps.length; i++) {
          final timeSeconds = results.times[i].inSeconds;
          final pumpRate = results.pumpInfs[i];
          final effectConc = results.concentrationsEffect[i];
          final plasmaConc = results.concentrations[i];
          final cumVol = results.cumulativeInfusedVolumes[i];
          print('${timeSeconds}\t\t${pumpRate.toStringAsFixed(1)}\t\t${effectConc.toStringAsFixed(3)}\t\t${plasmaConc.toStringAsFixed(3)}\t\t${cumVol.toStringAsFixed(3)}');
        }

        // Basic assertions
        expect(results.steps.length, greaterThan(0));
        expect(results.pumpInfs.length, equals(results.steps.length));
        expect(results.concentrationsEffect.length, equals(results.steps.length));
        expect(results.concentrations.length, equals(results.steps.length));
        expect(results.cumulativeInfusedVolumes.length, equals(results.steps.length));
        
        // Verify duration matches expected steps
        final expectedSteps = (config.durationMinutes * 60 / config.timeStepSeconds).round() + 1;
        expect(results.steps.length, equals(expectedSteps));
        
        // Verify final time matches duration
        expect(results.times.last.inMinutes, equals(config.durationMinutes));
      });
    }

    // =============================================================================
    // TEST CONFIGURATIONS - EASILY MODIFY THESE FOR DIFFERENT SCENARIOS
    // =============================================================================

    // 1. Remifentanil Eleveld Test (Fixed PK parameters)
    runSimulationTest(const SimulationTestConfig(
      testName: 'Remifentanil 50mcg/ml + Eleveld Model',
      model: Model.Eleveld,
      drug: Drug.remifentanil50mcg,
      sex: Sex.Female,
      age: 40,
      height: 170,
      weight: 70,
      target: 3.0,
      durationMinutes: 15,
    ));

    // 2. Remifentanil Minto Test
    runSimulationTest(const SimulationTestConfig(
      testName: 'Remifentanil 50mcg/ml + Minto Model',
      model: Model.Minto,
      drug: Drug.remifentanil50mcg,
      sex: Sex.Female,
      age: 40,
      height: 170,
      weight: 70,
      target: 3.0,
      durationMinutes: 15,
    ));

    // 3. Propofol Eleveld Test
    runSimulationTest(const SimulationTestConfig(
      testName: 'Propofol 10mg/ml + Eleveld Model',
      model: Model.Eleveld,
      drug: Drug.propofol10mg,
      sex: Sex.Female,
      age: 40,
      height: 170,
      weight: 70,
      target: 4.0,
      durationMinutes: 15,
    ));

    // 4. Dexmedetomidine Hannivoort Test
    runSimulationTest(const SimulationTestConfig(
      testName: 'Dexmedetomidine 4mcg/ml + Hannivoort Model',
      model: Model.Hannivoort,
      drug: Drug.dexmedetomidine,
      sex: Sex.Female,
      age: 40,
      height: 170,
      weight: 70,
      target: 3.0,
      durationMinutes: 15,
    ));

    // 5. Different Patient Demographics Test
    runSimulationTest(const SimulationTestConfig(
      testName: 'Remifentanil 50mcg/ml + Eleveld (Male, 65yo, 180cm, 85kg)',
      model: Model.Eleveld,
      drug: Drug.remifentanil50mcg,
      sex: Sex.Male,
      age: 65,
      height: 180,
      weight: 85,
      target: 2.5,
      durationMinutes: 30,
    ));

    // 6. Longer Duration Test
    runSimulationTest(const SimulationTestConfig(
      testName: 'Propofol 10mg/ml + Marsh (60 minutes)',
      model: Model.Marsh,
      drug: Drug.propofol10mg,
      sex: Sex.Male,
      age: 45,
      height: 175,
      weight: 75,
      target: 3.5,
      durationMinutes: 60,
    ));
  });
}