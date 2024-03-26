import 'dart:math';

import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';

class EleMarsh {
  Simulation goldSimulation;
  double weightBound;
  double bolusBound;

  EleMarsh(
      {required this.goldSimulation,
      required this.weightBound,
      required this.bolusBound});

  ({
    List<double> MDAPEs,
    List<double> MDPEs,
    List<double> MaxAPEs,
    List<double> SSEs,
    double adjustmentBolus,
    List<Simulation> baselineSimulations,
    int bolusBestGuess,
    List<int> bolusGuesses,
    List<Simulation> comparedSimulations,
    List<Simulation> finalSimulations,
    int guessIndex,
    double inductionCPTarget,
    int length,
    double predictedBIS,
    int weightBestGuess,
    List<int> weightGuesses
  }) calculate() {
    // Set up results
    List<int> weightGuesses = [];
    List<int> bolusGuesses = [];
    List<Simulation> goldSimulations = [];
    List<Simulation> marshSimulations = [];
    List<Simulation> guessSimulations = [];
    List<double> marshSimTargetIncEstimates = [];
    List<double> SSEs = [];
    List<double> MDPEs = [];
    List<double> MDAPEs = [];
    List<double> MaxAPEs = [];
    int weightBestGuess = -1;
    int bolusBestGuess = -1;
    double inductionCPTarget = -1;

    // Set up for baseline model
    int weightGuess = goldSimulation.weightGuess;
    int boluesGuess = goldSimulation.bolusGuess;

    int minWeightGuess = (weightGuess * (1 - weightBound)).round();
    int maxWeightGuess = (minWeightGuess * (1 + weightBound)).round();

    int minBolusGuess = (boluesGuess * (1 - bolusBound)).round();
    int maxBolusGuess = (boluesGuess * (1 + bolusBound)).round();

    var goldSimEstimate = goldSimulation.estimate;
    List<double> baselineSimCEs = goldSimEstimate.concentrationsEffect;

    for (int weightGuess = minWeightGuess;
        weightGuess <= maxWeightGuess;
        weightGuess++) {
      for (int bolusGuess = minBolusGuess;
          bolusGuess <= maxBolusGuess;
          bolusGuess=bolusGuess+2) {

        // Set up for the Marsh model
        Model marshModel = Model.Marsh;
        Patient marshPatient = goldSimulation.patient.copy();
        marshPatient.weight = weightGuess;
        Pump marshPump = goldSimulation.pump.copy();
        marshPump.infuseBolus(
            startsAt: Duration.zero,
            bolus: bolusGuess.toDouble()); // Infuse the bolusGuess via the pump
        Simulation  marshSimulation = Simulation(
            model: marshModel, patient: marshPatient, pump: marshPump);
        // print(comparedPump.pumpInfusionSequences);

        // Get the pump_infs sequence out from the compared model
        var marshSimEstimate = marshSimulation.estimate;
        List<Duration> times = marshSimEstimate.times;
        List<double> pumpInfs = marshSimEstimate.pumpInfs;

        // Set up for guess model
        Pump guessPump = goldSimulation.pump.copy();
        guessPump.copyPumpInfusionSequences(times: times, pumpInfs: pumpInfs);
        Simulation guessSimulation = goldSimulation.copy();
        guessSimulation.pump = guessPump;
        // print(finalPump.pumpInfusionSequences);

        // Extract CEs and CPs from the estimates
        var guessSimEstimate = guessSimulation.estimate;
        List<double> guessSimCEs = guessSimEstimate.concentrationsEffect;
        List<double> CEPErrors = [];
        List<double> CEPercentageErrors = [];
        List<double> CEAbsolutePercentageErrors = [];

        for (int i = 0; i < guessSimCEs.length; i++) {
          double error = guessSimCEs[i] - baselineSimCEs[i];
          CEPErrors.add(error);
          CEPercentageErrors.add(error / baselineSimCEs[i]);
          CEAbsolutePercentageErrors.add(error.abs() / baselineSimCEs[i]);
        }

        double marshSimTargetIncEstimate = marshSimulation
            .estimateTargetIncreased(bolusInfusedBy: bolusGuess.toDouble());

        double SSE =
            CEPErrors.reduce((value, element) => value + element * element);
        double MDPE = calculateMedian(CEPercentageErrors);
        double MDAPE = calculateMedian(CEAbsolutePercentageErrors);
        double maxPE =
            CEAbsolutePercentageErrors.where((element) => !element.isNaN)
                .reduce(max);

        weightGuesses.add(weightGuess);
        bolusGuesses.add(bolusGuess);

        goldSimulations.add(goldSimulation);
        marshSimulations.add(marshSimulation);
        guessSimulations.add(guessSimulation);

        marshSimTargetIncEstimates
            .add(marshSimTargetIncEstimate);
        SSEs.add(SSE);
        MDPEs.add(MDPE);
        MDAPEs.add(MDAPE);
        MaxAPEs.add(maxPE);
      }
    }

    List<int> minIndices = findMinIndices(SSEs);
    int guessIndex = 0;

    if (minIndices.length > 1) {
      List<double> filteredMaxPEs = [];
      for (int i = 0; i < minIndices.length; i++) {
        filteredMaxPEs.add(MaxAPEs[minIndices[i]]);
      }
      int filteredMinIndex = findMinIndices(filteredMaxPEs).first;
      guessIndex = minIndices[filteredMinIndex];

      // weightBestGuess = weightGuesses[minIndices[filteredMinIndex]];
      // bolusBestGuess = bolusGuesses[minIndices[filteredMinIndex]];
      // initialCPTarget =
      //     marshSimTargetIncEstimates[minIndices[filteredMinIndex]];
    } else {
      guessIndex = minIndices.first;
      // weightBestGuess = weightGuesses[minIndices.first];
      // bolusBestGuess = bolusGuesses[minIndices.first];
      // initialCPTarget = marshSimTargetIncEstimates[minIndices.first];
    }

    weightBestGuess = weightGuesses[guessIndex];
    bolusBestGuess = bolusGuesses[guessIndex];
    inductionCPTarget = marshSimTargetIncEstimates[guessIndex];

    // double inductionCPTarget =
    // initialCPTarget / 4 * baselineSimulation.operation.target;
    double adjustmentBolus = bolusBestGuess / 4;

    double predictedBIS = predictBIS(
        age: goldSimulation.patient.age,
        target: goldSimulation.pump.target);

    return (
      weightBestGuess: weightBestGuess,
      bolusBestGuess: bolusBestGuess,
      adjustmentBolus: adjustmentBolus,
      inductionCPTarget: inductionCPTarget,
      length: SSEs.length,
      weightGuesses: weightGuesses,
      bolusGuesses: bolusGuesses,
      guessIndex: guessIndex,
      baselineSimulations: goldSimulations,
      comparedSimulations: marshSimulations,
      finalSimulations: guessSimulations,
      SSEs: SSEs,
      MDPEs: MDPEs,
      MDAPEs: MDAPEs,
      MaxAPEs: MaxAPEs,
      predictedBIS: predictedBIS
    );
  }

  double calculateMedian(List<double> numbers) {
    // Sort the list in ascending order
    List<double> tmp = List.from(numbers);
    tmp.sort();

    int length = tmp.length;

    if (length % 2 == 1) {
      // For odd-length list, return the middle element
      return tmp[length ~/ 2];
    } else {
      // For even-length list, return the average of the two middle elements
      double middle1 = tmp[length ~/ 2 - 1];
      double middle2 = tmp[length ~/ 2];
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

  double predictBIS({required int age, required double target}) {
    double ce50 = 3.08 * exp(-0.00635 * (age - 35));
    double bis;

    if (target > ce50) {
      bis = 93 * (pow(ce50, 1.47) / (pow(ce50, 1.47) + pow(target, 1.47)));
    } else {
      bis = 93 * (pow(ce50, 1.89) / (pow(ce50, 1.89) + pow(target, 1.89)));
    }
    return bis;
  }
}
