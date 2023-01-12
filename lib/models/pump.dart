import 'dart:collection';
import 'package:propofol_dreams_app/constants.dart';

class Pump {
  Duration timeStep;
  int density;
  int maxPumpRate;
  Map<Duration, double>? bolusSequence;
  SplayTreeMap<Duration, double>? pumpInfusionSequences;
  SplayTreeMap<Duration, double>? targetSequences;

  Pump(
      {required this.timeStep,
      required this.density,
      required this.maxPumpRate,
      this.bolusSequence,
      this.pumpInfusionSequences,
      this.targetSequences});

  void updatePumpInfusionSequence(
      {required Duration start,
      required Duration end,
      required double pumpInfusion}) {
    pumpInfusionSequences ??= SplayTreeMap<Duration, double>();
    for (Duration d = start; d <= end; d += timeStep) {
      pumpInfusionSequences?.update(d, (value) => pumpInfusion,
          ifAbsent: () => pumpInfusion);
    }
  }

  void updateTargetSequence({required Duration at, required double target}) {
    targetSequences ??= SplayTreeMap<Duration, double>();
    targetSequences?.update(at, (value) => target, ifAbsent: () => target);
  }

  // void updateBolusSequence_old({required double bolus}) {
  //   bolusSequence ??= <Duration, double>{};
  //   bolusSequence?.update(Duration.zero, (value) => bolus,
  //       ifAbsent: () => bolus);
  // }

  void updateBolusSequence({required double bolus}) {
    pumpInfusionSequences ??= SplayTreeMap<Duration, double>();

    double durationInDouble =
        bolus / (kMaxHumanlyPossiblePushRate / 3600 * density);
    double steps = durationInDouble / timeStep.inMilliseconds * 1000;

    for (int i = 0; i < steps; i++) {
      double bolus = steps - i >= 1
          ? kMaxHumanlyPossiblePushRate.toDouble() * density
          : kMaxHumanlyPossiblePushRate.toDouble() * density * (steps - i);

      pumpInfusionSequences?.update(
          Duration(milliseconds: timeStep.inMilliseconds * i),
          (value) => bolus,
          ifAbsent: () => bolus);
    }

  }

  bool get isManual {
    return bolusSequence != null ||
        pumpInfusionSequences != null ||
        targetSequences != null;
  }

  @override
  String toString() {
    String str =
        '{time step: ${timeStep.toString()}, density: $density, max pump rate: $maxPumpRate';

    //TODO add sequence in output
    if (bolusSequence != null) {
      str += ', bolus_sequence: ${bolusSequence![Duration.zero]}';
    }

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
