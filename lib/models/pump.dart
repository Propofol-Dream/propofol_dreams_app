import 'dart:collection';
import 'drug.dart';

class Pump {
  Duration timeStep; //aka refresh rate
  double concentration; // Renamed from density
  int maxPumpRate;
  double target;
  Duration duration;
  Drug? drug; // Add drug property

  double? wakeUPCe;

  SplayTreeMap<Duration, double>? pumpInfusionSequences;
  SplayTreeMap<Duration, double>? targetSequences;

  Pump({required this.timeStep,
    required this.concentration, // Renamed from density
    required this.maxPumpRate,
    required this.target,
    required this.duration,
    this.drug, // Add drug parameter
    this.wakeUPCe,
    this.pumpInfusionSequences,
    this.targetSequences});

  Pump copy() {
    return Pump(
        timeStep: timeStep,
        concentration: concentration,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration,
        drug: drug,
        wakeUPCe: wakeUPCe,
        pumpInfusionSequences: SplayTreeMap<Duration, double>.from(
            pumpInfusionSequences ?? {}),
        targetSequences: SplayTreeMap<Duration, double>.from(
            targetSequences ?? {}));
  }


  void updatePumpInfusionSequence({required Duration at,
    required double pumpInfusion}) {
    pumpInfusionSequences ??= SplayTreeMap<Duration, double>();
    pumpInfusionSequences?.update(at, (value) => pumpInfusion,
        ifAbsent: () => pumpInfusion);
    // print('time: ${at}, pumpInfs: ${pumpInfusion}');
    // print('updated');
  }

  void copyPumpInfusionSequences(
      {required List<Duration> times, required List<double> pumpInfs}) {
    for (int i = 0; i < times.length; i++) {
      updatePumpInfusionSequence(at: times[i], pumpInfusion: pumpInfs[i]);
      // print('copycopycopycopycopy');
    }
  }

  void updateTargetSequences({required Duration at, required double target}) {
    targetSequences ??= SplayTreeMap<Duration, double>();
    targetSequences?.update(at, (value) => target, ifAbsent: () => target);
  }

  Duration bolusInfusionDuration({required double bolus}) {
    double infusionInSecs = bolus / (maxPumpRate * concentration / 3600);
    double timeStepInSecs = timeStep.inMilliseconds / 1000;

    int infusionInTimeStep = (infusionInSecs / timeStepInSecs).floor();
    return Duration(
        milliseconds: timeStep.inMilliseconds * (infusionInTimeStep));
  }

  void infuseBolus({required Duration startsAt, required double bolus}) {
    Duration endAt = startsAt + bolusInfusionDuration(bolus: bolus) - timeStep;
    for (Duration i = startsAt; i <= endAt; i = i + timeStep) {
      updatePumpInfusionSequence(
          at: i, pumpInfusion: (maxPumpRate * concentration).toDouble());
    }
  }

  //TODO to be deprecated
  // bool get isManual {
  //   return pumpInfusionSequences != null || targetSequences != null;
  // }

  @override
  String toString() {
    String str =
        '{time step: ${timeStep
        .toString()}, concentration: $concentration, max pump rate: $maxPumpRate, target: $target, duration: $duration';

    if (drug != null) {
      str += ', drug: ${drug?.displayName}';
    }

    //TODO add sequence in output
    if (pumpInfusionSequences != null) {
      str += ', pump_infusion_sequences: under development';
    }

    if (targetSequences != null) {
      str += ', target_sequences: under development';
    }

    str = '$str}';
    return str;
  }
}
