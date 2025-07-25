import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/parameters.dart';
import 'dart:math' as math;

/// Test data structure for Eleveld Propofol validation
class EleveldTestCase {
  final int age;
  final int weight; 
  final int height;
  final Sex sex;
  final double target;
  final String description;
  final EleveldExpectedResults expectedMatlab;

  const EleveldTestCase({
    required this.age,
    required this.weight,
    required this.height,
    required this.sex,
    required this.target,
    required this.description,
    required this.expectedMatlab,
  });
}

/// Expected results from MATLAB reference implementation
class EleveldExpectedResults {
  final double V1, V2, V3;
  final double Cl1, Cl2, Cl3;
  final double k10, k12, k21, k13, k31, ke0;
  final double ce50, predictedBIS;

  const EleveldExpectedResults({
    required this.V1,
    required this.V2,
    required this.V3,
    required this.Cl1,
    required this.Cl2,
    required this.Cl3,
    required this.k10,
    required this.k12,
    required this.k21,
    required this.k13,
    required this.k31,
    required this.ke0,
    required this.ce50,
    required this.predictedBIS,
  });
}

void main() {
  group('Eleveld Propofol Parameter Validation', () {
    
    // Reference test cases based on MATLAB implementation
    final List<EleveldTestCase> testCases = [
      // Standard reference patient (35yo, 70kg, 170cm, Male) - MATLAB verified
      EleveldTestCase(
        age: 35,
        weight: 70,
        height: 170,
        sex: Sex.Male,
        target: 3.0,
        description: 'Standard reference patient - Male',
        expectedMatlab: EleveldExpectedResults(
          V1: 6.280000, V2: 25.500000, V3: 168.421842,
          Cl1: 1.619497, Cl2: 1.830371, Cl3: 0.772661,
          k10: 0.257882, k12: 0.291460, k21: 0.071779,
          k13: 0.123035, k31: 0.004588, ke0: 0.146000,
          ce50: 3.080000, predictedBIS: 47.656210,
        ),
      ),
      
      // Standard reference patient - Female - MATLAB verified
      EleveldTestCase(
        age: 35,
        weight: 70,
        height: 170,
        sex: Sex.Female,
        target: 3.0,
        description: 'Standard reference patient - Female',
        expectedMatlab: EleveldExpectedResults(
          V1: 6.280000, V2: 25.500000, V3: 138.784766,
          Cl1: 1.899969, Cl2: 1.830371, Cl3: 0.668262,
          k10: 0.302543, k12: 0.291460, k21: 0.071779,
          k13: 0.106411, k31: 0.004815, ke0: 0.146000,
          ce50: 3.080000, predictedBIS: 47.656210,
        ),
      ),
      
      // Pediatric patient - MATLAB verified
      EleveldTestCase(
        age: 10,
        weight: 30,
        height: 140,
        sex: Sex.Male,
        target: 3.0,
        description: 'Pediatric patient - Male',
        expectedMatlab: EleveldExpectedResults(
          V1: 4.384151, V2: 16.141290, V3: 107.329993,
          Cl1: 0.921403, Cl2: 1.417004, Cl3: 0.509322,
          k10: 0.210167, k12: 0.323211, k21: 0.087788,
          k13: 0.116174, k31: 0.004745, ke0: 0.180446,
          ce50: 3.609898, predictedBIS: 54.550410,
        ),
      ),
      
      // Elderly patient - MATLAB verified
      EleveldTestCase(
        age: 80,
        weight: 60,
        height: 160,
        sex: Sex.Female,
        target: 3.0,
        description: 'Elderly patient - Female',
        expectedMatlab: EleveldExpectedResults(
          V1: 5.957949, V2: 10.832250, V3: 64.195281,
          Cl1: 1.488136, Cl2: 0.939918, Cl3: 0.382341,
          k10: 0.249773, k12: 0.157759, k21: 0.086770,
          k13: 0.064173, k31: 0.005956, ke0: 0.151736,
          ce50: 2.314467, predictedBIS: 37.739164,
        ),
      ),
      
      // Obese patient - MATLAB verified
      EleveldTestCase(
        age: 45,
        weight: 120,
        height: 175,
        sex: Sex.Male,
        target: 3.0,
        description: 'Obese patient - Male',
        expectedMatlab: EleveldExpectedResults(
          V1: 7.261250, V2: 37.400159, V3: 197.832038,
          Cl1: 2.357880, Cl2: 2.416681, Cl3: 0.878574,
          k10: 0.324721, k12: 0.332819, k21: 0.064617,
          k13: 0.120995, k31: 0.004441, ke0: 0.127595,
          ce50: 2.890500, predictedBIS: 45.229505,
        ),
      ),
    ];

    for (final testCase in testCases) {
      test('${testCase.description} - Parameter calculations', () {
        // Calculate parameters using Flutter implementation
        final pkParams = Model.EleveldPropofol.calculatePKParameters(
          sex: testCase.sex,
          weight: testCase.weight,
          height: testCase.height,
          age: testCase.age,
        );

        // Validate volume compartments (tolerance: ±1%)
        expect(pkParams.V1, closeTo(testCase.expectedMatlab.V1, testCase.expectedMatlab.V1 * 0.01));
        expect(pkParams.V2, closeTo(testCase.expectedMatlab.V2, testCase.expectedMatlab.V2 * 0.01));
        expect(pkParams.V3, closeTo(testCase.expectedMatlab.V3, testCase.expectedMatlab.V3 * 0.01));

        // Validate clearances (tolerance: ±1%)
        expect(pkParams.Cl1, closeTo(testCase.expectedMatlab.Cl1, testCase.expectedMatlab.Cl1 * 0.01));
        expect(pkParams.Cl2, closeTo(testCase.expectedMatlab.Cl2, testCase.expectedMatlab.Cl2 * 0.01));
        expect(pkParams.Cl3, closeTo(testCase.expectedMatlab.Cl3, testCase.expectedMatlab.Cl3 * 0.01));

        // Validate rate constants (tolerance: ±1%)
        expect(pkParams.k10, closeTo(testCase.expectedMatlab.k10, testCase.expectedMatlab.k10 * 0.01));
        expect(pkParams.k12, closeTo(testCase.expectedMatlab.k12, testCase.expectedMatlab.k12 * 0.01));
        expect(pkParams.k21, closeTo(testCase.expectedMatlab.k21, testCase.expectedMatlab.k21 * 0.01));
        expect(pkParams.k13, closeTo(testCase.expectedMatlab.k13, testCase.expectedMatlab.k13 * 0.01));
        expect(pkParams.k31, closeTo(testCase.expectedMatlab.k31, testCase.expectedMatlab.k31 * 0.01));
        expect(pkParams.ke0, closeTo(testCase.expectedMatlab.ke0, testCase.expectedMatlab.ke0 * 0.01));

        // Validate BIS-related parameters (tolerance: ±2%)
        expect(pkParams.ce50!, closeTo(testCase.expectedMatlab.ce50, testCase.expectedMatlab.ce50 * 0.02));
      });

      test('${testCase.description} - BIS calculation', () {
        // Calculate BIS using the same algorithm as MATLAB
        final ce50 = 3.08 * math.exp(-0.00635 * (testCase.age - 35));
        final target = testCase.target;
        
        double bis;
        if (target > ce50) {
          bis = 93 * (math.pow(ce50, 1.47) / (math.pow(ce50, 1.47) + math.pow(target, 1.47)));
        } else {
          bis = 93 * (math.pow(ce50, 1.89) / (math.pow(ce50, 1.89) + math.pow(target, 1.89)));
        }

        // Validate BIS calculation (tolerance: ±5%)
        expect(bis, closeTo(testCase.expectedMatlab.predictedBIS, testCase.expectedMatlab.predictedBIS * 0.05));
      });
    }

    group('Edge Case Validation', () {
      test('Very young pediatric patient (age 1)', () {
        final pkParams = Model.EleveldPropofol.calculatePKParameters(
          sex: Sex.Male,
          weight: 10,
          height: 75,
          age: 1,
        );

        // Ensure parameters are positive and reasonable
        expect(pkParams.V1, greaterThan(0));
        expect(pkParams.V2, greaterThan(0));
        expect(pkParams.V3, greaterThan(0));
        expect(pkParams.ke0, greaterThan(0));
        expect(pkParams.ke0, lessThan(1.0)); // ke0 should be reasonable
      });

      test('Very elderly patient (age 95)', () {
        final pkParams = Model.EleveldPropofol.calculatePKParameters(
          sex: Sex.Female,
          weight: 50,
          height: 150,
          age: 95,
        );

        // Ensure parameters are positive and reasonable
        expect(pkParams.V1, greaterThan(0));
        expect(pkParams.Cl1, greaterThan(0));
        expect(pkParams.ke0, greaterThan(0));
        expect(pkParams.ce50!, greaterThan(0));
      });

      test('Very obese patient (weight 150kg)', () {
        final pkParams = Model.EleveldPropofol.calculatePKParameters(
          sex: Sex.Male,
          weight: 150,
          height: 180,
          age: 40,
        );

        // Volumes should scale appropriately with weight  
        expect(pkParams.V1, greaterThan(7)); // V1 doesn't scale linearly with weight in Eleveld
        expect(pkParams.V2, greaterThan(40)); // V2 should scale with weight
        expect(pkParams.V3, greaterThan(200)); // V3 should scale with FFM
      });
    });

    group('Mathematical Consistency', () {
      test('Rate constant relationships', () {
        final pkParams = Model.EleveldPropofol.calculatePKParameters(
          sex: Sex.Male,
          weight: 70,
          height: 170,
          age: 35,
        );

        // Validate k = Cl/V relationships
        expect(pkParams.k10, closeTo(pkParams.Cl1 / pkParams.V1, 0.001));
        expect(pkParams.k12, closeTo(pkParams.Cl2 / pkParams.V1, 0.001));
        expect(pkParams.k21, closeTo(pkParams.Cl2 / pkParams.V2, 0.001));
        expect(pkParams.k13, closeTo(pkParams.Cl3 / pkParams.V1, 0.001));
        expect(pkParams.k31, closeTo(pkParams.Cl3 / pkParams.V3, 0.001));
      });

      test('Parameter scaling with demographics', () {
        // Test that parameters scale logically with patient size
        final small = Model.EleveldPropofol.calculatePKParameters(
          sex: Sex.Female, weight: 50, height: 150, age: 30,
        );
        final large = Model.EleveldPropofol.calculatePKParameters(
          sex: Sex.Male, weight: 100, height: 190, age: 30,
        );

        // Volumes should be larger for larger patients
        expect(large.V1, greaterThan(small.V1));
        expect(large.V2, greaterThan(small.V2));
        expect(large.V3, greaterThan(small.V3));
      });
    });
  });

  group('BIS Calculation Validation', () {
    final testTargets = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    
    for (final target in testTargets) {
      test('BIS calculation for target $target mcg/mL', () {
        const age = 35;
        final ce50 = 3.08 * math.exp(-0.00635 * (age - 35)); // Should be 3.08 for age 35
        
        double bis;
        if (target > ce50) {
          bis = 93 * (math.pow(ce50, 1.47) / (math.pow(ce50, 1.47) + math.pow(target, 1.47)));
        } else {
          bis = 93 * (math.pow(ce50, 1.89) / (math.pow(ce50, 1.89) + math.pow(target, 1.89)));
        }

        // BIS should be between 0 and 93
        expect(bis, greaterThan(0));
        expect(bis, lessThanOrEqualTo(93));
        
        // Higher concentrations should give lower BIS values
        if (target >= 3.0) {
          expect(bis, lessThan(50)); // Deep sedation range
        }
      });
    }

    test('Age-dependent Ce50 calculation', () {
      final ages = [20, 35, 50, 65, 80];
      final ce50Values = ages.map((age) => 3.08 * math.exp(-0.00635 * (age - 35))).toList();
      
      // Ce50 should decrease with age (higher sensitivity)
      for (int i = 1; i < ce50Values.length; i++) {
        expect(ce50Values[i], lessThan(ce50Values[i-1]));
      }
      
      // Reference value at age 35 should be exactly 3.08
      expect(ce50Values[1], closeTo(3.08, 0.001));
    });
  });
}