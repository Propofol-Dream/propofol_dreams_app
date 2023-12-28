import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:propofol_dreams_app/models/WUTInput.dart';

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

  List<int> durationInSeconds = [
    762,
    1338,
    1808,
    3672,
    4691,
    8724,
    9427,
    11407,
    11513,
    11653,
    11741,
    11787,
    11846,
    11966
  ];
  List<Duration> durationInputs =
      durationInSeconds.map((sec) => Duration(seconds: sec)).toList();

  List<double> dosageInputs = [
    285,
    380,
    442,
    664,
    784,
    1240,
    1360,
    1630,
    1630,
    1630,
    1630,
    1630,
    1630,
    1630
  ];

  List<double> eBISInputs = [
    41,
    45,
    41,
    45,
    43,
    59,
    52,
    53,
    47,
    54,
    68,
    66,
    73,
    97
  ];

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

  // The records are automatically sorted by duration.
  SplayTreeSet<WUTInput> inputs = SplayTreeSet<WUTInput>();

  double totalWeight = 0;

  for (int i = 0; i < durationInputs.length; i++) {
    inputs.add(WUTInput(
        durationInput: durationInputs[i],
        dosageInput: dosageInputs[i],
        eBISInput: eBISInputs[i]));
    totalWeight += durationInputs[i].inSeconds;
  }


  String toCsv(
      {required List<String> headers, required List<List<dynamic>> contents}) {

    List<List<dynamic>> data = [headers];

    // Assuming all lists are of the same length
    for (int i = 0; i < contents[0].length; i++) {
      List<dynamic> row = [];
      for (int j = 0; j < contents.length; j++) {
        row.add(contents[j][i]);
      }
      data.add(row);
    }
    return data.map((row) => row.join(',')).join('\n');
  }

  test('WakeUpTimer', () async {
    // print('total weight: $totalWeight');
    //TODO check whether the entry has first key value
    var firstDuration = durationInputs.first;
    var firstCumulativeInfusedDosage = dosageInputs.first;

    Patient patient =
        Patient(weight: weight, height: height, age: age, gender: gender);
    Pump pump =
        Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate,target: baseTarget,
            duration: firstDuration *
                2); //firstDuration * 2 this is for working out tRatio, if time takes longer for reaching the same volume;

    Simulation baseSimulation = Simulation(
        model: model, patient: patient, pump: pump,);
    var baseEstimate = baseSimulation.estimate;

    // Calculate CE Target based on volume comparison:
    // Find the volume at the same timestamp;
    // Find the ratio between base volume and the user entered volume
    // Use the ratio to estimate user CE Target
    int dIndex = baseEstimate.times.indexOf(firstDuration);
    var dRatio = firstCumulativeInfusedDosage /
        baseEstimate.cumulativeInfusedDosages[dIndex];
    var dCETarget = baseTarget * dRatio;

    // Calculate ratio based on time comparison:
    // Find the time with the same volume;
    // Find the ratio between base duration and user entered duration
    // User the ratio to estimate user CE Target
    int tIndex = findIndexOfNearValue(
        list: baseEstimate.cumulativeInfusedDosages,
        val: firstCumulativeInfusedDosage);
    var tRatio = baseEstimate.times[tIndex].inMilliseconds /
        firstDuration.inMilliseconds;
    var tCETarget = baseTarget * tRatio;

    var dCETargetRounded = (dCETarget * 100).roundToDouble() / 100;
    var tCETargetRounded = (tCETarget * 100).roundToDouble() / 100;

    List<Simulation> comparedSimulations = [];
    List<double> comparedCumulativeInfusedDosages = [];

    for (double i = min(dCETargetRounded, tCETargetRounded);
        i < max(dCETargetRounded, tCETargetRounded);
        i = i + 0.01) {
      // print(i);
      // Operation comparedOperation = operation.copy();
      Pump comparedPump = pump.copy();
      comparedPump.target = i;
      comparedPump.duration = firstDuration;

      Simulation comparedSimulation = baseSimulation.copy();
      comparedSimulation.pump = comparedPump;

      comparedSimulations.add(comparedSimulation);
      comparedCumulativeInfusedDosages
          .add(comparedSimulation.estimate.cumulativeInfusedDosages.last);
    }

    var cidIndex = findIndexOfNearValue(
        list: comparedCumulativeInfusedDosages,
        val: firstCumulativeInfusedDosage);
    var bestSimulation = comparedSimulations[cidIndex];

    // print(bestSimulation.estimate.times.last);
    // print(bestSimulation.estimate.concentrationsEffect.last);
    // print(bestSimulation.estimate.cumulativeInfusedDosages.last);
    // print(bestSimulation);
    // print(comparedCumulativeInfusedVolumes);
    // print(cumulativeInfusedVolumes[0]);
    var bestEstimate = bestSimulation.estimate;

    Pump finalPump = pump.copy();
    finalPump.copyPumpInfusionSequences(
        times: bestEstimate.times, pumpInfs: bestEstimate.pumpInfs);
    // print(bestEstimate.times.last);

    for (int i = 0; i < inputs.length - 1; i++) {
      var diffDuration = inputs.elementAt(i + 1).durationInput -
          inputs.elementAt(i).durationInput;
      var diffDosage =
          inputs.elementAt(i + 1).dosageInput - inputs.elementAt(i).dosageInput;

      var steps = diffDuration.inMilliseconds / pump.timeStep.inMilliseconds;
      for (Duration d = pump.timeStep;
          d <= diffDuration;
          d = d + pump.timeStep) {
        var at = inputs.elementAt(i).durationInput + d;
        var pumpInfusion = diffDosage / steps;
        print('Time at: $at, pumpInfusion = $pumpInfusion');
        finalPump.updatePumpInfusionSequence(
            at: at, pumpInfusion: pumpInfusion);
      }
    }

    Simulation finalSimulation = bestSimulation.copy();
    finalSimulation.pump = finalPump;
    finalSimulation.pump.duration = inputs.last.durationInput;

    var finalEstimate = finalSimulation.estimate;
    // print(finalEstimate.concentrationsEffect.last);
    // print(finalEstimate.times.last);
    // print(finalSimulation);

    const finalSimFileName = '/Users/eddy/Documents/final_sim.csv';
    await File(finalSimFileName).writeAsString(finalSimulation.toCsv());

    for (var input in inputs) {
      int index = finalEstimate.times.indexOf(input.durationInput);
      var concentrationEffect = finalEstimate.concentrationsEffect[index];
      input.concentrationEffect = concentrationEffect;
    }

    // print(inputs.toList());

    // StringBuffer csvInputsBuffer = StringBuffer();
    // // Adding header
    // csvInputsBuffer.writeln('duration, dosage, eBIS, concentrationEffect');
    //
    // // Adding each record
    // for (WUTInput input in inputs) {
    //   csvInputsBuffer.writeln(input.toCsv());
    // }



    const inputsFileName = '/Users/eddy/Documents/inputs.csv';
    // await File(inputsFileName).writeAsString(csvInputsBuffer.toString());


    //Build ce50 List

    var variables = finalSimulation.variables;
    var baselineBIS = variables.baselineBIS;
    var ce50 = variables.ce50;

    List<double> ce50Tests = [];
    for (double c = ce50 / 2; c <= ce50 * 2; c += 0.2) {
      ce50Tests.add(c);
    }
    List<double> sumOfWeightedSquaredDiffs = [];

    for (int n = 0; n < ce50Tests.length; n++) {
      var ce50Test = ce50Tests[n];
      List<double> weightedSquaredDiffs = [];

      for (int i = 0; i < inputs.length; i++) {
        double exponent =
            inputs.elementAt(i).concentrationEffect! > ce50Test ? 1.47 : 1.89;

        double adjustedBIS = baselineBIS *
            pow(ce50Test, exponent) /
            (pow(ce50Test, exponent) +
                pow(inputs.elementAt(i).concentrationEffect!, exponent));

        double weightedSquaredDiff =
            pow((adjustedBIS - inputs.elementAt(i).eBISInput), 2) *
                inputs.elementAt(i).durationInput.inSeconds /
                totalWeight;
        weightedSquaredDiffs.add(weightedSquaredDiff);
      }
      double sumOfWeightedSquaredDiff =
          weightedSquaredDiffs.reduce((a, b) => a + b);
      sumOfWeightedSquaredDiffs.add(sumOfWeightedSquaredDiff);
    }

    final filename = '/Users/eddy/Documents/ce50Test.csv';
    await File(filename).writeAsString(toCsv(
        headers: ['ce50Tests', 'sumOfWeightedSquaredDiff'],
        contents: [ce50Tests, sumOfWeightedSquaredDiffs]));
  });
}
