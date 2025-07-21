import 'dart:math' as math;
import 'sex.dart';
import 'model.dart';

/// Pharmacokinetic parameters for a model
class PKParameters {
  const PKParameters({
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
    this.ce50,
    this.baselineBIS,
    this.delayBIS,
  });

  // Volume compartments (L)
  final double V1;  // Central compartment
  final double V2;  // Peripheral compartment 1
  final double V3;  // Peripheral compartment 2

  // Clearance values (L/min)
  final double Cl1; // Elimination clearance
  final double Cl2; // Inter-compartmental clearance 1
  final double Cl3; // Inter-compartmental clearance 2

  // Rate constants (min^-1)
  final double k10; // Elimination rate constant
  final double k12; // Central to peripheral 1
  final double k21; // Peripheral 1 to central
  final double k13; // Central to peripheral 2
  final double k31; // Peripheral 2 to central
  final double ke0; // Effect-site equilibration rate constant

  // BIS-related parameters (optional, for propofol models)
  final double? ce50;        // Concentration for 50% effect
  final double? baselineBIS; // Baseline BIS value
  final double? delayBIS;    // BIS delay

  /// Convert to simulation.dart compatible record format
  ({
    double Cl1,
    double Cl2, 
    double Cl3,
    double V1,
    double V2,
    double V3,
    double baselineBIS,
    double ce50,
    double delayBIS,
    double k10,
    double k12,
    double k13,
    double k21,
    double k31,
    double ke0
  }) toSimulationRecord() {
    return (
      Cl1: Cl1,
      Cl2: Cl2,
      Cl3: Cl3,
      V1: V1,
      V2: V2,
      V3: V3,
      baselineBIS: baselineBIS ?? 93,
      ce50: ce50 ?? 3.08,
      delayBIS: delayBIS ?? 15,
      k10: k10,
      k12: k12,
      k13: k13,
      k21: k21,
      k31: k31,
      ke0: ke0,
    );
  }

  @override
  String toString() {
    return 'PKParameters(V1: $V1, V2: $V2, V3: $V3, Cl1: $Cl1, Cl2: $Cl2, Cl3: $Cl3, k10: $k10, k12: $k12, k21: k21, k13: $k13, k31: $k31, ke0: $ke0, ce50: $ce50, baselineBIS: $baselineBIS, delayBIS: $delayBIS)';
  }
}

/// Extension to add PK parameter calculation to existing Model enum
extension PKCalculation on Model {
  /// Calculate pharmacokinetic parameters for this model
  PKParameters calculatePKParameters({
    required Sex sex,
    required int weight,
    required int height,
    required int age,
  }) {
    final double weightKg = weight.toDouble();
    final double heightCm = height.toDouble();
    final double ageYr = age.toDouble();
    final int sexInt = sex == Sex.Male ? 1 : 0;

    switch (this) {
      case Model.Marsh:
        return _calculateMarshParameters(sexInt, weightKg, heightCm, ageYr);
      case Model.Schnider:
        return _calculateSchniderParameters(sexInt, weightKg, heightCm, ageYr);
      case Model.Eleveld:
        return _calculateEleveldParameters(sexInt, weightKg, heightCm, ageYr);
      case Model.Paedfusor:
        return _calculatePaedfusorParameters(sexInt, weightKg, heightCm, ageYr);
      case Model.Kataria:
        return _calculateKatariaParameters(sexInt, weightKg, heightCm, ageYr);
      default:
        // Return default parameters for unsupported models
        return const PKParameters(
          V1: 0, V2: 0, V3: 0,
          Cl1: 0, Cl2: 0, Cl3: 0,
          k10: 0, k12: 0, k21: 0, k13: 0, k31: 0, ke0: 0,
        );
    }
  }

  /// Calculate Marsh parameters
  static PKParameters _calculateMarshParameters(int sex, double weight, double height, double age) {
    final double V1 = 0.228 * weight;
    final double V2 = 0.463 * weight;
    final double V3 = 2.893 * weight;
    final double k10 = 0.119;
    final double k12 = 0.112;
    final double k21 = 0.055;
    final double k13 = 0.042;
    final double k31 = 0.0033;
    final double Cl1 = k10 * V1;
    final double Cl2 = k21 * V2;
    final double Cl3 = k31 * V3;
    final double ke0 = 1.2; // Updated from simulation.dart (was 0)

    // BIS parameters for propofol
    final double ce50 = 3.08 * math.exp(-0.00635 * (age - 35));
    final double baselineBIS = 93;
    final double delayBIS = 15 + math.exp(0.0517 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
      ce50: ce50, baselineBIS: baselineBIS, delayBIS: delayBIS,
    );
  }

