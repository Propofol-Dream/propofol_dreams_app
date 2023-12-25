import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';

import 'dart:io';
import 'dart:math';
import 'package:propofol_dreams_app/constants.dart';
import 'dart:collection';

void main() {
  Model model = Model.Eleveld;
  int weight = 87;
  int age = 62;
  int height = 183;
  Gender gender = Gender.Male;

  SplayTreeMap<Duration, double>? cumulativeInfusedDosageSequence;

  Duration timeStep = Duration(seconds: 1);
  int density = 10;
  int maxPumpRate = 12000;

  double baseTarget = 4;

  int findIndexOfNearValue({required List list, required var val}) {
    var diff = list.map((i) => (i - val).abs()).toList();
    var min = diff.reduce((current, next) => current < next ? current : next);
    int index = diff.indexOf(min);

    return index;
  }

  void updateCumulativeInfusedDosageSequence(
      {required Duration at, required double cumulativeInfusedDosage}) {
    cumulativeInfusedDosageSequence ??= SplayTreeMap<Duration, double>();
    cumulativeInfusedDosageSequence?.update(
        at, (value) => cumulativeInfusedDosage,
        ifAbsent: () => cumulativeInfusedDosage);
  }

  updateCumulativeInfusedDosageSequence(
      at: Duration(seconds: 762), cumulativeInfusedDosage: 285);
  updateCumulativeInfusedDosageSequence(
      at: Duration(seconds: 1338), cumulativeInfusedDosage: 380);
  updateCumulativeInfusedDosageSequence(
      at: Duration(seconds: 4691), cumulativeInfusedDosage: 784);
  updateCumulativeInfusedDosageSequence(
      at: Duration(seconds: 11407), cumulativeInfusedDosage: 1630);

  // updateCumulativeInfusedVolumeSequence(
  //     at: Duration(seconds: 10), cumulativeInfusedVolume: 100);
  // updateCumulativeInfusedVolumeSequence(
  //     at: Duration(seconds: 20), cumulativeInfusedVolume: 200);
  // updateCumulativeInfusedVolumeSequence(
  //     at: Duration(seconds: 30), cumulativeInfusedVolume: 400);
  // updateCumulativeInfusedVolumeSequence(
  //     at: Duration(seconds: 40), cumulativeInfusedVolume: 800);

  test('WakeUpTimer', () async {
    var firstDuration = cumulativeInfusedDosageSequence!.firstKey()!;
    var firstCumulativeInfusedDosage =
        cumulativeInfusedDosageSequence?[firstDuration]!;

    Patient patient =
        Patient(weight: weight, height: height, age: age, gender: gender);
    Pump pump =
        Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate);
    Operation operation = Operation(
        target: baseTarget,
        duration: firstDuration *
            2); //*2 this is for working out tRatio, if time takes longer for reaching the same volume;

    Simulation baseSimulation = Simulation(
        model: model, patient: patient, pump: pump, operation: operation);
    var baseEstimate = baseSimulation.estimate;

    // Calculate CE Target based on volume comparison:
    // Find the volume at the same timestamp;
    // Find the ratio between base volume and the user entered volume
    // Use the ratio to estimate user CE Target
    int dIndex = baseEstimate.times.indexOf(firstDuration);
    // print(baseSimulation);
    // print(firstDuration);
    // print(dIndex);
    // print(baseEstimate.cumulativeInfusedDosages.length);
    var dRatio = firstCumulativeInfusedDosage! /
        baseEstimate.cumulativeInfusedDosages[dIndex];
    var vCETarget = baseTarget * dRatio;

    // Calculate ratio based on time comparison:
    // Find the time with the same volume;
    // Find the ratio between base duration and user entered duration
    // User the ratio to estimate user CE Target
    int tIndex = findIndexOfNearValue(
        list: baseEstimate.cumulativeInfusedDosages,
        val: firstCumulativeInfusedDosage);
    var tRatio =
        baseEstimate.times[tIndex].inMilliseconds / firstDuration.inMilliseconds;
    var tCETarget = baseTarget * tRatio;
    // print("tRatio: $tRatio");
    // print("tCETarget: $tCETarget");

    var vCETargetRounded = (vCETarget * 100).roundToDouble() / 100;
    var tCETargetRounded = (tCETarget * 100).roundToDouble() / 100;

    List<Simulation> comparedSimulations = [];
    List<double> comparedCumulativeInfusedDosages = [];
    for (double i = min(vCETargetRounded, tCETargetRounded);
        i < max(vCETargetRounded, tCETargetRounded);
        i = i + 0.01) {
      // print(i);
      Operation comparedOperation = operation.copy();
      comparedOperation.target = i;
      comparedOperation.duration = firstDuration;

      Simulation comparedSimulation = baseSimulation.copy();
      comparedSimulation.operation = comparedOperation;

      comparedSimulations.add(comparedSimulation);
      comparedCumulativeInfusedDosages
          .add(comparedSimulation.estimate.cumulativeInfusedDosages.last);
    }

    var civIndex = findIndexOfNearValue(
        list: comparedCumulativeInfusedDosages,
        val: firstCumulativeInfusedDosage);
    var bestSimulation = comparedSimulations[civIndex];
    print(bestSimulation.estimate.times.last);
    print(bestSimulation.estimate.concentrationsEffect.last);
    print(bestSimulation.estimate.cumulativeInfusedDosages.last);
    print(bestSimulation);
    // print(comparedCumulativeInfusedVolumes);
    // print(cumulativeInfusedVolumes[0]);
    var bestEstimate = bestSimulation.estimate;

    Pump finalPump = pump.copy();
    finalPump.copyPumpInfusionSequences(
        times: bestEstimate.times, pumpInfs: bestEstimate.pumpInfs);
    // print(bestEstimate.times.last);

    var iterator = cumulativeInfusedDosageSequence?.entries.iterator;
    iterator!.moveNext();

    cumulativeInfusedDosageSequence?.entries
        .take(cumulativeInfusedDosageSequence!.length - 1)
        .forEach((entry) {
      print('Key: ${entry.key}, Value: ${entry.value}');
      iterator!.moveNext();
      var nextEntry = iterator.current;
      // print('Next Key: ${nextEntry?.key}, Next Value: ${nextEntry?.value}');
      var diffDuration = nextEntry.key - entry.key;
      var diffCIV = nextEntry.value - entry.value;
      // print(diffDuration);
      // print(diffCIV);

      var steps = diffDuration.inMilliseconds / pump.timeStep.inMilliseconds;
      for (Duration d = pump.timeStep;
          d <= diffDuration;
          d = d + pump.timeStep) {
        var at = entry.key + d;
        var pumpInfusion = diffCIV / steps;
        // print('Time at: $at, pumpInfusion = $pumpInfusion');
        finalPump.updatePumpInfusionSequence(
            at: at, pumpInfusion: pumpInfusion);
      }
    });
    Simulation finalSimulation = bestSimulation.copy();
    finalSimulation.pump = finalPump;
    var finalEstimate = finalSimulation.estimate;
    print(finalEstimate.concentrationsEffect.last);
    print(finalEstimate.times.last);
    print(finalSimulation);
    // finalSimulation.toCsv(map);

  });
}
