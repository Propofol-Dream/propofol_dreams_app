import 'dart:math';
import 'dart:convert';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:propofol_dreams_app/models/target.dart';

class Simulation {
  Model model;
  Patient patient;
  Pump pump;
  Operation operation;

  Simulation(
      {required this.model,
      required this.patient,
      required this.pump,
      required this.operation});

  Simulation copy() {
    return Simulation(
        model: model, patient: patient, pump: pump, operation: operation);
  }

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
  }) get variables {
    // print('variables');
    double k10 = 0,
        k12 = 0,
        k13 = 0,
        k21 = 0,
        k31 = 0,
        ke0 = 0,
        V1 = 0,
        V2 = 0,
        V3 = 0;
    if (model == Model.Paedfusor) {
      k10 = 0.1527 * pow(patient.weight, -0.3); // per min;
      k12 = 0.114; // per min
      k13 = 0.0419; // per min
      k21 = 0.055; // per min
      k31 = 0.0033; // per min
      ke0 = 0.26; // per min

      V1 = 0.4584 * patient.weight;
      V2 = V1 * k12 / k21;
      V3 = V1 * k13 / k31;

      if (patient.age == 13) {
        k10 = 0.0678; // per min

        V1 = 0.4 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (patient.age == 14) {
        k10 = 0.0792; // per min

        V1 = 0.342 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (patient.age == 15) {
        k10 = 0.0954; // per min

        V1 = 0.284 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      } else if (patient.age == 16) {
        k10 = 0.119; // per min

        V1 = 0.22857 * patient.weight;
        V2 = V1 * k12 / k21;
        V3 = V1 * k13 / k31;
      }
    } else if (model == Model.Kataria) {
      k10 = 0.085; // per min
      k12 = 0.188; // per min
      k13 = 0.063; // per min
      k21 = 0.102; // per min
      k31 = 0.0038; // per min
      ke0 = 0; // per min

      V1 = 0.41 * patient.weight;
      V2 = 0.78 * patient.weight + 3.1 * patient.age;
      V3 = 6.9 * patient.weight;
    } else if (model == Model.Marsh) {
      k10 = 0.119; // per min
      k12 = 0.112; // per min
      k13 = 0.042; // per min
      k21 = 0.055; // per min
      k31 = 0.0033; // per min
      ke0 = 1.2; // per min

      V1 = 0.228 * patient.weight;
      V2 = 0.463 * patient.weight;
      V3 = 2.893 * patient.weight;
    } else if (model == Model.Schnider) {
      V1 = 4.27; //litre
      V2 = 18.9 - 0.391 * (patient.age - 53); //litre
      V3 = 238.0; //litre

      k10 = (0.443 +
          0.0107 * (patient.weight - 77) -
          0.0159 * (patient.lbm - 59) +
          0.0062 * (patient.height - 177)); // per min

      k12 = (0.302 - 0.0056 * (patient.age - 53)); // per min
      k13 = 0.196; // per min
      k21 = (1.29 - 0.024 * (patient.age - 53)) /
          (18.9 - 0.391 * (patient.age - 53)); // per min
      k31 = 0.0035; // per min
      ke0 = 0.456; // per min
      // t_half_keo = np.log(2) / (ke0 * steps_per_min) //deprecated
    }
    double Cl1 = k10 * V1; //litre / steps per min
    double Cl2 = k21 * V2; //litre / steps per min
    double Cl3 = k31 * V3; //litre / steps per min

    if (model == Model.Eleveld) {
      bool opioid = true; // arbitrarily set YES to intraop opioids

      V1 = 6.28 * (patient.weight / (patient.weight + 33.6)) / (0.675675675676);
      V2 = 25.5 * (patient.weight / 70) * exp(-0.0156 * (patient.age - 35));

      V3 = 273 *
          patient.ffm *
          (opioid ? exp(-0.0138 * patient.age) : 1) /
          54.4752059601377;

      Cl1 = ((patient.gender == Gender.Male ? 1.79 : 2.1) *
              (pow((patient.weight / 70), 0.75)) *
              (pow(patient.pma, 9.06)) /
              (pow(patient.pma, 9.06) + pow(42.3, 9.06))) *
          (opioid ? exp(-0.00286 * patient.age) : 1);

      Cl2 = 1.75 *
          (pow(
              ((25.5 *
                      (patient.weight / 70) *
                      exp(-0.0156 * (patient.age - 35))) /
                  25.5),
              0.75)) *
          (1 + 1.3 * (1 - patient.pma / (patient.pma + 68.3)));

      Cl3 = 1.11 *
          (pow(
              (patient.ffm *
                  (opioid ? exp(-0.0138 * patient.age) : 1) /
                  54.4752059601377),
              0.75)) *
          (patient.pma / (patient.pma + 68.3) / 0.964695544);

      k10 = Cl1 / V1;
      k12 = Cl2 / V1;
      k13 = Cl3 / V1;
      k21 = Cl2 / V2;
      k31 = Cl3 / V3;
      ke0 = 0.146 * pow((patient.weight / 70), -0.25);
    }

    double ce50 = 3.08 * exp(-0.00635 * (patient.age - 35));
    double baselineBIS = 93;
    double delayBIS = 15 + exp(0.0517 * (patient.age - 35));

    return (
      V1: V1,
      V2: V2,
      V3: V3,
      k10: k10,
      k12: k12,
      k13: k13,
      k21: k21,
      k31: k31,
      ke0: ke0,
      Cl1: Cl1,
      Cl2: Cl2,
      Cl3: Cl3,
      ce50: ce50,
      baselineBIS: baselineBIS,
      delayBIS: delayBIS,
    );
  }

  Map<String, List> get calibrate {
    Pump testPump = pump.copy();

    for (Duration i = Duration.zero;
        i < Duration(seconds: 100);
        i = i + testPump.timeStep) {
      double maxInfusion = (testPump.density * testPump.maxPumpRate).toDouble();
      testPump.updatePumpInfusionSequence(at: i, pumpInfusion: maxInfusion);
    }

    return test(testPump: testPump);
  }

  double get maxCalibratedEffect {
    List<double> result = calibrate['concentrations_effect'] as List<double>;
    return result.reduce(max);
  }

  Map<String, List> get peak {
    return test(initialA1: 10);
  }

  double get maxCe {
    List<double> ce = peak['concentrations_effect'] as List<double>;
    return ce.reduce(max);
  }

  Map<String, List> test({Pump? testPump, double? initialA1}) {
    Operation trialOperation =
        Operation(target: 0, duration: const Duration(seconds: 720));

    Duration time = Duration.zero;
    var variables = this.variables;
    double k21 = variables.k21;
    double k31 = variables.k31;
    double k10 = variables.k10;
    double k12 = variables.k12;
    double k13 = variables.k13;
    double V1 = variables.V1;
    double ke0 = variables.ke0;

    List<double> A1s = [];
    List<double> A2s = [];
    List<double> A3s = [];
    List<Duration> times = [];
    List<int> steps = [];
    List<double> pumpInfs = [];
    List<double> concentrations = [];
    List<double> concentrationsEffect = [];

    double timeStep = pump.timeStep.inMilliseconds / 1000; //sec
    int operationDuration = trialOperation.duration.inSeconds;
    double totalStep = operationDuration / timeStep;

    for (int step = 0; step <= totalStep; step += 1) {
      double? manualPumpInf = testPump?.pumpInfusionSequences?[time];

      double pumpInf = manualPumpInf ?? 0;

      double A2 = step == 0
          ? 0
          : A2s.last + (k12 * A1s.last - k21 * A2s.last) * timeStep / 60;

      double A3 = step == 0
          ? 0
          : A3s.last + (k13 * A1s.last - k31 * A3s.last) * timeStep / 60;

      double A1 = step == 0
          ? initialA1 ?? 0
          : (pumpInfs.last / 60 +
                      A2 * k21 +
                      A3 * k31 -
                      A1s.last * (k10 + k12 + k13)) *
                  timeStep /
                  60 +
              A1s.last;

      double concentration = A1 / V1;
      double concentrationEffect = step == 0
          ? 0
          : concentrationsEffect.last +
              ke0 *
                  (concentrations.last - concentrationsEffect.last) *
                  timeStep /
                  60;

      steps.add(step);
      times.add(time);
      pumpInfs.add(pumpInf);
      A1s.add(A1);
      A2s.add(A2);
      A3s.add(A3);
      concentrations.add(concentration);
      concentrationsEffect.add(concentrationEffect);
      time = time + pump.timeStep;
    }

    return ({
      'steps': steps,
      'times': times,
      'pump_infs': pumpInfs,
      'A1s': A1s,
      'A2s': A2s,
      'A3s': A3s,
      'concentrations': concentrations,
      'concentrations_effect': concentrationsEffect,
    });
  }

  // TODO: depreciate maxCeReachesAt, as it is not in use
  // Duration get maxCeReachesAt {
  //   List<Duration> durations = peak['times'] as List<Duration>;
  //   List<double> ces = peak['concentrations_effect'] as List<double>;
  //   int index = ces.indexOf(maxCe);
  //
  //   return durations[index];
  // }

  // TODO: depreciate ceAt, as it is not in use
  // double ceAt({required Duration duration}) {
  //   List<Duration> durations = peak['times'] as List<Duration>;
  //   int index = durations.indexOf(duration);
  //   List<double> ces = peak['concentrations_effect'] as List<double>;
  //   return ces[index];
  // }

  double estimateBolusInfused({required double targetIncreasedBy}) {
    if (targetIncreasedBy <= 0) return 0;

    double result = 0.0;
    if (model.target == Target.Effect_Site) {
      result = targetIncreasedBy / maxCe * pump.density;
    } else if (model.target == Target.Plasma) {
      double V1 = variables.V1;
      result = targetIncreasedBy * V1;
    }
    return result;
  }

  double estimateTargetIncreased({required double bolusInfusedBy}) {
    if (bolusInfusedBy <= 0) return 0;

    double result = 0.0;
    if (model.target == Target.Effect_Site) {
      result = bolusInfusedBy * maxCe / pump.density;
    } else if (model.target == Target.Plasma) {
      result = (-15.693 +
              sqrt(pow(15.693, 2) +
                  4 * 0.2197 * bolusInfusedBy * 70 / patient.weight)) /
          (0.4394);
      result = result / 4 * operation.target;
      // Pump testPump = pump.copy();
      // testPump.infuseBolus(startsAt: Duration.zero, bolus: bolusInfusedBy);
      // Map<String, List> testResult = test(testPump: testPump);
      // List<double> CP = testResult['concentrations'] as List<double>;
      // result = CP.reduce(max);

      // double V1 = variables['V1'] as double;
      // result = bolusInfusedBy / V1;
    }
    return result;
  }

  ({
    List<double> A1Changes,
    List<double> A1s,
    List<double> A2s,
    List<double> A3s,
    List<double> concentrations,
    List<double> concentrationsEffect,
    List<double> cumulativeInfusedDosages,
    List<double> cumulativeInfusedVolumes,
    List<double> eBISEstimates,
    List<double> infs,
    List<double> overshootTimes,
    List<double> pumpInfs,
    List<int> steps,
    List<double> target,
    List<Duration> times
  }) get estimate {
    // print('esstimate');
    Duration time = Duration.zero;
    var variables = this.variables;
    double k21 = variables.k21;
    double k31 = variables.k31;
    double k10 = variables.k10;
    double k12 = variables.k12;
    double k13 = variables.k13;
    double V1 = variables.V1;
    double ke0 = variables.ke0;

    //List for calibrated_effect only
    List<double> A1s = [];
    List<double> A2s = [];
    List<double> A3s = [];
    List<Duration> times = [];
    List<int> steps = [];
    List<double> pumpInfs = []; //mg per hr
    List<double> concentrations = [];
    List<double> concentrationsEffect = [];

    //List for volume estimation
    List<double> targets = [];
    List<double> overshootTimes = [];
    List<double> infs = []; //mg per hr
    List<double> A1Changes = [];
    List<double> cumulativeInfusedDosages = [];
    List<double> cumulativeInfusedVolumes = []; // mL

    double maxCalibratedE = maxCalibratedEffect;

    double timeStep = pump.timeStep.inMilliseconds /
        1000; // this is to allow time_step in milliseconds
    int operationDuration = operation.duration.inSeconds;
    double totalStep = operationDuration / timeStep;

    //find max Pump Infusion Rate
    double maxPumpInfusionRate =
        (pump.density * pump.maxPumpRate).toDouble(); // mg per hr

    // Calculate eBIS
    double baselineBIS = variables.baselineBIS;
    double ce50 = variables.ce50;
    List<double> eBISEstimates = [];

    // print(ce50);

    for (int step = 0; step <= totalStep; step += 1) {
      //find manual pump inf
      double? manualPumpInf = pump.pumpInfusionSequences?[time];

      //find manual target
      double? manualTarget = pump.targetSequences?[time];

      double A2 = step == 0
          ? 0
          : A2s.last + (k12 * A1s.last - k21 * A2s.last) * timeStep / 60;

      double A3 = step == 0
          ? 0
          : A3s.last + (k13 * A1s.last - k31 * A3s.last) * timeStep / 60;

      double concentrationEffect = step == 0
          ? 0
          : concentrationsEffect.last +
              ke0 *
                  (concentrations.last - concentrationsEffect.last) *
                  timeStep /
                  60;

      double target =
          step == 0 ? operation.target : manualTarget ?? targets.last;

      double overshootTime = (step == 0
          ? target / maxCalibratedE * 100 - 1
          : (target - targets.last > 0
              ? (target - targets.last) / maxCalibratedE * 100 - 1
              : overshootTimes.last - timeStep));

      double A1Change = step == 0
          ? 0
          : (A2 * k21 + A3 * k31 - A1s.last * (k10 + k12 + k13)) *
              timeStep /
              60;

      double? inf;
      double? pumpInf;
      double? A1;

      if (model.target == Target.Effect_Site) {
        A1 = step == 0
            ? 0
            : (pumpInfs.last / 60) * timeStep / 60 + A1Change + A1s.last;

        inf = 3600 * (target * V1 - A1Change - A1) / timeStep;

        pumpInf = manualPumpInf ??
            ((concentrationEffect > target
                ? 0.0
                : (overshootTime > 0.0
                    ? maxPumpInfusionRate
                    : (inf < 0.0 ? 0.0 : inf))));
      } else {
        inf = step == 0
            ? 0
            : 3600 * (target * V1 - A1Change - A1s.last) / timeStep;

        pumpInf = manualPumpInf ??
            (step == 0
                ? inf
                : (inf > maxPumpInfusionRate
                    ? maxPumpInfusionRate
                    : (inf < 0 ? 0 : inf)));

        A1 = step == 0
            ? 0
            : (pumpInf / 60) * timeStep / 60 + A1Change + A1s.last;
      }

      double concentration = A1 / V1;

      double cumulativeInfusedDosage = step == 0
          ? pumpInf * timeStep / 3600
          : cumulativeInfusedDosages.last + pumpInf * timeStep / 3600;

      double cumulativeInfusedVolume = cumulativeInfusedDosage / pump.density;

      double eBISEstimate = concentrationEffect > ce50
          ? baselineBIS *
              (pow(ce50, 1.47)) /
              (pow(ce50, 1.47) + pow(concentrationEffect, 1.47))
          : baselineBIS *
              (pow(ce50, 1.89)) /
              (pow(ce50, 1.89) + pow(concentrationEffect, 1.89));

      steps.add(step);
      times.add(time);
      targets.add(target);
      overshootTimes.add(overshootTime);
      infs.add(inf);
      pumpInfs.add(pumpInf);
      A1Changes.add(A1Change);
      A1s.add(A1);
      A2s.add(A2);
      A3s.add(A3);
      concentrations.add(concentration);
      concentrationsEffect.add(concentrationEffect);
      cumulativeInfusedDosages.add(cumulativeInfusedDosage);
      cumulativeInfusedVolumes.add(cumulativeInfusedVolume);
      eBISEstimates.add(eBISEstimate);
      time = time + pump.timeStep;
    }
    // print(times.last);

    return (
      steps: steps,
      times: times,
      target: targets,
      overshootTimes: overshootTimes,
      infs: infs,
      pumpInfs: pumpInfs,
      A1Changes: A1Changes,
      A1s: A1s,
      A2s: A2s,
      A3s: A3s,
      concentrations: concentrations,
      concentrationsEffect: concentrationsEffect,
      cumulativeInfusedDosages: cumulativeInfusedDosages,
      cumulativeInfusedVolumes: cumulativeInfusedVolumes,
    eBISEstimates: eBISEstimates
    );
  }

  double get weightGuess {
    double guess = 0.0;

    if (pump.density == 10) {
      guess = patient.gender == Gender.Female
          ? (15.24 +
              1.033 * patient.weight -
              0.001552 * patient.weight * patient.weight +
              2.119e-6 * patient.weight * patient.weight * patient.weight +
              8.909e-5 * patient.height * patient.height -
              4.423e-4 * patient.weight * patient.bmi -
              0.1928 * patient.age +
              9.729e-4 * patient.age * patient.age -
              0.003927 * patient.age * patient.weight +
              1.779e-6 * patient.age * patient.weight * patient.weight +
              0.001165 * patient.age * patient.bmi -
              0.08306 * patient.bmi)
          : (15.03 +
              0.9526 * patient.weight -
              0.001513 * patient.weight * patient.weight +
              1.991e-6 * patient.weight * patient.weight * patient.weight +
              1.144e-4 * patient.height * patient.height -
              4.308e-4 * patient.weight * patient.bmi -
              0.2029 * patient.age +
              1.047e-3 * patient.age * patient.age -
              0.003866 * patient.age * patient.weight +
              3.305e-6 * patient.age * patient.weight * patient.weight +
              0.001263 * patient.age * patient.bmi -
              0.09866 * patient.bmi);
    } else {
      guess = patient.gender == Gender.Female
          ? (17.92 +
              0.9685 * patient.weight -
              0.001057 * pow(patient.weight, 2) +
              1.21e-6 * pow(patient.weight, 3) +
              9.414e-5 * pow(patient.height, 2) -
              4.366e-4 * patient.weight * patient.bmi -
              0.2552 * patient.age +
              1.281e-3 * pow(patient.age, 2) -
              0.003136 * patient.age * patient.weight -
              6.911e-7 * patient.age * pow(patient.weight, 2) +
              0.001090 * patient.age * patient.bmi -
              0.07710 * patient.bmi)
          : (16.42 +
              0.9375 * patient.weight -
              0.001365 * pow(patient.weight, 2) +
              1.838e-6 * pow(patient.weight, 3) +
              1.256e-4 * pow(patient.height, 2) -
              4.43e-4 * patient.weight * patient.bmi -
              0.2637 * patient.age +
              1.557e-3 * pow(patient.age, 2) -
              0.003772 * patient.age * patient.weight +
              3.321e-6 * patient.age * pow(patient.weight, 2) +
              0.001355 * patient.age * patient.bmi -
              0.09703 * patient.bmi);
    }

    return guess;
  }

  double get bolusGuess {
    double guess = 0.0;

    if (pump.density == 10) {
      guess = patient.gender == Gender.Female
          ? (41.31 +
              3.063 * patient.weight -
              2.312e-3 * patient.weight * patient.weight +
              6.172e-6 * patient.weight * patient.weight * patient.weight -
              0.1026 * patient.height +
              4.375e-4 * patient.height * patient.height -
              5.997e-4 * patient.weight * patient.bmi -
              0.5831 * patient.age +
              0.004267 * patient.age * patient.age -
              0.01399 * patient.age * patient.weight -
              3.716e-5 * patient.age * patient.weight * patient.weight +
              3.345e-7 *
                  patient.age *
                  patient.age *
                  patient.weight *
                  patient.weight +
              0.001912 * patient.age * patient.bmi -
              0.1885 * patient.bmi)
          : (47.92 +
              2.983 * patient.weight -
              2.339e-3 * patient.weight * patient.weight +
              6.439e-6 * patient.weight * patient.weight * patient.weight -
              0.1693 * patient.height +
              6.393e-4 * patient.height * patient.height -
              5.025e-4 * patient.weight * patient.bmi -
              0.5454 * patient.age +
              0.003780 * patient.age * patient.age -
              0.01376 * patient.age * patient.weight -
              4.149e-5 * patient.age * patient.weight * patient.weight +
              3.661e-7 *
                  patient.age *
                  patient.age *
                  patient.weight *
                  patient.weight +
              0.002259 * patient.age * patient.bmi -
              0.2682 * patient.bmi);
    } else {
      guess = patient.gender == Gender.Female
          ? (58.18 +
              3.358 * patient.weight -
              3.991e-3 * pow(patient.weight, 2) +
              8.628e-6 * pow(patient.weight, 3) -
              0.3385 * patient.height +
              1.058e-3 * pow(patient.height, 2) -
              0.5662 * patient.age +
              0.005773 * pow(patient.age, 2) -
              0.01759 * patient.age * patient.weight -
              2.245e-5 * patient.age * pow(patient.weight, 2) +
              3.48e-7 * pow(patient.age, 2) * pow(patient.weight, 2) +
              0.002268 * patient.age * patient.bmi -
              0.3347 * patient.bmi)
          : (36.37 +
              3.024 * patient.weight -
              2.734e-3 * pow(patient.weight, 2) +
              6.121e-6 * pow(patient.weight, 3) +
              3.25e-4 * pow(patient.height, 2) -
              1.287e-3 * patient.weight * patient.bmi -
              1.023 * patient.age +
              0.01396 * pow(patient.age, 2) -
              4.776e-5 * pow(patient.age, 3) -
              0.01692 * patient.age * patient.weight -
              1.859e-5 * patient.age * pow(patient.weight, 2) +
              2.843e-7 * pow(patient.age, 2) * pow(patient.weight, 2) +
              0.002622 * patient.age * patient.bmi -
              0.077 * patient.bmi);
    }

    // guess = guess / 4 * operation.target;

    return guess;
  }

  //This is not initial bolus, Engbert's algo doesn't require bolus to be calculated
  //This was designed for calculate hand push bolus, but may not be required any more
  double get bolus {
    if (model.target == Target.Effect_Site) {
      return operation.target / maxCe * pump.density;
    } else if (model.target == Target.Plasma) {
      double V1 = variables.V1 as double;
      return operation.target * V1;
    } else {
      return -1;
    }
  }

  //This was hand push bolus, not pump infused bolus, and may not be required any more
  Duration get pushBolusDuration {
    double infusionInSecs =
        bolus / (pump.density * kMaxHumanlyPossiblePushRate / 3600);
    double timeStepInSecs = pump.timeStep.inMilliseconds / 1000;

    int infusionInTimeStep = (infusionInSecs / timeStepInSecs).floor();
    return Duration(
        milliseconds: pump.timeStep.inMilliseconds * (infusionInTimeStep + 1));
  }

  //This was hand push bolus, not pump infused bolus, and may not be required any more
  double get pushBolusRate {
    return bolus / (pushBolusDuration.inMilliseconds / 1000 / 3600);
  }

  List<double> cumulativeSum(List<double> l) {
    double cumSum = 0;
    List<double> cumSums = [];
    for (double d in l) {
      cumSum += d;
      cumSums.add(cumSum);
    }
    return cumSums;
  }

  // TODO: depreciate toCsv, new version implemented
  // String toCsv(Map<String, dynamic> map) {
  //   String csv = '';
  //   int length = 0;
  //
  //   for (var key in map.keys) {
  //     csv = '$csv$key, ';
  //     length = map[key].length;
  //   }
  //   csv = '${csv.substring(0, csv.length - 2)}\n';
  //
  //   for (int i = 0; i < length; i++) {
  //     // print(i.toString() + ' : ' + (length-1).toString());
  //     for (var key in map.keys) {
  //       csv = '$csv${map[key][i]}, ';
  //     }
  //     csv = '${csv.substring(0, csv.length - 2)}\n';
  //   }
  //   return csv;
  // }

  // TODO: depreciate toJson, new version implemented
  // Map<String, String> toJson(Map<String, dynamic> map) {
  //   Map<String, String> json = {};
  //
  //   for (var key in map.keys) {
  //     if (!json.containsKey(key)) {
  //       String values = '[';
  //       for (var val in map[key]) {
  //         values = '$values\'$val\', ';
  //       }
  //       values = '${values.substring(0, values.length - 2)}]';
  //       // print(values);
  //       json['\'${key.toString()}\''] = values;
  //     }
  //   }
  //   return (json);
  // }

  String toCsv() {
    var estimate = this.estimate;

    List<List<dynamic>> data = [
      [
        'steps',
        'times',
        'target',
        'overshootTimes',
        'infs',
        'pumpInfs',
        'A1Changes',
        'A1s',
        'A2s',
        'A3s',
        'concentrations',
        'concentrationsEffect',
        'cumulativeInfusedDosages',
        'cumulativeInfusedVolumes',
        'eBISEstimates'
      ]
    ];

    // Assuming all lists are of the same length
    for (int i = 0; i < estimate.steps.length; i++) {
      List<dynamic> row = [
        estimate.steps[i],
        estimate.times[i].toString(), // List<Duration>
        estimate.target[i],
        estimate.overshootTimes[i],
        estimate.infs[i],
        estimate.pumpInfs[i],
        estimate.A1Changes[i],
        estimate.A1s[i],
        estimate.A2s[i],
        estimate.A3s[i],
        estimate.concentrations[i],
        estimate.concentrationsEffect[i],
        estimate.cumulativeInfusedDosages[i],
        estimate.cumulativeInfusedVolumes[i],
        estimate.eBISEstimates[i],
      ];
      data.add(row);
    }
    return data.map((row) => row.join(',')).join('\n');
  }

  @override
  String toString() {
    return '{model: $model, patient: $patient, operation: $operation, pump: $pump}';
  }

  Map<String, dynamic> toJson() {
    var estimate = this.estimate;
    return {
      'steps': estimate.steps.map((item) => item.toString()).toList(),
      'times': estimate.times.map((item) => item.toString()).toList(),
      // Convert Duration to String
      'target': estimate.target.map((item) => item.toString()).toList(),
      'overshootTimes':
          estimate.overshootTimes.map((item) => item.toString()).toList(),
      'infs': estimate.infs.map((item) => item.toString()).toList(),
      'pumpInfs': estimate.pumpInfs.map((item) => item.toString()).toList(),
      'A1Changes': estimate.A1Changes.map((item) => item.toString()).toList(),
      'A1s': estimate.A1s.map((item) => item.toString()).toList(),
      'A2s': estimate.A2s.map((item) => item.toString()).toList(),
      'A3s': estimate.A3s.map((item) => item.toString()).toList(),
      'concentrations':
          estimate.concentrations.map((item) => item.toString()).toList(),
      'concentrationsEffect':
          estimate.concentrationsEffect.map((item) => item.toString()).toList(),
      'cumulativeInfusedDosages': estimate.cumulativeInfusedDosages
          .map((item) => item.toString())
          .toList(),
      'cumulativeInfusedVolumes': estimate.cumulativeInfusedVolumes
          .map((item) => item.toString())
          .toList(),
      'eBISEstimates': estimate.eBISEstimates
          .map((item) => item.toString())
          .toList(),
    };
  }
}