  /// Calculate Schnider parameters (matches simulation.dart exactly)
  static PKParameters _calculateSchniderParameters(int sex, double weight, double height, double age) {
    // James Equation for LBM (matches simulation.dart calculation)
    final double lbm = (1.07 * weight - 148 * (weight / height) * (weight / height)) * (1 - sex) +
                       sex * (1.1 * weight - 128 * (weight / height) * (weight / height));

    final double V1 = 4.27; // litre
    final double V2 = 18.9 - 0.391 * (age - 53); // litre  
    final double V3 = 238.0; // litre

    final double k10 = (0.443 + 0.0107 * (weight - 77) - 0.0159 * (lbm - 59) + 0.0062 * (height - 177)); // per min
    final double k12 = (0.302 - 0.0056 * (age - 53)); // per min
    final double k13 = 0.196; // per min
    final double k21 = (1.29 - 0.024 * (age - 53)) / (18.9 - 0.391 * (age - 53)); // per min
    final double k31 = 0.0035; // per min
    final double ke0 = 0.456; // per min

    final double Cl1 = k10 * V1; // litre / min
    final double Cl2 = k21 * V2; // litre / min  
    final double Cl3 = k31 * V3; // litre / min

    // BIS parameters for propofol
    final double ce50 = 3.08 * math.exp(-0.00635 * (age - 35));
    final double baselineBIS = 93;
    final double delayBIS = 15 + math.exp(0.0517 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
      ce50: ce50, baselineBIS: baselineBIS, delayBIS: delayBIS,
    );
  }

  /// Calculate Eleveld parameters (improved accuracy over simulation.dart)
  static PKParameters _calculateEleveldParameters(int sex, double weight, double height, double age) {
    // Using opioid = true assumption (matches simulation.dart)
    bool opioid = true;
    
    // V1 calculation
    final double V1 = 6.28 * (weight / (weight + 33.6)) / (0.675675675676);
    
    // V2 calculation  
    final double V2 = 25.5 * (weight / 70) * math.exp(-0.0156 * (age - 35));
    
    // V3 calculation - full equation (more accurate than simulation.dart shortcut)
    final double V3 = 273 * math.exp(-0.0138 * age) * 
                      (sex * ((0.88 + (0.12) / (1 + math.pow(age / 13.4, -12.7))) * 
                             (9270 * weight / (6680 + 216 * weight / (height / 100) * (height / 100)))) +
                       (1 - sex) * ((1.11 + (-0.11) / (1 + math.pow(age / 7.1, -1.1))) *
                                   (9270 * weight / (8780 + 244 * weight / (height / 100) * (height / 100))))) / 54.4752059601377;
    
    // PMA calculation (matches simulation.dart)
    final double pma = age * 52.143 + 40;
    
    // Cl1 calculation
    final double Cl1 = ((sex == 1 ? 1.79 : 2.1) * math.pow((weight / 70), 0.75) *
                       math.pow(pma, 9.06) / (math.pow(pma, 9.06) + math.pow(42.3, 9.06))) *
                       (opioid ? math.exp(-0.00286 * age) : 1);
                       
    // Cl2 calculation
    final double Cl2 = 1.75 * math.pow(((25.5 * (weight / 70) * math.exp(-0.0156 * (age - 35))) / 25.5), 0.75) *
                       (1 + 1.3 * (1 - pma / (pma + 68.3)));
                       
    // Cl3 calculation - full equation (more accurate than simulation.dart)
    final double Cl3 = 1.11 * math.pow(((sex * ((0.88 + (0.12) / (1 + math.pow(age / 13.4, -12.7))) *
                                              (9270 * weight / (6680 + 216 * weight / (height / 100) * (height / 100)))) +
                                       (1 - sex) * ((1.11 + (-0.11) / (1 + math.pow(age / 7.1, -1.1))) *
                                                   (9270 * weight / (8780 + 244 * weight / (height / 100) * (height / 100))))) *
                                       (opioid ? math.exp(-0.0138 * age) : 1) / 54.4752059601377), 0.75) *
                       (pma / (pma + 68.3) / 0.964695544);

    // Rate constants
    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k13 = Cl3 / V1;
    final double k21 = Cl2 / V2;
    final double k31 = Cl3 / V3;
    final double ke0 = 0.146 * math.pow(weight / 70, -0.25);

    // BIS parameters for propofol
    final double ce50 = 3.08 * math.exp(-0.00635 * (age - 35));
    final double baselineBIS = 93;
    final double delayBIS = 15 + math.exp(0.0517 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
      ce50: ce50, baselineBIS: baselineBIS, delayBIS: delayBIS,
    );
  }

