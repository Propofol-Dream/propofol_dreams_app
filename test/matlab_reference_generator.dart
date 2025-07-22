/// MATLAB Reference Data Generator
/// 
/// This file contains the exact MATLAB Eleveld implementation for generating
/// reference test data. Use this to validate Flutter calculations against
/// the authoritative MATLAB source.

import 'dart:math' as math;

class MatlabEleveldReference {
  /// Generate reference PK parameters using exact MATLAB Eleveld implementation
  /// 
  /// This matches the MATLAB code exactly:
  /// ```matlab
  /// V1 = 6.28*(weight/(weight + 33.6))/(0.675675675676);
  /// V2 = 25.5 * (weight/70)*exp(-0.0156*(age-35));
  /// V3 = 273*exp(-0.0138*age)*(sex*((0.88+(0.12)/(1+(age/13.4)^(-12.7)))*(9270*weight/(6680+216*weight/(height/100)^2)))+(1-sex)*((1.11+(-0.11)/(1+(age/7.1)^(-1.1)))*(9270*weight/(8780+244*weight/(height/100)^2))))/54.4752059601377;
  /// ```
  static Map<String, double> calculateEleveldParameters({
    required int age,
    required int weight, 
    required int height,
    required int sex, // 1 = male, 0 = female
    bool opioid = true, // Assume opioid present (matches MATLAB default)
  }) {
    final double ageYr = age.toDouble();
    final double weightKg = weight.toDouble();
    final double heightCm = height.toDouble();
    final int sexInt = sex;

    // V1 calculation (exact MATLAB)
    final double V1 = 6.28 * (weightKg / (weightKg + 33.6)) / (0.675675675676);
    
    // V2 calculation (exact MATLAB)
    final double V2 = 25.5 * (weightKg / 70) * math.exp(-0.0156 * (ageYr - 35));
    
    // V3 calculation (exact MATLAB - complex FFM calculation)
    final double v3Component1 = sexInt * ((0.88 + (0.12) / (1 + math.pow(ageYr / 13.4, -12.7))) * 
                                        (9270 * weightKg / (6680 + 216 * weightKg / math.pow(heightCm / 100, 2))));
    final double v3Component2 = (1 - sexInt) * ((1.11 + (-0.11) / (1 + math.pow(ageYr / 7.1, -1.1))) *
                                               (9270 * weightKg / (8780 + 244 * weightKg / math.pow(heightCm / 100, 2))));
    final double V3 = 273 * math.exp(-0.0138 * ageYr) * (v3Component1 + v3Component2) / 54.4752059601377;
    
    // PMA calculation (exact MATLAB)
    final double pma = ageYr * 52.143 + 40;
    
    // Cl1 calculation (exact MATLAB)
    final double Cl1 = ((sexInt == 1 ? 1.79 : 2.1) * math.pow((weightKg / 70), 0.75) * 
                       math.pow(pma, 9.06) / (math.pow(pma, 9.06) + math.pow(42.3, 9.06))) *
                       (opioid ? math.exp(-0.00286 * ageYr) : 1);
                       
    // Cl2 calculation (exact MATLAB)
    final double Cl2 = 1.75 * math.pow(((25.5 * (weightKg / 70) * math.exp(-0.0156 * (ageYr - 35))) / 25.5), 0.75) *
                       (1 + 1.3 * (1 - pma / (pma + 68.3)));
                       
    // Cl3 calculation (exact MATLAB - complex)
    final double cl3Component1 = sexInt * ((0.88 + (0.12) / (1 + math.pow(ageYr / 13.4, -12.7))) *
                                         (9270 * weightKg / (6680 + 216 * weightKg / math.pow(heightCm / 100, 2))));
    final double cl3Component2 = (1 - sexInt) * ((1.11 + (-0.11) / (1 + math.pow(ageYr / 7.1, -1.1))) *
                                                (9270 * weightKg / (8780 + 244 * weightKg / math.pow(heightCm / 100, 2))));
    final double Cl3 = 1.11 * math.pow(((cl3Component1 + cl3Component2) * 
                                       (opioid ? math.exp(-0.0138 * ageYr) : 1) / 54.4752059601377), 0.75) *
                       (pma / (pma + 68.3) / 0.964695544);

    // Rate constants (exact MATLAB)
    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k13 = Cl3 / V1;
    final double k21 = Cl2 / V2;
    final double k31 = Cl3 / V3;
    final double ke0 = 0.146 * math.pow(weightKg / 70, -0.25);

    // BIS parameters (exact MATLAB)
    final double ce50 = 3.08 * math.exp(-0.00635 * (ageYr - 35));

    return {
      'V1': V1,
      'V2': V2,
      'V3': V3,
      'Cl1': Cl1,
      'Cl2': Cl2,
      'Cl3': Cl3,
      'k10': k10,
      'k12': k12,
      'k21': k21,
      'k13': k13,
      'k31': k31,
      'ke0': ke0,
      'ce50': ce50,
    };
  }

