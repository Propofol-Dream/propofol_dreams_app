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

  @override
  String toString() {
    return 'PKParameters(V1: $V1, V2: $V2, V3: $V3, Cl1: $Cl1, Cl2: $Cl2, Cl3: $Cl3, k10: $k10, k12: $k12, k21: $k21, k13: $k13, k31: $k31, ke0: $ke0)';
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
    final double ke0 = 0; // Plasma targeting

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Schnider parameters
  static PKParameters _calculateSchniderParameters(int sex, double weight, double height, double age) {
    // James Equation for LBM
    final double lbm = (1.07 * weight - 148 * (weight / height) * (weight / height)) * (1 - sex) +
                       sex * (1.1 * weight - 128 * (weight / height) * (weight / height));

    final double V1 = 4.27;
    final double V2 = 18.9 - 0.391 * (age - 53);
    final double V3 = 238;
    final double k10 = (0.443 + 0.0107 * (weight - 77) - 0.0159 * (lbm - 59) + 0.0062 * (height - 177));
    final double k12 = 0.302 - 0.0056 * (age - 53);
    final double k21 = (1.29 - 0.024 * (age - 53)) / (18.9 - 0.391 * (age - 53));
    final double k13 = 0.196;
    final double k31 = 0.0035;
    final double ke0 = 0.456;

    final double Cl1 = k10 * V1;
    final double Cl2 = k21 * V2;
    final double Cl3 = k31 * V3;

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Eleveld parameters
  static PKParameters _calculateEleveldParameters(int sex, double weight, double height, double age) {
    final double V1 = 6.28 * (weight / (weight + 33.6)) / (0.675675675676);
    final double V2 = 25.5 * (weight / 70) * math.exp(-0.0156 * (age - 35));
    final double V3 = 273 * math.exp(-0.0138 * age) * 
                      (sex * ((0.88 + (0.12) / (1 + math.pow(age / 13.4, -12.7))) * 
                             (9270 * weight / (6680 + 216 * weight / (height / 100) * (height / 100)))) +
                       (1 - sex) * ((1.11 + (-0.11) / (1 + math.pow(age / 7.1, -1.1))) *
                                   (9270 * weight / (8780 + 244 * weight / (height / 100) * (height / 100))))) / 54.4752059601377;
    
    final double Cl1 = ((sex * 1.79 + (1 - sex) * 2.1) * math.pow((weight / 70), 0.75) *
                       math.pow((age * 52.143 + 40), 9.06) / (math.pow((age * 52.143 + 40), 9.06) + math.pow(42.3, 9.06))) *
                       math.exp(-0.00286 * age);
    final double Cl2 = 1.75 * math.pow(((25.5 * (weight / 70) * math.exp(-0.0156 * (age - 35))) / 25.5), 0.75) *
                       (1 + 1.3 * (1 - (age * 52.143 + 40) / ((age * 52.143 + 40) + 68.3)));
    final double Cl3 = 1.11 * math.pow(((sex * ((0.88 + (0.12) / (1 + math.pow(age / 13.4, -12.7))) *
                                              (9270 * weight / (6680 + 216 * weight / (height / 100) * (height / 100)))) +
                                       (1 - sex) * ((1.11 + (-0.11) / (1 + math.pow(age / 7.1, -1.1))) *
                                                   (9270 * weight / (8780 + 244 * weight / (height / 100) * (height / 100))))) *
                                       math.exp(-0.0138 * age) / 54.4752059601377), 0.75) *
                       ((age * 52.143 + 40) / ((age * 52.143 + 40) + 68.3) / 0.964695544);

    final double k10 = Cl1 / V1;
    final double k12 = Cl2 / V1;
    final double k21 = Cl2 / V2;
    final double k13 = Cl3 / V1;
    final double k31 = Cl3 / V3;
    final double ke0 = 0.146 * math.pow(weight / 70, -0.25);

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Paedfusor parameters (simplified pediatric model)
  static PKParameters _calculatePaedfusorParameters(int sex, double weight, double height, double age) {
    // Simplified pediatric parameters - would need actual Paedfusor equations
    final double V1 = 0.458 * weight;
    final double V2 = 0.618 * weight;
    final double V3 = 3.856 * weight;
    final double k10 = 0.1527;
    final double k12 = 0.207;
    final double k21 = 0.0906;
    final double k13 = 0.0422;
    final double k31 = 0.0033;
    final double Cl1 = k10 * V1;
    final double Cl2 = k21 * V2;
    final double Cl3 = k31 * V3;
    final double ke0 = 0; // Plasma targeting

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
    );
  }

  /// Calculate Kataria parameters (pediatric)
  static PKParameters _calculateKatariaParameters(int sex, double weight, double height, double age) {
    // Kataria pediatric parameters
    final double V1 = 0.38 * weight;
    final double V2 = 0.59 * weight;
    final double V3 = 5.12 * weight;
    final double k10 = 0.0792 + 0.00347 * age;
    final double k12 = 0.0414;
    final double k21 = 0.0544;
    final double k13 = 0.0103;
    final double k31 = 0.00201;
    final double Cl1 = k10 * V1;
    final double Cl2 = k21 * V2;
    final double Cl3 = k31 * V3;
    final double ke0 = 0; // Plasma targeting

    return PKParameters(
      V1: V1, V2: V2, V3: V3,
      Cl1: Cl1, Cl2: Cl2, Cl3: Cl3,
      k10: k10, k12: k12, k21: k21, k13: k13, k31: k31, ke0: ke0,
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