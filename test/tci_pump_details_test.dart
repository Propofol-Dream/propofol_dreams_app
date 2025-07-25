import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/drug.dart';

void main() {
  group('TCI Pump Details Test', () {
    test('Print TCI simulation with pump details in JSON format', () {
      // Create patient: Female, 40yo, 170cm, 70kg
      final patient = Patient(
        sex: Sex.Female,
        age: 40,
        height: 170,
        weight: 70,
      );

      // Create pump: Propofol 10mg/ml, target 4 mcg/ml, 15 minutes
      final pump = Pump(
        timeStep: const Duration(seconds: 5),
        concentration: 10.0, // mg/ml
        maxPumpRate: 1200, // ml/hr
        target: 4.0, // mcg/ml
        duration: const Duration(minutes: 15),
        drug: Drug.propofol,
      );

      // Create simulation with Eleveld model
      final simulation = Simulation(
        model: Model.Eleveld,
        patient: patient,
        pump: pump,
      );

      // Get simulation results for first 15 minutes
      final results = simulation.estimate;
      
      // Print in JSON-like format with pump details
      print('''
{
  "simulation": {
    "model": "${simulation.model}",
    "patient": {
      "sex": "${patient.sex.name}",
      "age": ${patient.age},
      "height": ${patient.height},
      "weight": ${patient.weight},
      "bmi": ${patient.bmi.toStringAsFixed(1)}
    },
    "pump": {
      "timeStep": "${pump.timeStep}",
      "concentration": ${pump.concentration},
      "concentrationUnit": "mg/ml",
      "maxPumpRate": ${pump.maxPumpRate},
      "maxPumpRateUnit": "ml/hr",
      "maxInfusionRate": ${pump.concentration * pump.maxPumpRate},
      "maxInfusionRateUnit": "mg/hr",
      "target": ${pump.target},
      "targetUnit": "${simulation.model.targetUnit.displayName}",
      "targetType": "${simulation.model.target}",
      "duration": "${pump.duration}",
      "drug": "${pump.drug?.displayName ?? "Unknown"}"
    },
    "pharmacokinetics": {
      "V1": ${simulation.variables.V1.toStringAsFixed(3)},
      "V2": ${simulation.variables.V2.toStringAsFixed(3)},
      "V3": ${simulation.variables.V3.toStringAsFixed(3)},
      "Cl1": ${simulation.variables.Cl1.toStringAsFixed(3)},
      "Cl2": ${simulation.variables.Cl2.toStringAsFixed(3)},
      "Cl3": ${simulation.variables.Cl3.toStringAsFixed(3)},
      "k10": ${simulation.variables.k10.toStringAsFixed(4)},
      "k12": ${simulation.variables.k12.toStringAsFixed(4)},
      "k21": ${simulation.variables.k21.toStringAsFixed(4)},
      "k13": ${simulation.variables.k13.toStringAsFixed(4)},
      "k31": ${simulation.variables.k31.toStringAsFixed(4)},
      "ke0": ${simulation.variables.ke0.toStringAsFixed(4)},
      "ce50": ${simulation.variables.ce50.toStringAsFixed(2)},
      "baselineBIS": ${simulation.variables.baselineBIS.toStringAsFixed(1)},
      "delayBIS": ${simulation.variables.delayBIS.toStringAsFixed(1)}
    },
    "summary": {
      "totalSteps": ${results.steps.length},
      "finalCumulativeDose": ${results.cumulativeInfusedDosages.last.toStringAsFixed(2)},
      "finalCumulativeDoseUnit": "mg",
      "finalCumulativeVolume": ${results.cumulativeInfusedVolumes.last.toStringAsFixed(2)},
      "finalCumulativeVolumeUnit": "ml",
      "finalPlasmaConcentration": ${results.concentrations.last.toStringAsFixed(2)},
      "finalEffectConcentration": ${results.concentrationsEffect.last.toStringAsFixed(2)},
      "finalBIS": ${results.BISEstimates.last.toStringAsFixed(1)},
      "averagePumpRate": ${results.pumpInfs.reduce((a, b) => a + b) / results.pumpInfs.length.toStringAsFixed(2)},
      "averagePumpRateUnit": "mg/hr"
    }
  }
}''');

      // Basic assertions
      expect(results.steps.length, greaterThan(0));
      expect(results.pumpInfs.length, equals(results.steps.length));
      expect(results.cumulativeInfusedVolumes.length, equals(results.steps.length));
    });
  });
}