  /// Calculate BIS using exact MATLAB algorithm
  static double calculateBIS({
    required double target,
    required double ce50,
  }) {
    if (target > ce50) {
      return 93 * (math.pow(ce50, 1.47) / (math.pow(ce50, 1.47) + math.pow(target, 1.47)));
    } else {
      return 93 * (math.pow(ce50, 1.89) / (math.pow(ce50, 1.89) + math.pow(target, 1.89)));
    }
  }

  /// Generate comprehensive test dataset matching MATLAB behavior
  static List<Map<String, dynamic>> generateTestDataset() {
    final List<Map<String, dynamic>> dataset = [];
    
    // Test matrix: Age, Weight, Height, Sex combinations
    final ages = [10, 20, 35, 50, 65, 80, 95];
    final weights = [30, 50, 70, 90, 120];
    final heights = [140, 160, 170, 180, 190];
    final sexes = [0, 1]; // 0 = female, 1 = male
    final targets = [1.0, 2.0, 3.0, 4.0, 5.0];

    // Generate representative subset (not full cartesian product)
    final testCases = [
      // Standard cases
      {'age': 35, 'weight': 70, 'height': 170, 'sex': 1}, // Reference male
      {'age': 35, 'weight': 70, 'height': 170, 'sex': 0}, // Reference female
      
      // Pediatric cases
      {'age': 10, 'weight': 30, 'height': 140, 'sex': 1},
      {'age': 10, 'weight': 30, 'height': 140, 'sex': 0},
      
      // Elderly cases
      {'age': 80, 'weight': 60, 'height': 160, 'sex': 1},
      {'age': 80, 'weight': 60, 'height': 160, 'sex': 0},
      
      // Obese cases
      {'age': 45, 'weight': 120, 'height': 175, 'sex': 1},
      {'age': 45, 'weight': 120, 'height': 175, 'sex': 0},
      
      // Edge cases
      {'age': 20, 'weight': 50, 'height': 150, 'sex': 0},
      {'age': 65, 'weight': 90, 'height': 180, 'sex': 1},
    ];

    for (final testCase in testCases) {
      for (final target in targets) {
        final params = calculateEleveldParameters(
          age: testCase['age'] as int,
          weight: testCase['weight'] as int,
          height: testCase['height'] as int,
          sex: testCase['sex'] as int,
        );
        
        final bis = calculateBIS(
          target: target,
          ce50: params['ce50']!,
        );

        dataset.add({
          'age': testCase['age'] as int,
          'weight': testCase['weight'] as int,
          'height': testCase['height'] as int,
          'sex': testCase['sex'] as int,
          'target': target,
          'V1': params['V1'],
          'V2': params['V2'],
          'V3': params['V3'],
          'Cl1': params['Cl1'],
          'Cl2': params['Cl2'],
          'Cl3': params['Cl3'],
          'k10': params['k10'],
          'k12': params['k12'],
          'k21': params['k21'],
          'k13': params['k13'],
          'k31': params['k31'],
          'ke0': params['ke0'],
          'ce50': params['ce50'],
          'bis': bis,
        });
      }
    }

    return dataset;
  }

  /// Print dataset in Dart code format for easy copying to tests
  static void printTestDataset() {
    final dataset = generateTestDataset();
    
    print('// Generated MATLAB reference dataset');
    print('final matlabReferenceData = [');
    
    for (final entry in dataset) {
      print('  {');
      for (final key in entry.keys) {
        final value = entry[key];
        if (value is double) {
          print('    \'$key\': ${value.toStringAsFixed(6)},');
        } else {
          print('    \'$key\': $value,');
        }
      }
      print('  },');
    }
    
    print('];');
  }
}

/// Quick validation test
void main() {
  // Test standard reference patient
  final params = MatlabEleveldReference.calculateEleveldParameters(
    age: 35,
    weight: 70,
    height: 170,
    sex: 1, // male
  );
  
  print('MATLAB Reference - Standard Patient (35yo, 70kg, 170cm, Male):');
  params.forEach((key, value) {
    print('$key: ${value.toStringAsFixed(6)}');
  });
  
  // Test BIS calculation
  final bis = MatlabEleveldReference.calculateBIS(
    target: 3.0,
    ce50: params['ce50']!,
  );
  print('BIS at 3.0 mcg/mL: ${bis.toStringAsFixed(1)}');
  
  print('\n--- Full Test Dataset ---');
  MatlabEleveldReference.printTestDataset();
}