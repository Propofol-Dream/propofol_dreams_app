import 'dart:math';

import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';
import 'package:propofol_dreams_app/models/target.dart';
import 'package:propofol_dreams_app/models/parameters.dart';

class Simulation {
  Model model;
  Patient patient;
  Pump pump;

  Simulation({required this.model, required this.patient, required this.pump});

  Simulation copy() {
    return Simulation(model: model, patient: patient, pump: pump);
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
    // Use new PKParameters system for cleaner, more accurate calculations
    final Sex sex = patient.sex;
    final pkParams = model.calculatePKParameters(
      sex: sex,
      weight: patient.weight,
      height: patient.height,
      age: patient.age,
    );
    
    return pkParams.toSimulationRecord();
  }

  ({
    List<double> A1s,
    List<double> A2s,
    List<double> A3s,
    List<double> concentrations,
    List<double> concentrationsEffect,
    List<double> pumpInfs,
    List<int> steps,
    List<Duration> times
  }) get calibrate {
    Pump testPump = pump.copy();

    for (Duration i = Duration.zero;
        i < const Duration(seconds: 100);
        i = i + testPump.timeStep) {
      double maxInfusion = (testPump.density * testPump.maxPumpRate).toDouble();
      testPump.updatePumpInfusionSequence(at: i, pumpInfusion: maxInfusion);
    }
    // print('calibrate');
    // print(pump.pumpInfusionSequences);
    return test(testPump: testPump);
  }

  double get maxCalibratedEffect {
    List<double> result = calibrate.concentrationsEffect;
    return result.reduce(max);
  }

  ({
    List<double> A1s,
    List<double> A2s,
    List<double> A3s,
    List<double> concentrations,
    List<double> concentrationsEffect,
    List<double> pumpInfs,
    List<int> steps,
    List<Duration> times
  }) get peak {
    return test(initialA1: 10);
  }

  double get maxCe {
    List<double> ce = peak.concentrationsEffect;
    return ce.reduce(max);
  }

