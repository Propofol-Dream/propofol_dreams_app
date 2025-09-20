import 'dart:math';

import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/model.dart';

class EleMarsh {
  Simulation goldSimulation;
  EleMarsh(
      {required this.goldSimulation});

  ({
    int weightBestGuess,
    int bolusBestGuess,
    double adjustmentBolus,
    double inductionCPTarget,
    double manualBolus,
    double predictedBIS,
    Simulation goldSimulationBest,
    Simulation marshSimulationBest,
    Simulation guessSimulationBest,
    Duration? vial20mlTime,
    Duration? vial50mlTime,
  }) estimate({required double weightBound, required double bolusBound}) {
    // Set up results
    List<int> weightGuesses = [];
    List<int> bolusGuesses = [];
    List<Simulation> goldSimulations = [];
    List<Simulation> marshSimulations = [];
    List<Simulation> guessSimulations = [];
    List<double> marshSimTargetIncEstimates = [];
    List<double> MaxAPEs = [];
    int weightBestGuess = -1;
    int bolusBestGuess = -1;
    double inductionCPTarget = -1;

    // Set up for baseline model
    int weightGuess = goldSimulation.weightGuess;
    int boluesGuess = goldSimulation.bolusGuess;

    int minWeightGuess = (weightGuess * (1 - weightBound)).round();
    int maxWeightGuess = (weightGuess * (1 + weightBound)).round();

    int minBolusGuess = (boluesGuess * (1 - bolusBound)).round();
    int maxBolusGuess = (boluesGuess * (1 + bolusBound)).round();

    var goldSimEstimate = goldSimulation.estimate;
    List<double> baselineSimCEs = goldSimEstimate.concentrationsEffect;

    for (int weightGuess = minWeightGuess;
        weightGuess <= maxWeightGuess;
        weightGuess++) {
      for (int bolusGuess = minBolusGuess;
          bolusGuess <= maxBolusGuess;
          bolusGuess = bolusGuess+2) {

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
        // List<double> CEPErrors = [];
        // List<double> CEPercentageErrors = [];
        List<double> CEAbsolutePercentageErrors = [];

        for (int i = 0; i < guessSimCEs.length; i++) {
          double error = guessSimCEs[i] - baselineSimCEs[i];
          // CEPErrors.add(error);
          // CEPercentageErrors.add(error / baselineSimCEs[i]);
          CEAbsolutePercentageErrors.add(error.abs() / baselineSimCEs[i]);
        }

        double marshSimTargetIncEstimate = marshSimulation
            .estimateTargetIncreased(bolusInfusedBy: bolusGuess.toDouble());

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
        MaxAPEs.add(maxPE);
      }
    }

    List<int> minIndices = findMinValueIndex(MaxAPEs);
    int guessIndex = 0;

    if (minIndices.length > 1) {
      List<double> filteredMaxPEs = [];
      for (int i = 0; i < minIndices.length; i++) {
        filteredMaxPEs.add(MaxAPEs[minIndices[i]]);
      }
      int filteredMinIndex = findMinValueIndex(filteredMaxPEs).first;
      guessIndex = minIndices[filteredMinIndex];

    } else {
      guessIndex = minIndices.first;
    }

    weightBestGuess = weightGuesses[guessIndex];
    bolusBestGuess = bolusGuesses[guessIndex];
    inductionCPTarget = marshSimTargetIncEstimates[guessIndex];
    double adjustmentBolus = bolusBestGuess / 4;

    // Extract the optimal simulation objects using the best guess index
    Simulation goldSimulationBest = goldSimulations[guessIndex];
    Simulation marshSimulationBest = marshSimulations[guessIndex];
    Simulation guessSimulationBest = guessSimulations[guessIndex];

    // Getting manualBolus
    Simulation marshBestSim = marshSimulations[guessIndex];
    double V1 = marshBestSim.variables.V1;
    double manualBolus = bolusBestGuess / 4 * goldSimulation.pump.target - V1 * goldSimulation.pump.target;

    double predictedBIS = predictBIS(
        age: goldSimulation.patient.age,
        target: goldSimulation.pump.target);

    // Calculate vial preparation times from guess simulation
    Duration? vial20mlTime = guessSimulationBest.vial20mlTime;
    Duration? vial50mlTime = guessSimulationBest.vial50mlTime;

    return (
      weightBestGuess: weightBestGuess,
      bolusBestGuess: bolusBestGuess,
      adjustmentBolus: adjustmentBolus,
      inductionCPTarget: inductionCPTarget,
      manualBolus: manualBolus,
      predictedBIS: predictedBIS,
      goldSimulationBest: goldSimulationBest,
      marshSimulationBest: marshSimulationBest,
      guessSimulationBest: guessSimulationBest,
      vial20mlTime: vial20mlTime,
      vial50mlTime: vial50mlTime
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

  List<int> findMinValueIndex(List<double> numbers) {
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

  ({double ce50, double ce50Shift}) ce50Calc({required double ce, required double bis, double shiftRatio = 0.3}){
    double baseBIS = 93;

    //This is the analytical solution to the Sigmoid Emax equation
    double ce50 = ce / (pow((baseBIS/bis-1),(1/1.47)) + shiftRatio);
    double ce50Shift = ce50 * shiftRatio;

    return (ce50:ce50,ce50Shift:ce50Shift);
  }

  ({List<double> ceList, List<double> bisList}) ce50Plot({required double ce50, required double ce50Shift}){
    List<double> ceList = [];
    List<double> bisList = [];
    double baseBIS = 93;

    for (double ce = 1; ce <6; ce= ce+0.01){
      double bis = 0;
      if (ce - ce50Shift <=0){
        bis = baseBIS;
      }
      else if (ce - ce50Shift > ce50){
        bis = baseBIS*(pow(ce50,1.47))/(pow(ce50,1.47)+pow((ce-ce50Shift),1.47));
      }
      else{
        bis = baseBIS*(pow(ce50,1.89))/(pow(ce50,1.89)+pow((ce-ce50Shift),1.89));
      }
      ceList.add(ce);
      bisList.add(bis);
    }
    return(ceList: ceList, bisList: bisList);

  }

}
