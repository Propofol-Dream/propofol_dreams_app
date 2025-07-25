import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart' as PDSim;
import 'package:propofol_dreams_app/models/parameters.dart';

void main() {
  group('Simulation Integration Test', () {
    // Test patient: 35 yo male, 70 kg, 170 cm
    const Sex sex = Sex.Male;
    const int weight = 70;
    const int height = 170;
    const int age = 35;

    test('Existing propofol models still work with new parameter system', () {
      final patient = Patient(
        weight: weight,
        age: age,
        height: height,
        sex: sex,
      );

      final pump = Pump(
        timeStep: const Duration(seconds: 1),
        density: 10, // mg/mL for propofol
        maxPumpRate: 1200,
        target: 3.0,
        duration: const Duration(minutes: 60),
      );

      // Test all propofol models
      final propofolModels = [
        Model.EleveldPropofol,
        Model.MarshPropofol,
        Model.SchniderPropofol,
      ];

      for (final model in propofolModels) {
        final simulation = PDSim.Simulation(
          model: model,
          patient: patient,
          pump: pump,
        );

        final results = simulation.estimate;

        // Verify simulation produces valid results
        expect(results.times.isNotEmpty, true, reason: '$model should produce time points');
        expect(results.pumpInfs.isNotEmpty, true, reason: '$model should produce pump infusion rates');
        expect(results.cumulativeInfusedVolumes.isNotEmpty, true, reason: '$model should produce cumulative volumes');

        // Verify reasonable ranges for propofol
        expect(results.times.length, greaterThan(100), reason: '$model should have sufficient time points');
        expect(results.pumpInfs.any((rate) => rate > 0), true, reason: '$model should have non-zero infusion rates');

        print('✓ $model simulation working correctly');
      }
    });

    test('Parameter calculation system works for all models', () {
      final allModels = [
        Model.EleveldPropofol,
        Model.MarshPropofol,
        Model.SchniderPropofol,
        Model.PaedfusorPropofol,
        Model.KatariaPropofol,
        Model.MintoRemifentanil,
        Model.EleveldRemifentanil,
        Model.HannivoortDexmedetomidine,
        Model.EleveldRemimazolam,
      ];

      for (final model in allModels) {
        // Skip models that don't support adult patients
        if ((model == Model.PaedfusorPropofol || model == Model.KatariaPropofol) && age >= 17) {
          continue;
        }

        final params = model.calculatePKParameters(
          sex: sex,
          weight: weight,
          height: height,
          age: age,
        );

        // Verify all parameters are positive
        expect(params.V1, greaterThan(0), reason: '$model V1 should be positive');
        expect(params.V2, greaterThan(0), reason: '$model V2 should be positive');
        expect(params.V3, greaterThan(0), reason: '$model V3 should be positive');
        expect(params.Cl1, greaterThan(0), reason: '$model Cl1 should be positive');
        expect(params.Cl2, greaterThan(0), reason: '$model Cl2 should be positive');
        expect(params.Cl3, greaterThan(0), reason: '$model Cl3 should be positive');
        expect(params.k10, greaterThan(0), reason: '$model k10 should be positive');
        expect(params.k12, greaterThan(0), reason: '$model k12 should be positive');
        expect(params.k21, greaterThan(0), reason: '$model k21 should be positive');
        expect(params.k13, greaterThan(0), reason: '$model k13 should be positive');
        expect(params.k31, greaterThan(0), reason: '$model k31 should be positive');
        expect(params.ke0, greaterThanOrEqualTo(0), reason: '$model ke0 should be non-negative');

        print('✓ $model parameters calculated successfully');
      }
    });
  });
}