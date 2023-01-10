import 'dart:collection';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:propofol_dreams_app/models/target.dart';

import 'model.dart';
import 'simulation.dart';
import 'pump.dart';
import 'operation.dart';
import 'patient.dart';
import 'package:propofol_dreams_app/constants.dart';

class Trial {
  Simulation simulation;

  Trial({required this.simulation});

  Pump manualPump(
      {Map<Duration, double>? bolusSequence,
      SplayTreeMap<Duration, double>? pumpInfusionSequences,
      SplayTreeMap<Duration, double>? depthSequences}) {
    return Pump(
        time_step: simulation.pump.time_step,
        dilution: simulation.pump.dilution,
        max_pump_rate: kMaxHumanlyPossiblePushRate,
        bolusSequence: bolusSequence,
        pumpInfusionSequences: pumpInfusionSequences,
        depthSequences: depthSequences);
  }

  Map<String, dynamic> estimate(
      {Pump? manualPump, required Duration duration}) {
    Operation trialOperation =
        Operation(depth: simulation.operation.depth, duration: duration);

    Simulation trialSimulation = Simulation(
        model: simulation.model,
        patient: simulation.patient,
        pump: manualPump ?? simulation.pump,
        operation: trialOperation);

    return trialSimulation.estimate;
  }

  Map<String, dynamic> get baseline {
    return estimate(duration: Duration(minutes: 600));
  }

  Map<String, dynamic> get forecast_bolus {
    return estimate(duration: Duration(seconds: 200));
  }

  //bolus is in mg not mcg nor mL
  double get bolusVolumes {
    // DateTime start = DateTime.now();
    // int i = forecast_bolus['pump_infs'].indexWhere((element) => element == 0);
    // double b = forecast_bolus['cumulative_infused_volumes'][i];
    double b = findMostCommon(forecast_bolus['cumulative_infused_volumes']);
    // DateTime end = DateTime.now();
    // Duration  d = end.difference(start);
    // print(d);
    return b;

    // return findMostCommon(forecast_bolus['cumulative_infused_volumes']);
  }

  double get bolus {
    return bolusVolumes * simulation.pump.dilution;
  }

  Duration get bolusExpiresTime {
    List vol = forecast_bolus['cumulative_infused_volumes'];
    int index = vol.lastIndexOf(bolusVolumes);
    Duration d = forecast_bolus['times'][index];
    return d;
    // return Duration.zero;
  }

  List<double> proposeInjection(
      {required double injection, required int interval, int last = 0}) {
    List<double> amounts = [];
    for (double amount = 0; amount < injection + interval; amount += interval) {
      amounts.add(amount);
    }
    if (last == 0) {
      return amounts;
    } else if (last <= amounts.length) {
      return (amounts.skip(amounts.length - last).take(last)).toList();
    } else {
      return [];
    }
  }

  double findCumulativeInfusedVolumes({required Duration duration}) {
    // List times = baseline['times'];
    // int index = times.indexWhere((element) => element == duration);
    //
    // if (index < 0 || index > times.length - 1) {
    //   return -1;
    // } else {
    //   return baseline['cumulative_infused_volumes'][index];
    // }
    return estimate(duration: duration)['cumulative_infused_volumes'].last;
  }

  //pump infusion is in mg/hr
  double findPumpInfusion({required Duration duration}) {
    return findCumulativeInfusedVolumes(duration: duration) *
        simulation.pump.dilution;
  }

  Map<String, double> proposePumpInfusion(
      {double? proposedBolus, required Duration start, required Duration end}) {
    double startInfusion = 0;
    double endInfusion = 0;

    start == Duration.zero
        ? startInfusion = 0
        : startInfusion = findPumpInfusion(duration: start);

    end == (Duration.zero)
        ? endInfusion = 0
        : endInfusion = findPumpInfusion(duration: end);

    double duration = (end - start).inMilliseconds / 1000;

    double pumpInfusion = (endInfusion - startInfusion - (proposedBolus ?? 0)) /
        duration *
        simulation.pump.time_step.inSeconds *
        3600;

    Map<String, double> result = {
      'start': startInfusion,
      'end': endInfusion,
      'pump_infusion': pumpInfusion,
      'duration': duration
    };

    if (proposedBolus != null) {
      result['proposed_bolus'] = proposedBolus;
    }
    return result;

    // start <= bolusExpiresTime
    //     ? startInfusion = 0
    //     : startInfusion = findPumpInfusion(duration: start);
    // end == (Duration.zero) || end > Duration(minutes: 600)
    //     ? endInfusion = 0
    //     : endInfusion = findPumpInfusion(duration: end);
    //
    // double trueBolus = start <= bolusExpiresTime ? bolus : 0;
    //
    // return {'start': startInfusion, 'bolus': trueBolus, 'end': endInfusion};
  }

