import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'package:propofol_dreams_app/models/WUTInput.dart.bk';

import 'dart:io';
import 'dart:math';
import 'dart:collection';

void main() {
  Model model = Model.Eleveld;
  int weight = 87;
  int age = 62;
  int height = 183;
  Gender gender = Gender.Male;

  // List<int> durationInSeconds = [
  //   762,
  //   1338,
  //   1808,
  //   3672,
  //   4691,
  //   8724,
  //   9427,
  //   11407,
  //   11513,
  //   11653,
  //   11741,
  //   11787,
  //   11846,
  //   11966
  // ];
  List<int> durationInSeconds = [762, 1338, 4691, 11407];

  List<Duration> durationInputs =
      durationInSeconds.map((sec) => Duration(seconds: sec)).toList();

  // List<double> dosageInputs = [
  //   285,
  //   380,
  //   442,
  //   664,
  //   784,
  //   1240,
  //   1360,
  //   1630,
  //   1630,
  //   1630,
  //   1630,
  //   1630,
  //   1630,
  //   1630
  // ];

  List<double> dosageInputs = [285, 380, 784, 1630];

  // List<double> eBISInputs = [
  //   41,
  //   45,
  //   41,
  //   45,
  //   43,
  //   59,
  //   52,
  //   53,
  //   47,
  //   54,
  //   68,
  //   66,
  //   73,
  //   97
  // ];

  List<double> eBISInputs = [41, 45, 43, 53];

  //TODO: Test & fix Duration(second: 5) or more
  Duration timeStep = const Duration(seconds: 1);
  int density = 10;
  int maxPumpRate = 1200; //mg/hr

  double baseTarget = 4;

  double ce50Fit = 0;
  double ce50ShiftFit = 0;

  int findIndexOfNearValue({required List list, required var val}) {
    var diff = list.map((i) => (i - val).abs()).toList();
    var min = diff.reduce((current, next) => current < next ? current : next);
    int index = diff.indexOf(min);

    return index;
  }

  // The records are automatically sorted by duration.
  SplayTreeSet<WUTInput> inputs = SplayTreeSet<WUTInput>();

  for (int i = 0; i < durationInputs.length; i++) {
    inputs.add(WUTInput(
        durationInput: durationInputs[i],
        dosageInput: dosageInputs[i],
        eBISInput: eBISInputs[i]));
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

    var firstDuration = durationInputs.first;
    var firstCumulativeInfusedDosage = dosageInputs.first;

    Patient patient =
        Patient(weight: weight, height: height, age: age, gender: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: baseTarget,
        duration: firstDuration *
            2); //firstDuration * 2 this is for working out tRatio, if time takes longer for reaching the same volume;

    Simulation baseSimulation = Simulation(
      model: model,
      patient: patient,
      pump: pump,
    );
    var baseEstimate = baseSimulation.estimate;

    const baseSimFileName = '/Users/eddy/Developer/base_sim.csv';
    await File(baseSimFileName).writeAsString(baseSimulation.toCsv());

    // Calculate CE Target based on dosage comparison:
    // Find the volume at the same timestamp;
    // Find the ratio between base volume and the user entered volume
    // Use the ratio to estimate user CE Target
    int dIndex = baseEstimate.times.indexOf(firstDuration);
    var dRatio = firstCumulativeInfusedDosage /
        baseEstimate.cumulativeInfusedDosages[dIndex];
    var dCETarget = baseTarget * dRatio;

    // print(dCETarget);
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
    // print(tCETarget);
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

    const bestSimFileName = '/Users/eddy/Developer/best_sim.csv';
    await File(bestSimFileName).writeAsString(bestSimulation.toCsv());
    // print(bestSimulation);

    Pump finalPump = pump.copy();

    finalPump.copyPumpInfusionSequences(
        times: bestEstimate.times, pumpInfs: bestEstimate.pumpInfs);

    // print(finalPump.pumpInfusionSequences);

    Simulation testSimulation = bestSimulation.copy();
    testSimulation.pump = finalPump.copy();
    const testSimFileName = '/Users/eddy/Developer/test_sim.csv';
    await File(testSimFileName).writeAsString(testSimulation.toCsv());

    // print(testSimulation.pump.pumpInfusionSequences);

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
        var pumpInfusion = diffDosage / steps * 3600;
        // print('Time at: $at, pumpInfusion = $pumpInfusion');
        finalPump.updatePumpInfusionSequence(
            at: at, pumpInfusion: pumpInfusion);
        // print('at: ${at}, pumpInfusion: ${pumpInfusion}');
      }
      // if(i==0) {
      //   print(i);
      //   print(diffDuration.inSeconds);
      //   print(diffDosage);
      //   var pumpinf = diffDosage/steps;
      //   print(steps);
      //   print(pumpinf);
      //   print(pump.timeStep);
      // }
    }

    Simulation finalSimulation = bestSimulation.copy();
    finalSimulation.pump = finalPump;
    finalSimulation.pump.duration = inputs.last.durationInput;

    var finalEstimate = finalSimulation.estimate;
    // // print(finalEstimate.concentrationsEffect.last);
    // // print(finalEstimate.times.last);
    // // print(finalSimulation);
    //
    const finalSimFileName = '/Users/eddy/Developer/final_sim.csv';
    await File(finalSimFileName).writeAsString(finalSimulation.toCsv());

    const bestSimFileName2 = '/Users/eddy/Developer/best2_sim.csv';
    await File(bestSimFileName2).writeAsString(bestSimulation.toCsv());

    for (var input in inputs) {
      int index = finalEstimate.times.indexOf(input.durationInput);
      input.concentrationEffect = finalEstimate.concentrationsEffect[index];
    }
    // StringBuffer csvInputsBuffer = StringBuffer();
    // // Adding header
    // csvInputsBuffer.writeln('duration, dosage, eBIS, concentrationEffect');
    //
    // // Adding each record
    // for (WUTInput input in inputs) {
    //   csvInputsBuffer.writeln(input.toCsv());
    // }
    //
    // const inputsFileName = '/Users/eddy/Documents/inputs.csv';
    // await File(inputsFileName).writeAsString(csvInputsBuffer.toString());

    //Step 2 calculate ce50Fit
    var variables = finalSimulation.variables;
    var baselineBIS = variables.baselineBIS;
    var baselineCe50 = variables.ce50;
    print('Eleveld Baseline Ce50: $baselineCe50');

    //Discard all the bis readings in the first 10 minutes (non-steady state)
    inputs.removeWhere(
        (input) => input.durationInput < const Duration(minutes: 10));

    // Count how many times the dosageInput of the last element occurs in the set
    int count = inputs
        .where((input) => input.dosageInput == inputs.last.dosageInput)
        .length;

    Duration totalDurationWeight = inputs.fold(Duration.zero,
        (Duration sum, WUTInput input) => sum + input.durationInput);

    // Check if it occurs more than once
    if (count > 1) {
      // Remove elements from the end based on the count
      for (int i = 0; i < count - 1; i++) {
        inputs.remove(inputs.last);
      }
    }

    if (inputs.isEmpty) {
      ce50Fit = baselineCe50;
      ce50ShiftFit = baselineCe50 / 10;
    } else {
      List<double> ce50s = [];
      List<double> ce50Shifts = [];
      List<double> sumOfWeightedSquaredDiffs = [];

      //Build ce50 List
      List<double> ce50Tests = [];
      for (double ce50 = (baselineCe50 / 2 * 100).round() / 100;
          ce50 <= (baselineCe50 * 2 * 100).round() / 100;
          ce50 += 0.05) {
        ce50Tests.add(ce50);
      }
      // print('ce50Tests');
      // print(ce50Tests);

      for (int n = 0; n < ce50Tests.length; n++) {
        var ce50Test = ce50Tests[n];

        List<double> weightedSquaredDiffs = [];

        List<double> ceShifts = [];
        for (double ceShift = (ce50Test * 0.1 * 100).round() / 100;
            ceShift <= (ce50Test * 100).round() / 100;
            ceShift += 0.05) {
          ceShifts.add(ceShift);
        }

        for (int m = 0; m < ceShifts.length; m++) {
          var ce50Shift = ceShifts[m];

          for (int i = 0; i < inputs.length; i++) {
            // double weightedSquaredDiff = 0;

            double adjustedBIS = 0;

            if (inputs.elementAt(i).concentrationEffect! - ce50Shift < 0) {
              adjustedBIS = baselineBIS;
            } else if (inputs.elementAt(i).concentrationEffect! - ce50Shift >
                ce50Test) {
              adjustedBIS = baselineBIS *
                  pow(ce50Test, 1.47) /
                  (pow(ce50Test, 1.47) +
                      pow(inputs.elementAt(i).concentrationEffect! - ce50Shift,
                          1.47));
            } else {
              adjustedBIS = baselineBIS *
                  pow(ce50Test, 1.89) /
                  (pow(ce50Test, 1.89) +
                      pow(inputs.elementAt(i).concentrationEffect! - ce50Shift,
                          1.89));
            }

            double weightedSquaredDiff =
                pow(adjustedBIS - inputs.elementAt(i).eBISInput, 2) *
                    (inputs.elementAt(i).durationInput.inMilliseconds /
                        totalDurationWeight.inMilliseconds);
            weightedSquaredDiffs.add(weightedSquaredDiff);

            // if (n == 0 && m == 0 && i == 0) {
            //   print(ce50Test);
            //   print(ce50Shift);
            //   print(adjustedBIS);
            //   print(inputs.elementAt(i).concentrationEffect);
            //   print(weightedSquaredDiff);
            //   print(inputs.elementAt(i).durationInput.inMilliseconds);
            //   print(totalDurationWeight.inMilliseconds);
            // }
          }

          ce50s.add(ce50Test);
          ce50Shifts.add(ce50Shift);
          double sumOfWeightedSquaredDiff =
              weightedSquaredDiffs.reduce((a, b) => a + b);
          sumOfWeightedSquaredDiffs.add(sumOfWeightedSquaredDiff);
        }
      }

      double minDiff =
          sumOfWeightedSquaredDiffs.reduce((a, b) => a < b ? a : b);
      int indexOfMinDiff = sumOfWeightedSquaredDiffs.indexOf(minDiff);
      ce50Fit = ce50s[indexOfMinDiff];
      ce50ShiftFit = ce50Shifts[indexOfMinDiff];

      const filename = '/Users/eddy/Developer/ce50Test.csv';
      await File(filename).writeAsString(toCsv(
          headers: ['ce50s', 'ce50Shifts', 'sumOfWeightedSquaredDiff'],
          contents: [ce50s, ce50Shifts, sumOfWeightedSquaredDiffs]));
    }
    print('ce50Fit: $ce50Fit');
    print('ce50ShiftFit: $ce50ShiftFit');

    List<double> predeBIS = [];

    for (int i = 0; i < inputs.length; i++) {
      if (inputs.elementAt(i).concentrationEffect! - ce50ShiftFit < 0) {
        predeBIS.add(baselineBIS);
      } else if (inputs.elementAt(i).concentrationEffect! - ce50ShiftFit >
          ce50Fit) {
        predeBIS.add(baselineBIS *
            pow(ce50Fit, 1.47) /
            (pow(ce50Fit, 1.47) +
                pow(inputs.elementAt(i).concentrationEffect! - ce50ShiftFit,
                    1.47)));
      } else {
        predeBIS.add(baselineBIS *
            pow(ce50Fit, 1.89) /
            (pow(ce50Fit, 1.89) +
                pow(inputs.elementAt(i).concentrationEffect! - ce50ShiftFit,
                    1.89)));
      }
    }

    List durations = inputs.map((input) => input.durationInput).toList();
    List dosages = inputs.map((input) => input.dosageInput).toList();
    List eBISs = inputs.map((input) => input.eBISInput).toList();

    const filename = '/Users/eddy/Developer/predeBIS.csv';
    await File(filename).writeAsString(toCsv(
        headers: ['duration', 'dosage', 'eBISInputs', 'predeBIS'],
        contents: [durations, dosages, eBISs, predeBIS]));


  });
}
