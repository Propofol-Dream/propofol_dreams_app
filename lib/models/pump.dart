import 'dart:collection';
import 'package:propofol_dreams_app/constants.dart';

class Pump {
  Duration time_step;
  int dilution;
  int max_pump_rate;
  Map<Duration, double>? bolusSequence;
  SplayTreeMap<Duration, double>? pumpInfusionSequences;
  SplayTreeMap<Duration, double>? depthSequences;

  Pump(
      {required this.time_step,
      required this.dilution,
      required this.max_pump_rate,
      this.bolusSequence,
      this.pumpInfusionSequences,
      this.depthSequences});

  void updatePumpInfusionSequence(
      {required Duration start,
      required Duration end,
      required double pumpInfusion}) {
    pumpInfusionSequences ??= SplayTreeMap<Duration, double>();
    for (Duration d = start; d <= end; d += time_step) {
      pumpInfusionSequences?.update(d, (value) => pumpInfusion,
          ifAbsent: () => pumpInfusion);
    }
  }

  void updateDepthSequence({required Duration at, required double depth}) {
    depthSequences ??= SplayTreeMap<Duration, double>();
    depthSequences?.update(at, (value) => depth, ifAbsent: () => depth);
  }

  void updateBolusSequence({required double bolus}) {
    bolusSequence ??= <Duration, double>{};
    bolusSequence?.update(Duration.zero, (value) => bolus,
        ifAbsent: () => bolus);
  }

  void updateBolusSequence_new({required double bolus}) {
    bolusSequence ??= <Duration, double>{};

    double durationInDouble =
        bolus / (kMaxHumanlyPossiblePushRate / 3600 * dilution);
    double steps = durationInDouble / time_step.inMilliseconds * 1000;

    for (int i = 0; i < steps; i++) {
      double bolus = steps - i >= 1
          ? kMaxHumanlyPossiblePushRate.toDouble() * dilution
          : kMaxHumanlyPossiblePushRate.toDouble() * dilution * (steps - i);

      bolusSequence?.update(
          Duration(milliseconds: time_step.inMilliseconds * i),
          (value) => bolus,
          ifAbsent: () => bolus);
    }
    print(bolusSequence);
  }

  bool get isManual {
    return bolusSequence != null ||
        pumpInfusionSequences != null ||
        depthSequences != null;
  }

  String toString() {
    String str =
        '{time step: ${time_step.toString()}, dilution: $dilution, max pump rate: $max_pump_rate';

    //TODO add sequence in output
    if (bolusSequence != null) {
      str += ', bolus_sequence: ${bolusSequence![Duration.zero]}';
    }

    if (pumpInfusionSequences != null) {
      str += ', pump_infusion_sequences: under development';
    }

    if (depthSequences != null) {
      str += ', depth_sequences: under development';
    }

    str = str + '}';

    return str;
  }
}
