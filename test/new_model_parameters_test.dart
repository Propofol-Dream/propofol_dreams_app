import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/parameters.dart';

void main() {
  group('New Model Parameter Tests', () {
    // Test patient: 35 yo male, 70 kg, 170 cm (reference patient)
    const Sex sex = Sex.Male;
    const int weight = 70;
    const int height = 170;
    const int age = 35;

    test('Minto Remifentanil parameters calculation', () {
      final params = Model.MintoRemifentanil.calculatePKParameters(
        sex: sex,
        weight: weight,
        height: height,
        age: age,
      );

      // Verify that parameters are calculated (not zero)
      expect(params.V1, greaterThan(0));
      expect(params.V2, greaterThan(0));
      expect(params.V3, greaterThan(0));
      expect(params.Cl1, greaterThan(0));
      expect(params.Cl2, greaterThan(0));
      expect(params.Cl3, greaterThan(0));
      expect(params.k10, greaterThan(0));
      expect(params.k12, greaterThan(0));
      expect(params.k21, greaterThan(0));
      expect(params.k13, greaterThan(0));
      expect(params.k31, greaterThan(0));
      expect(params.ke0, greaterThan(0));

      // Print values for verification against MATLAB
      print('Minto Remifentanil Parameters:');
      print('V1: ${params.V1.toStringAsFixed(4)} L');
      print('V2: ${params.V2.toStringAsFixed(4)} L');
      print('V3: ${params.V3.toStringAsFixed(4)} L');
      print('Cl1: ${params.Cl1.toStringAsFixed(4)} L/min');
      print('Cl2: ${params.Cl2.toStringAsFixed(4)} L/min');
      print('Cl3: ${params.Cl3.toStringAsFixed(4)} L/min');
      print('ke0: ${params.ke0.toStringAsFixed(4)} min⁻¹');
    });

    test('Eleveld Remifentanil parameters calculation', () {
      final params = Model.EleveldRemifentanil.calculatePKParameters(
        sex: sex,
        weight: weight,
        height: height,
        age: age,
      );

      // Verify that parameters are calculated (not zero)
      expect(params.V1, greaterThan(0));
      expect(params.V2, greaterThan(0));
      expect(params.V3, greaterThan(0));
      expect(params.Cl1, greaterThan(0));
      expect(params.Cl2, greaterThan(0));
      expect(params.Cl3, greaterThan(0));
      expect(params.k10, greaterThan(0));
      expect(params.k12, greaterThan(0));
      expect(params.k21, greaterThan(0));
      expect(params.k13, greaterThan(0));
      expect(params.k31, greaterThan(0));
      expect(params.ke0, greaterThan(0));

      // Print values for verification against MATLAB
      print('Eleveld Remifentanil Parameters:');
      print('V1: ${params.V1.toStringAsFixed(4)} L');
      print('V2: ${params.V2.toStringAsFixed(4)} L');
      print('V3: ${params.V3.toStringAsFixed(4)} L');
      print('Cl1: ${params.Cl1.toStringAsFixed(4)} L/min');
      print('Cl2: ${params.Cl2.toStringAsFixed(4)} L/min');
      print('Cl3: ${params.Cl3.toStringAsFixed(4)} L/min');
      print('ke0: ${params.ke0.toStringAsFixed(4)} min⁻¹');
    });

    test('Hannivoort Dexmedetomidine parameters calculation', () {
      final params = Model.HannivoortDexmedetomidine.calculatePKParameters(
        sex: sex,
        weight: weight,
        height: height,
        age: age,
      );

      // Verify that parameters are calculated (not zero)
      expect(params.V1, greaterThan(0));
      expect(params.V2, greaterThan(0));
      expect(params.V3, greaterThan(0));
      expect(params.Cl1, greaterThan(0));
      expect(params.Cl2, greaterThan(0));
      expect(params.Cl3, greaterThan(0));
      expect(params.k10, greaterThan(0));
      expect(params.k12, greaterThan(0));
      expect(params.k21, greaterThan(0));
      expect(params.k13, greaterThan(0));
      expect(params.k31, greaterThan(0));
      
      // ke0 should be 0 for plasma targeting
      expect(params.ke0, equals(0));

      // Print values for verification against MATLAB
      print('Hannivoort Dexmedetomidine Parameters:');
      print('V1: ${params.V1.toStringAsFixed(4)} L');
      print('V2: ${params.V2.toStringAsFixed(4)} L');
      print('V3: ${params.V3.toStringAsFixed(4)} L');
      print('Cl1: ${params.Cl1.toStringAsFixed(4)} L/min');
      print('Cl2: ${params.Cl2.toStringAsFixed(4)} L/min');
      print('Cl3: ${params.Cl3.toStringAsFixed(4)} L/min');
      print('ke0: ${params.ke0.toStringAsFixed(4)} min⁻¹');
    });

    test('Eleveld Remimazolam parameters calculation', () {
      final params = Model.EleveldRemimazolam.calculatePKParameters(
        sex: sex,
        weight: weight,
        height: height,
        age: age,
      );

      // Verify that parameters are calculated (not zero)
      expect(params.V1, greaterThan(0));
      expect(params.V2, greaterThan(0));
      expect(params.V3, greaterThan(0));
      expect(params.Cl1, greaterThan(0));
      expect(params.Cl2, greaterThan(0));
      expect(params.Cl3, greaterThan(0));
      expect(params.k10, greaterThan(0));
      expect(params.k12, greaterThan(0));
      expect(params.k21, greaterThan(0));
      expect(params.k13, greaterThan(0));
      expect(params.k31, greaterThan(0));
      expect(params.ke0, greaterThan(0));

      // Print values for verification against MATLAB
      print('Eleveld Remimazolam Parameters:');
      print('V1: ${params.V1.toStringAsFixed(4)} L');
      print('V2: ${params.V2.toStringAsFixed(4)} L');
      print('V3: ${params.V3.toStringAsFixed(4)} L');
      print('Cl1: ${params.Cl1.toStringAsFixed(4)} L/min');
      print('Cl2: ${params.Cl2.toStringAsFixed(4)} L/min');
      print('Cl3: ${params.Cl3.toStringAsFixed(4)} L/min');
      print('ke0: ${params.ke0.toStringAsFixed(4)} min⁻¹');
    });

    test('All models return valid parameters', () {
      // Test all models don't return default zero parameters
      for (final model in [
        Model.MintoRemifentanil,
        Model.EleveldRemifentanil,
        Model.HannivoortDexmedetomidine,
        Model.EleveldRemimazolam,
      ]) {
        final params = model.calculatePKParameters(
          sex: sex,
          weight: weight,
          height: height,
          age: age,
        );

        expect(params.V1, greaterThan(0), reason: '$model V1 should be > 0');
        expect(params.V2, greaterThan(0), reason: '$model V2 should be > 0');
        expect(params.V3, greaterThan(0), reason: '$model V3 should be > 0');
        expect(params.Cl1, greaterThan(0), reason: '$model Cl1 should be > 0');
        expect(params.k10, greaterThan(0), reason: '$model k10 should be > 0');
      }
    });
  });
}