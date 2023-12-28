import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';

void main() {
  test('Adjustment', () async {


    int weight = 80;
    int age = 40;
    int height = 170;
    Gender gender = Gender.Male;
    Duration timeStep = Duration(seconds: 1);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 4;
    Duration duration = Duration(minutes: 180);

    int weightBound = 0; // 0 = No brute force
    double bolusBound = 0.0; // 0.0 = No brute force

    // Set up lists of results
    List<int> weightGuesses = [];
    List<int> bolusGuesses = [];
    List<double> SSEs = [];
    List<double> MdPEs = [];
    List<double> MdAPEs = [];
    List<double> maxPEs = [];
    int weightBestGuess = -1;
    int bolusBestGuess = -1;

    // Set up for baseline model
    Model baselineModel = Model.Eleveld;
    Patient baselinePatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump baselinePump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate, target: target, duration: duration);
    // Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation baselineSim = Simulation(
        model: baselineModel, patient: baselinePatient, pump: baselinePump);
    int minWeightGuess = (baselineSim.weightGuess - weightBound).toInt();
    int maxWeightGuess = (baselineSim.weightGuess + weightBound).toInt();
    int minBolusGuess = (baselineSim.bolusGuess * (1 - bolusBound)).toInt();
    int maxBolusGuess = (baselineSim.bolusGuess * (1 + bolusBound)).toInt();

    print("weight bounds: $minWeightGuess - $maxWeightGuess");
    print("bolus bounds: $minBolusGuess - $maxBolusGuess");

    for (int weightGuess = minWeightGuess; weightGuess <= maxWeightGuess; weightGuess++){

      for (int bolusGuess = minBolusGuess; bolusGuess <= maxBolusGuess; bolusGuess++){
        // Set up for compared model
        Model comparedModel = Model.Marsh;
        Patient comparedPatient = baselinePatient.copy();
        comparedPatient.weight = weightGuess;
        // Patient comparedPatient = Patient(weight: weightGuess, age: age, height: height, gender: gender);
        // Infuse the bolus via the pump
        Pump comparedPump = baselinePump.copy();
        comparedPump.infuseBolus(startsAt: Duration.zero, bolus: bolusGuess.toDouble());
        Simulation comparedSim = Simulation(
            model: comparedModel, patient: comparedPatient, pump: comparedPump);

        var comparedEstimate = comparedSim.estimate;
        List<Duration> times = comparedEstimate.times;
        List<double> pumpInfs = comparedEstimate.pumpInfs;

        // Set up for final model
        Pump finalPump = baselinePump.copy();
        finalPump.copyPumpInfusionSequences(times: times, pumpInfs: pumpInfs);
        Simulation finalSim = Simulation(model: baselineModel, patient: baselinePatient, pump: finalPump);

        var baselineEstimate = baselineSim.estimate;
        var finalEstimate = finalSim.estimate;

        //Extract CEs and CPs from the three models
        List<double> baselineCEs = baselineEstimate.concentrationsEffect;
        List<double> finalCEs = finalEstimate.concentrationsEffect;

        List<double> CEPErrors = [];
        List<double> CEPercentageErrors = [];
        List<double> CEAbsolutePercentageErrors = [];

        for (int i = 0; i < finalCEs.length; i++) {
          double error = finalCEs[i] - baselineCEs[i];
          CEPErrors.add(error);
          CEPercentageErrors.add(error/baselineCEs[i]);
          CEAbsolutePercentageErrors.add(error.abs()/baselineCEs[i]);
        }

        double SSE = CEPErrors.reduce((value, element) => value + element * element);
        double MdPE = calculateMedian(CEPercentageErrors);
        double MdAPE = calculateMedian(CEAbsolutePercentageErrors);
        double maxPE = CEAbsolutePercentageErrors.where((element) => !element.isNaN).reduce(max);

        weightGuesses.add(weightGuess);
        bolusGuesses.add(bolusGuess);
        SSEs.add(SSE);
        MdPEs.add(MdPE);
        MdAPEs.add(MdAPE);
        maxPEs.add(maxPE);
      }
    }

    List<int> minIndices = findMinIndices(SSEs);

    if(minIndices.length > 1){
      List<double> filteredMaxPEs = [];
      for (int i = 0; i < minIndices.length; i++){
        filteredMaxPEs.add(maxPEs[minIndices[i]]);
      }
      int filteredMinIndex = findMinIndices(filteredMaxPEs).first;
      weightBestGuess = weightGuesses[minIndices[filteredMinIndex]];
      bolusBestGuess = bolusGuesses[minIndices[filteredMinIndex]];
    }
    else{
      weightBestGuess = weightGuesses[minIndices.first];
      bolusBestGuess = bolusGuesses[minIndices.first];
    }

    print("combination: ${SSEs.length}");
    print("weightBestGuess: $weightBestGuess");
    print("bolusBestGuess: $bolusBestGuess");

    // final filename = '/Users/eddy/Documents/output.csv';
    // var file = await File(filename).writeAsString(finalSim.toCsv(finalSim.estimate));

  });
}

double calculateMedian(List<double> numbers) {
  // Sort the list in ascending order
  numbers.sort();

  int length = numbers.length;

  if (length % 2 == 1) {
    // For odd-length list, return the middle element
    return numbers[length ~/ 2];
  } else {
    // For even-length list, return the average of the two middle elements
    double middle1 = numbers[length ~/ 2 - 1];
    double middle2 = numbers[length ~/ 2];
    return (middle1 + middle2) / 2;
  }
}

List<int> findMinIndices(List<double> numbers) {
  List<int> minIndices = [];
  double minValue = numbers.where((element) => !element.isNaN).reduce(min);
  for (int i = 0; i < numbers.length; i++) {
    if (numbers[i] == minValue) {
      minIndices.add(i);
    }
  }
  return minIndices;
}