  /// Calculate Paedfusor parameters (matches simulation.dart exactly)
  static PKParameters _calculatePaedfusorParameters(int sex, double weight, double height, double age) {
    // Age-specific calculations from simulation.dart
    double k10 = 0.1527 * math.pow(weight, -0.3); // per min
    double k12 = 0.114; // per min  
    double k13 = 0.0419; // per min
    double k21 = 0.055; // per min
    double k31 = 0.0033; // per min
    double ke0 = 0.26; // per min
    
    double V1 = 0.4584 * weight;
    double V2 = V1 * k12 / k21;
    double V3 = V1 * k13 / k31;

    // Age-specific overrides from simulation.dart
    if (age == 13) {
      k10 = 0.0678; // per min
      V1 = 0.4 * weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;
    } else if (age == 14) {
      k10 = 0.0792; // per min
      V1 = 0.342 * weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;
    } else if (age == 15) {
      k10 = 0.0954; // per min
      V1 = 0.284 * weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;
    } else if (age == 16) {
      k10 = 0.119; // per min
      V1 = 0.22857 * weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;
    }

    final double Cl1 = k10 * V1;
    final double Cl2 = k21 * V2;
    final double Cl3 = k31 * V3;

    // BIS parameters for propofol
    final double ce50 = 3.08 * math.exp(-0.00635 * (age - 35));
    final double baselineBIS = 93;
    final double delayBIS = 15 + math.exp(0.0517 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
      ce50: ce50, baselineBIS: baselineBIS, delayBIS: delayBIS,
    );
  }

  /// Calculate Kataria parameters (matches simulation.dart exactly)
  static PKParameters _calculateKatariaParameters(int sex, double weight, double height, double age) {
    // Kataria pediatric parameters from simulation.dart
    final double k10 = 0.085; // per min
    final double k12 = 0.188; // per min
    final double k13 = 0.063; // per min
    final double k21 = 0.102; // per min
    final double k31 = 0.0038; // per min
    final double ke0 = 0; // per min (plasma targeting)

    final double V1 = 0.41 * weight;
    final double V2 = 0.78 * weight + 3.1 * age;
    final double V3 = 6.9 * weight;

    final double Cl1 = k10 * V1;
    final double Cl2 = k21 * V2;
    final double Cl3 = k31 * V3;

    // BIS parameters for propofol
    final double ce50 = 3.08 * math.exp(-0.00635 * (age - 35));
    final double baselineBIS = 93;
    final double delayBIS = 15 + math.exp(0.0517 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
      ce50: ce50, baselineBIS: baselineBIS, delayBIS: delayBIS,
    );
  }
}

/// Future models that can be implemented by extending this file
enum FutureModels {
  RemifentanilMinto,
  RemifentanilEleveld, 
  DexmedetomidineHannivoort,
  RemimazolamEleveld,
}

extension FuturePKCalculation on FutureModels {
  /// Calculate pharmacokinetic parameters for future models
  PKParameters calculatePKParameters({
    required Sex sex,
    required int weight,
    required int height,
    required int age,
  }) {
    final double weightKg = weight.toDouble();
    final double heightCm = height.toDouble();
    final double ageYr = age.toDouble();
    final int sexInt = sex == Sex.Male ? 1 : 0;

    switch (this) {
      case FutureModels.RemifentanilMinto:
        return _calculateMintoParameters(sexInt, weightKg, heightCm, ageYr);
      case FutureModels.RemifentanilEleveld:
        return _calculateRemifentanilEleveldParameters(sexInt, weightKg, heightCm, ageYr);
      case FutureModels.DexmedetomidineHannivoort:
        return _calculateHannivoortParameters(sexInt, weightKg, heightCm, ageYr);
      case FutureModels.RemimazolamEleveld:
        return _calculateRemimazolamEleveldParameters(sexInt, weightKg, heightCm, ageYr);
    }
  }

