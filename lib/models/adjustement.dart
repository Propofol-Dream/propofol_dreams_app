import 'dart:math';

import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';

class Adjustment {
  Simulation baselineSimulation;
  int weightBound;
  double bolusBound;

  Adjustment(
      {required this.baselineSimulation,
      required this.weightBound,
      required this.bolusBound});

  ({
    int weightBestGuess,
    int bolusBestGuess,
    int length,
    List<int> weightGuesses,
    List<int> bolusGuesses,
    List<double> SSEs,
    List<double> MdPEs,
    List<double> MdAPEs,
    List<double> maxPEs
  }) calculate() {
    // Set up results
    List<int> weightGuesses = [];
    List<int> bolusGuesses = [];
    List<double> SSEs = [];
    List<double> MdPEs = [];
    List<double> MdAPEs = [];
    List<double> maxPEs = [];
    int weightBestGuess = -1;
    int bolusBestGuess = -1;

    // Set up for baseline model
    int minWeightGuess =
        (baselineSimulation.patient.weightGuess - weightBound).toInt();
    int maxWeightGuess =
        (baselineSimulation.patient.weightGuess + weightBound).toInt();
    int minBolusGuess =
        (baselineSimulation.bolusGuess * (1 - bolusBound)).toInt();
    int maxBolusGuess =
        (baselineSimulation.bolusGuess * (1 + bolusBound)).toInt();

    for (int weightGuess = minWeightGuess;
        weightGuess <= maxWeightGuess;
        weightGuess++) {
      for (int bolusGuess = minBolusGuess;
          bolusGuess <= maxBolusGuess;
          bolusGuess++) {
        // Set up for compared model
        Model comparedModel = Model.Marsh;
        Patient comparedPatient = baselineSimulation.patient.copy();
        comparedPatient.weight = weightGuess;
        Pump comparedPump = baselineSimulation.pump.copy();
        comparedPump.infuseBolus(
            startsAt: Duration.zero,
            bolus: bolusGuess.toDouble()); // Infuse the bolusGuess via the pump
        Simulation comparedSimulation = Simulation(
            model: comparedModel,
            patient: comparedPatient,
            pump: comparedPump,
            operation: baselineSimulation.operation);

        // Get the pump_infs sequence out from the compared model
        Map<String, List> comparedEstimate = comparedSimulation.estimate;
        List<Duration> times = comparedEstimate['times'] as List<Duration>;
        List<double> pumpInfs = comparedEstimate['pump_infs'] as List<double>;

        // Set up for final model
        Pump finalPump = baselineSimulation.pump.copy();
        finalPump.copyPumpInfusionSequences(times: times, pumpInfs: pumpInfs);
        Simulation finalSimulation = baselineSimulation.copy();
        finalSimulation.pump = finalPump;

        // Extract estimates from baseline & final simulations
        Map<String, List> baselineEstimate = baselineSimulation.estimate;
        Map<String, List> finalEstimate = finalSimulation.estimate;

        // Extract CEs and CPs from the estimates
        List<double> baselineCEs =
            baselineEstimate['concentrations_effect'] as List<double>;
        List<double> finalCEs =
            finalEstimate['concentrations_effect'] as List<double>;

        List<double> CEPErrors = [];
        List<double> CEPercentageErrors = [];
        List<double> CEAbsolutePercentageErrors = [];

        for (int i = 0; i < finalCEs.length; i++) {
          double error = finalCEs[i] - baselineCEs[i];
          CEPErrors.add(error);
          CEPercentageErrors.add(error / baselineCEs[i]);
          CEAbsolutePercentageErrors.add(error.abs() / baselineCEs[i]);
        }

        double SSE =
            CEPErrors.reduce((value, element) => value + element * element);
        double MdPE = calculateMedian(CEPercentageErrors);
        double MdAPE = calculateMedian(CEAbsolutePercentageErrors);
        double maxPE =
            CEAbsolutePercentageErrors.where((element) => !element.isNaN)
                .reduce(max);

        weightGuesses.add(weightGuess);
        bolusGuesses.add(bolusGuess);
        SSEs.add(SSE);
        MdPEs.add(MdPE);
        MdAPEs.add(MdAPE);
        maxPEs.add(maxPE);
      }
    }

    List<int> minIndices = findMinIndices(SSEs);

    if (minIndices.length > 1) {
      List<double> filteredMaxPEs = [];
      for (int i = 0; i < minIndices.length; i++) {
        filteredMaxPEs.add(maxPEs[minIndices[i]]);
      }
      int filteredMinIndex = findMinIndices(filteredMaxPEs).first;
      weightBestGuess = weightGuesses[minIndices[filteredMinIndex]];
      bolusBestGuess = bolusGuesses[minIndices[filteredMinIndex]];
    } else {
      weightBestGuess = weightGuesses[minIndices.first];
      bolusBestGuess = bolusGuesses[minIndices.first];
    }

    return (
      weightBestGuess: weightBestGuess,
      bolusBestGuess: bolusBestGuess,
      length: SSEs.length,
      weightGuesses: weightGuesses,
      bolusGuesses: bolusGuesses,
      SSEs: SSEs,
      MdPEs: MdPEs,
      MdAPEs: MdAPEs,
      maxPEs: maxPEs
    );
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
}
