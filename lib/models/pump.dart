import 'dart:collection';

class Pump {
  Duration timeStep;
  int density;
  int maxPumpRate;
  double target;
  Duration duration;

  double? wakeUPCe;

  SplayTreeMap<Duration, double>? pumpInfusionSequences;
  SplayTreeMap<Duration, double>? targetSequences;

  Pump({required this.timeStep,
    required this.density,
    required this.maxPumpRate,
    required this.target,
    required this.duration,
    this.wakeUPCe,
    this.pumpInfusionSequences,
    this.targetSequences});

  Pump copy() {
    return Pump(
      timeStep: timeStep,
      density: density,
      maxPumpRate: maxPumpRate,
      target: target,
      duration: duration,
      wakeUPCe: wakeUPCe,
      pumpInfusionSequences: pumpInfusionSequences,
      targetSequences: targetSequences
    );
  }

  void updatePumpInfusionSequence({required Duration at,
    required double pumpInfusion}) {
    pumpInfusionSequences ??= SplayTreeMap<Duration, double>();
    pumpInfusionSequences?.update(at, (value) => pumpInfusion,
        ifAbsent: () => pumpInfusion);
  }

  void copyPumpInfusionSequences(
      {required List<Duration> times, required List<double> pumpInfs}) {
    for (int i = 0; i < times.length; i++) {
      updatePumpInfusionSequence(at: times[i], pumpInfusion: pumpInfs[i]);
    }
  }

  void updateTargetSequences({required Duration at, required double target}) {
    targetSequences ??= SplayTreeMap<Duration, double>();
    targetSequences?.update(at, (value) => target, ifAbsent: () => target);
  }

  Duration bolusInfusionDuration({required double bolus}) {
    double infusionInSecs = bolus / (maxPumpRate * density / 3600);
    double timeStepInSecs = timeStep.inMilliseconds / 1000;

    int infusionInTimeStep = (infusionInSecs / timeStepInSecs).floor();
    return Duration(
        milliseconds: timeStep.inMilliseconds * (infusionInTimeStep));
  }

  void infuseBolus({required Duration startsAt, required double bolus}) {
    Duration endAt = startsAt + bolusInfusionDuration(bolus: bolus) - timeStep;
    for (Duration i = startsAt; i <= endAt; i = i + timeStep) {
      updatePumpInfusionSequence(
          at: i, pumpInfusion: (maxPumpRate * density).toDouble());
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
        .toString()}, density: $density, max pump rate: $maxPumpRate, target: $target, duration: $duration';

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