  List<Map<String, dynamic>> propose(
      {required Duration start, required Duration end}) {
    //if start is earlier than bolusExpiresTime, then get a list of proposed bolus

    List<Map<String, dynamic>> results = [];
    Map<String, dynamic> baseline = estimateChunk(start: start, end: end);

    if (start == Duration.zero) {
      List<double> proposedBolus =
          proposeInjection(injection: bolus, interval: 10, last: 3);
      for (int i = 0; i < proposedBolus.length; i++) {
        double? proposedPumpInfusion = proposePumpInfusion(
            proposedBolus: proposedBolus[i],
            start: start,
            end: end)['pump_infusion'];
        if (proposedPumpInfusion != null) {
          List<double> proposedPumpInfusions = proposeInjection(
              injection: proposedPumpInfusion, interval: 10, last: 3);

          for (int j = 0; j < proposedPumpInfusions.length; j++) {
            Pump p = manualPump();
            p.updateBolusSequence(bolus: proposedBolus[i]);
            p.updatePumpInfusionSequence(
                start: start, end: end, pumpInfusion: proposedPumpInfusions[j]);
            Map<String, dynamic> proposed =
                estimate(manualPump: p, duration: end);

            Map<String, dynamic> result = {
              'bolus': proposedBolus[i],
              'pump_infusion': proposedPumpInfusions[j]
            };
            result.addAll(compare(baseline: baseline, proposed: proposed));

            results.add(result);
          }
        }
      }
    } else {
      double? proposedPumpInfusion =
          proposePumpInfusion(start: start, end: end)['pump_infusion'];

      if (proposedPumpInfusion != null) {
        List<double> proposedPumpInfusions = proposeInjection(
            injection: proposedPumpInfusion, interval: 10, last: 3);
        for (int j = 0; j < proposedPumpInfusions.length; j++) {
          Pump p = manualPump();
          p.updatePumpInfusionSequence(
              start: start, end: end, pumpInfusion: proposedPumpInfusions[j]);
          Map<String, dynamic> proposed = estimateChunk(
              alternativeEstimate: estimate(manualPump: p, duration: end),
              start: start,
              end: end);

          Map<String, dynamic> result = {
            'pump_infusion': proposedPumpInfusions[j]
          };
          result.addAll(compare(baseline: baseline, proposed: proposed));
          results.add(result);
        }
      }
    }

    return results;
  }

  Map<String, double> compare({required Map baseline, required Map proposed}) {
    //check whether the model is Plasma or Effect Site
    //pick concentration or concentration_effect from both baseline and proposed
    //calculate deviations[] and squared deviations[]
    //return AUC of squared deviations and max positive deivation and min negative deviation
    List<double> deviations = [];
    List<double> squared_deviations = [];

    List tmpBaseline = [];
    List tmpProposed = [];

    if (simulation.model.target == Target.Effect_Site) {
      tmpBaseline = baseline['concentrations_effect'];
      tmpProposed = proposed['concentrations_effect'];
    } else {
      tmpBaseline = baseline['concentrations'];
      tmpProposed = proposed['concentrations'];
    }

    for (int i = 0; i < tmpBaseline.length - 1; i++) {
      double deviation = (tmpProposed[i] - tmpBaseline[i]) *
          simulation.pump.time_step.inMilliseconds /
          1000;
      deviations.add(deviation);
      double squared_deviation = pow(deviation, 2) as double;
      squared_deviations.add(squared_deviation);
    }

    //TODO: work out the Durations inMilliseconds / 1000
    List<Duration> times = baseline['times'];
    Duration start = times.reduce((a, b) => a < b ? a : b);
    Duration end = times.reduce((a, b) => a > b ? a : b);

    double AUC =
        (squared_deviations.reduce((value, element) => value + element) /
            (end - start).inMilliseconds *
            1000);
    double lowest_deviation = (deviations.reduce(min));
    double highest_deviation = (deviations.reduce(max));

    return {
      'AUC': AUC,
      'max pos dev': highest_deviation,
      'max neg dev': lowest_deviation
    };
  }

  Map<String, dynamic> estimateChunk(
      {Map<String, dynamic>? alternativeEstimate,
      required Duration start,
      required Duration end}) {
    var estimates = alternativeEstimate ?? estimate(duration: end);

    List<Duration> times = estimates['times'];
    int i = times.indexOf(start);

    estimates.values.forEach((v) {
      List value = v;
      value.removeRange(0, i);
    });

    return estimates;
  }

  double findMostCommon(List list) {
    var map = {};
    list.forEach((x) => map[x] = !map.containsKey(x) ? (1) : (map[x] + 1));
    var sorted = map.values.toList()..sort();
    var mostCount = sorted.last;
    var key = map.keys.firstWhere((k) => map[k] == mostCount);
    return key;
  }
}