  /// Calculate Minto Remifentanil parameters
  static PKParameters _calculateMintoParameters(int sex, double weight, double height, double age) {
    // James Equation for LBM
    final double lbm = (1.07 * weight - 148 * (weight / height) * (weight / height)) * (1 - sex) +
                       sex * (1.1 * weight - 128 * (weight / height) * (weight / height));

    final double V1 = 5.1 - 0.0201 * (age - 40) + 0.072 * (lbm - 55);
    final double V2 = 9.82 - 0.0811 * (age - 40) + 0.108 * (lbm - 55);
    final double V3 = 5.42;
    final double Cl1 = 2.6 - 0.0162 * (age - 40) + 0.0191 * (lbm - 55);
    final double Cl2 = 2.05 - 0.0301 * (age - 40);
    final double Cl3 = 0.076 - 0.00113 * (age - 40);

    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k21 = Cl2 / V2;
    final double k13 = Cl3 / V1;
    final double k31 = Cl3 / V3;
    final double ke0 = 0.595 - 0.007 * (age - 40);

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Eleveld Remifentanil parameters
  static PKParameters _calculateRemifentanilEleveldParameters(int sex, double weight, double height, double age) {
    // Reference individual = 35 yo, male, 70 kg, 170 cm
    final double ffm = sex * (0.88 + (1 - 0.88) / (1 + math.pow(age / 13.4, -12.7))) *
                          (9270 * weight / (6680 + 216 * (weight / (height / 100)) * (weight / (height / 100)))) +
                       (1 - sex) * (1.11 + (1 - 1.11) / (1 + math.pow(age / 7.1, -1.1))) *
                          (9270 * weight / (8780 + 244 * (weight / (height / 100)) * (weight / (height / 100))));
    
    final double siz = ffm / 54.4752;
    final double ksex = sex + (1 - sex) * (1 + (0.470 * math.pow(age, 6) / (math.pow(age, 6) + math.pow(12, 6))) *
                                                (1 - math.pow(age, 6) / (math.pow(age, 6) + math.pow(45, 6))));

    final double V1 = 5.81 * siz * math.exp(-0.00554 * (age - 35));
    final double V2 = 8.82 * siz * math.exp(-0.00327 * (age - 35)) * ksex;
    final double V3 = 5.03 * siz * math.exp(-0.0315 * (age - 35)) * math.exp(-0.0360 * (weight - 70));
    final double Cl1 = 2.58 * math.pow(siz, 0.75) * (weight * weight / (weight * weight + 2.88 * 2.88) / (70 * 70 / (70 * 70 + 2.88 * 2.88))) * ksex * math.exp(-0.00327 * (age - 35));
    final double Cl2 = 1.72 * math.pow(V2 / 8.82, 0.75) * math.exp(-0.00554 * (age - 35)) * ksex;
    final double Cl3 = 0.124 * math.pow(V3 / 5.03, 0.75) * math.exp(-0.00554 * (age - 35));

    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k21 = Cl2 / V2;
    final double k13 = Cl3 / V1;
    final double k31 = Cl3 / V3;
    final double ke0 = 1.09 * math.exp(-0.0289 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Hannivoort Dexmedetomidine parameters
  static PKParameters _calculateHannivoortParameters(int sex, double weight, double height, double age) {
    final double V1 = 1.78 * weight / 70;
    final double V2 = 30.3 * weight / 70;
    final double V3 = 52.0 * weight / 70;
    final double Cl1 = 0.686 * math.pow(weight / 70, 0.75);
    final double Cl2 = 2.98 * math.pow(V2 / 30.3, 0.75);
    final double Cl3 = 0.602 * math.pow(V3 / 52.0, 0.75);

    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k21 = Cl2 / V2;
    final double k13 = Cl3 / V1;
    final double k31 = Cl3 / V3;
    final double ke0 = 0; // No effect site for plasma targeting

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Remimazolam Eleveld parameters
  static PKParameters _calculateRemimazolamEleveldParameters(int sex, double weight, double height, double age) {
    final int liver = 1; // Assume normal liver function
    
    final double V1 = 4.31 * weight / 70;
    final double V2 = 12.3 * weight / 70;
    final double V3 = 18.6 * weight / 70 * math.exp(0.00731 * (age - 35)) * (sex + (1 - sex) * math.exp(0.287)) * ((1 - liver) + liver * math.exp(0.824));
    final double Cl1 = 1.12 * math.pow(weight / 70, 0.75) * (sex + (1 - sex) * math.exp(0.163)) * math.exp(-0.139); // Assume opioid present
    final double Cl2 = 1.45 * math.pow(V2 / 12.3, 0.75);
    final double Cl3 = 0.298 * math.pow(V3 / 18.6, 0.75);

    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k21 = Cl2 / V2;
    final double k13 = Cl3 / V1;
    final double k31 = Cl3 / V3;
    final double ke0 = 0.145 * math.exp(-0.0106 * (age - 35));

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }
}