  ({
    List<double> A1s,
    List<double> A2s,
    List<double> A3s,
    List<double> concentrations,
    List<double> concentrationsEffect,
    List<double> pumpInfs,
    List<int> steps,
    List<Duration> times
  }) test({Pump? testPump, double? initialA1}) {
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

    return (
      steps: steps,
      times: times,
      pumpInfs: pumpInfs,
      A1s: A1s,
      A2s: A2s,
      A3s: A3s,
      concentrations: concentrations,
      concentrationsEffect: concentrationsEffect,
    );
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
    if (model.target == Target.EffectSite) {
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
    if (model.target == Target.EffectSite) {
      result = bolusInfusedBy * maxCe / pump.density;
    } else if (model.target == Target.Plasma) {
      result = (-15.693 +
              sqrt(pow(15.693, 2) +
                  4 * 0.2197 * bolusInfusedBy * 70 / patient.weight)) /
          (0.4394);
      result = result / 4 * pump.target;
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
    List<double> BISEstimates,
    List<double> infs,
    List<double> overshootTimes,
    List<double> pumpInfs,
    List<int> steps,
    List<double> target,
    List<Duration> times
  }) get estimate {
    // print('estimate');
    // Duration time = Duration.zero;
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

    double maxCalibratedEffect = this.maxCalibratedEffect;

    double timeStep = pump.timeStep.inMilliseconds /
        1000; // this is to allow time_step in milliseconds
    int operationDuration = pump.duration.inSeconds;
    double totalStep = operationDuration / timeStep;

    //find max Pump Infusion Rate
    double maxPumpInfusionRate =
        (pump.density * pump.maxPumpRate).toDouble(); // mg per hr

    // Calculate eBIS
    double baselineBIS = variables.baselineBIS;
    double ce50 = variables.ce50;
    List<double> BISEstimates = [];

    // print(ce50);

    for (int step = 0; step <= totalStep; step += 1) {
      Duration time = pump.timeStep * step;

      //find manual pump inf
      double? modifiedPumpInf = pump.pumpInfusionSequences?[time];

      //find manual target
      double? modifiedTarget = pump.targetSequences?[time];

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

      double target = step == 0 ? pump.target : modifiedTarget ?? targets.last;

      double overshootTime = (step == 0
          ? target / maxCalibratedEffect * 100 - 1
          : (target - targets.last > 0
              ? (target - targets.last) / maxCalibratedEffect * 100 - 1
              : overshootTimes.last - timeStep));

      double A1Change = step == 0
          ? 0
          : (A2 * k21 + A3 * k31 - A1s.last * (k10 + k12 + k13)) *
              timeStep /
              60;

      double? inf;
      double? pumpInf;
      double? A1;

      if (model.target == Target.EffectSite) {
        A1 = step == 0
            ? 0
            : (pumpInfs.last / 60) * timeStep / 60 + A1Change + A1s.last;

        inf = 3600 * (target * V1 - A1Change - A1) / timeStep;

        pumpInf = modifiedPumpInf ??
            ((concentrationEffect > target
                ? 0.0
                : (overshootTime > 0.0
                    ? maxPumpInfusionRate
                    : (inf < 0.0 ? 0.0 : inf))));
      } else {
        inf = step == 0
            ? 0
            : 3600 * (target * V1 - A1Change - A1s.last) / timeStep;

        pumpInf = modifiedPumpInf ??
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

      //Extend the loop, if there is a wakeUPCe
      if (step == totalStep.toInt() && pump.wakeUPCe != null) {
        if (pump.wakeUPCe! < concentrationEffect) {
          totalStep = totalStep + 1;
          if (target != 0) {
            pump.updateTargetSequences(at: time + pump.timeStep, target: 0);
            // print('target = 0');
          }
          // print(totalStep);
          // print(pump.wakeUPCe);
          // print(concentrationEffect);
        }
      }

      double cumulativeInfusedDosage = step == 0
          ? pumpInf * timeStep / 3600
          : cumulativeInfusedDosages.last + pumpInf * timeStep / 3600;

      double cumulativeInfusedVolume = cumulativeInfusedDosage / pump.density;

      double BISEstimate = concentrationEffect > ce50
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
      BISEstimates.add(BISEstimate);
      // time = time + pump.timeStep;
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
      BISEstimates: BISEstimates
    );
  }

  int get weightGuess {
    double guess = 0.0;

    // Updated as per PD-167
    if (patient.age < 14) {
      guess = patient.sex == Sex.Female
          ? (5.153 +
              1.212 * patient.weight -
              0.002884 * pow(patient.weight, 2) +
              7.205e-6 * pow(patient.weight, 3) +
              0.02533 * patient.height -
              0.001739 * patient.weight * patient.bmi -
              0.03442 * patient.age -
              0.004224 * patient.age * patient.weight)
          : (5.031 +
              1.081 * patient.weight -
              0.002597 * pow(patient.weight, 2) +
              6.607e-6 * pow(patient.weight, 3) +
              0.02911 * patient.height -
              0.001948 * patient.weight * patient.bmi -
              0.2673 * patient.age +
              0.0138 * pow(patient.age, 2) -
              0.002003 * patient.age * patient.weight);
    } else {
      guess = patient.sex == Sex.Female
          ? (17.5 +
              0.9912 * patient.weight -
              0.001305 * pow(patient.weight, 2) +
              1.528e-6 * pow(patient.weight, 3) +
              1.006e-4 * pow(patient.height, 2) -
              3.690e-4 * patient.weight * patient.bmi -
              0.2682 * patient.age +
              1.560e-3 * pow(patient.age, 2) -
              0.003543 * patient.age * patient.weight +
              2.322e-6 * patient.age * pow(patient.weight, 2) +
              0.001080 * patient.age * patient.bmi -
              0.07786 * patient.bmi)
          : (16.07 +
              0.9376 * patient.weight -
              0.001383 * pow(patient.weight, 2) +
              1.684e-6 * pow(patient.weight, 3) +
              1.292e-4 * pow(patient.height, 2) -
              3.801e-4 * patient.weight * patient.bmi -
              0.2617 * patient.age +
              1.614e-3 * pow(patient.age, 2) -
              0.003841 * patient.age * patient.weight +
              3.927e-6 * pow(patient.weight, 2) * patient.age +
              0.001340 * patient.age * patient.bmi -
              0.09995 * patient.bmi);
    }
    return guess.round();
  }

  int get bolusGuess {
    double guess = 0.0;

    if (patient.age < 14) {
      guess = patient.sex == Sex.Female
          ? (8.549 +
              3.755 * patient.weight -
              0.006237 * pow(patient.weight, 2) +
              1.88e-5 * pow(patient.weight, 3) +
              0.03835 * patient.height -
              0.003901 * patient.weight * patient.bmi -
              0.9089 * patient.age +
              0.03911 * pow(patient.age, 2) -
              0.03027 * patient.age * patient.weight +
              0.06972 * patient.bmi)
          : (10.93 +
              3.556 * patient.weight -
              0.006061 * pow(patient.weight, 2) +
              1.847e-5 * pow(patient.weight, 3) +
              0.05001 * patient.height -
              0.004215 * patient.weight * patient.bmi -
              1.504 * patient.age +
              0.07093 * pow(patient.age, 2) -
              0.02577 * patient.age * patient.weight +
              0.07899 * patient.bmi);
    } else {
      guess = patient.sex == Sex.Female
          ? (38.01 +
              3.096 * patient.weight -
              2.187e-3 * pow(patient.weight, 2) +
              4.676e-6 * pow(patient.weight, 3) -
              0.09256 * patient.height +
              4.097e-4 * pow(patient.height, 2) -
              7.581e-4 * patient.weight * patient.bmi -
              0.6293 * patient.age +
              0.005249 * pow(patient.age, 2) -
              0.01542 * patient.age * patient.weight -
              2.887e-5 * pow(patient.weight, 2) * patient.age +
              3.178e-7 * pow(patient.age, 2) * pow(patient.weight, 2) +
              0.002109 * patient.age * patient.bmi -
              0.1769 * patient.bmi)
          : (42.34 +
              2.947 * patient.weight -
              1.996e-3 * pow(patient.weight, 2) +
              4.323e-6 * pow(patient.weight, 3) -
              0.09979 * patient.height +
              4.667e-4 * pow(patient.height, 2) -
              8.554e-4 * patient.weight * patient.bmi -
              0.6839 * patient.age +
              0.005336 * pow(patient.age, 2) -
              0.01454 * patient.age * patient.weight -
              2.864e-5 * pow(patient.weight, 2) * patient.age +
              2.875e-7 * pow(patient.age, 2) * pow(patient.weight, 2) +
              0.002405 * patient.age * patient.bmi -
              0.2078 * patient.bmi);
    }
    return guess.round();
  }

  //This is not initial bolus, Engbert's algo doesn't require bolus to be calculated
  //This was designed for calculate hand push bolus, but may not be required any more
  double get bolus {
    if (model.target == Target.EffectSite) {
      return pump.target / maxCe * pump.density;
    } else if (model.target == Target.Plasma) {
      double V1 = variables.V1;
      return pump.target * V1;
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
        estimate.BISEstimates[i],
      ];
      data.add(row);
    }
    return data.map((row) => row.join(',')).join('\n');
  }

  @override
  String toString() {
    return '{model: $model, patient: $patient, pump: $pump}';
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
      'eBISEstimates':
          estimate.BISEstimates.map((item) => item.toString()).toList(),
    };
  }
}
