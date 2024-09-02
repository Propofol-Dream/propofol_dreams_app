
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';

typedef guessRow = ({
int weightGuess,
int bolusGuess,
double inductionCPTarget,
double SSRE,
double maxPE});

typedef VwakeRow = ({
int step,
Duration time,
double dV1,
double A1,
double A2,
double A3,
double CP,
double CE,
});

void main() {

  double calcMedian(List<double> numbers) {
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

  ({double fit, double shiftFit}) ce50Calc({required double ce, required double bis, double shiftRatio = 0.3}){
    double baseBIS = 93;

    //This is the analytical solution to the Sigmoid Emax equation
    double ce50Fit = ce / (pow((baseBIS/bis-1),(1/1.47)) + shiftRatio);
    double ce50ShiftFit = ce50Fit * shiftRatio;

    return (fit:ce50Fit,shiftFit:ce50ShiftFit);
  }

  ({List<double> CEs, List<double> BISs}) ce50Plot({required double ce50, required double ce50Shift}){
    List<double> CEs = [];
    List<double> BISs = [];
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
      CEs.add(ce);
      BISs.add(bis);
    }
    return(CEs: CEs, BISs: BISs);
  }


  test('EleMarsh estimate()', () async {
    int weight = 150;
    int age = 75;
    int height = 135;
    Gender gender = Gender.Male;
    Duration timeStepSim = const Duration(seconds: 1);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 3;
    Duration duration = const Duration(minutes: 60);

    // Set up for the model
    Model goldModel = Model.Eleveld;
    Patient goldPatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump goldPump = Pump(timeStep: timeStepSim, density: density, maxPumpRate: maxPumpRate,target: target, duration: duration);
    // Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation goldSimulation = Simulation(
        model: goldModel, patient: goldPatient, pump: goldPump);


    // estimate's parameters
    double weightBoundary = 0.05;
    double bolusBoundary = 0.25;

    double dosageRate = 100; // mg/hr
    double CP = 3;
    double CE = 3;
    double BIS = 40;
    List<double> wakeUpBIS = [60,70];



    // Start of the estimate()
    List<guessRow> guessMatrix1 = [];
    List<guessRow> guessMatrix2 = [];

    // Set up for baseline model
    int initWeightGuess = goldSimulation.weightGuess;
    int initBoluesGuess = goldSimulation.bolusGuess;
    // print(boluesGuess);

    int minWeightGuess = (initWeightGuess * (1 - weightBoundary)).round();
    int maxWeightGuess = (initWeightGuess * (1 + weightBoundary)).round();

    int minBolusGuess = (initBoluesGuess * (1 - bolusBoundary)).round();
    int maxBolusGuess = (initBoluesGuess * (1 + bolusBoundary)).round();

    var goldSimEstimate = goldSimulation.estimate;
    List<double> goldCEs = goldSimEstimate.concentrationsEffect;

    for (int weightGuess = minWeightGuess;
    weightGuess <= maxWeightGuess;
    weightGuess = weightGuess + 1) {

        // Set up for the Marsh model
        Model marshModel = Model.Marsh;
        Patient marshPatient = goldSimulation.patient.copy();
        marshPatient.weight = weightGuess;
        Pump marshPump = goldSimulation.pump.copy();
        marshPump.infuseBolus(
            startsAt: Duration.zero,
            bolus: initBoluesGuess.toDouble()); // Infuse the bolusGuess via the pump
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
        // List<double> CEPercentageErrors = [];
        List<double> CEAbsolutePercentageErrors = [];

        for (int i = 0; i < guessSimCEs.length; i++) {
          double error = guessSimCEs[i] - goldCEs[i];
          CEPErrors.add(error);
          // CEPercentageErrors.add(error / goldCEs[i]);
          CEAbsolutePercentageErrors.add(error.abs() / goldCEs[i]);
        }

        double inductionCPTarget = marshSimulation
            .estimateTargetIncreased(bolusInfusedBy: initBoluesGuess.toDouble());

        double SSE =
            CEPErrors.reduce((value, element) => value + element * element);


        double SSRE = sqrt(SSE);
        double maxPE =
        CEAbsolutePercentageErrors.where((element) => !element.isNaN)
            .reduce(max);

        guessRow row = (weightGuess: weightGuess, bolusGuess: initBoluesGuess, SSRE: SSRE, maxPE: maxPE, wakeCeHigh: inductionCPTarget);
        guessMatrix1.add(row);
        print("{weighGuess: $weightGuess, initBoluesGuess: $initBoluesGuess, SSRE: $SSRE, maxPE: $maxPE}");
    }

    // Step 1: Find the min SSE
    double minSSRE1 = guessMatrix1.map((row) => row.SSRE).reduce((a, b) => a < b ? a : b);

    // Step 2: Find the max maxPE with matching mas SSE
    double minMaxPE1 = guessMatrix1.where((row) => row.SSRE == minSSRE1)
        .map((row) => row.maxPE)
        .reduce((a, b) => a < b ? a : b);

    // Step 3: Find first row which meets both criteria
    guessRow bestWeightGuessRow = guessMatrix1.firstWhere((row) => row.SSRE == minSSRE1 && row.maxPE == minMaxPE1);

    int weightBestGuess = bestWeightGuessRow.weightGuess;

    for (int bolusGuess = minBolusGuess;
    bolusGuess <= maxBolusGuess;
    bolusGuess=bolusGuess + 2) {

      // Set up for the Marsh model
      Model marshModel = Model.Marsh;
      Patient marshPatient = goldSimulation.patient.copy();
      marshPatient.weight = weightBestGuess;
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
      // List<double> CEPercentageErrors = [];
      List<double> CEAbsolutePercentageErrors = [];

      for (int i = 0; i < guessSimCEs.length; i++) {
        double error = guessSimCEs[i] - goldCEs[i];
        CEPErrors.add(error);
        // CEPercentageErrors.add(error / goldCEs[i]);
        CEAbsolutePercentageErrors.add(error.abs() / goldCEs[i]);
      }

      double inductionCPTarget = marshSimulation
          .estimateTargetIncreased(bolusInfusedBy: bolusGuess.toDouble());

      double SSE =
      CEPErrors.reduce((value, element) => value + element * element);


      double SSRE = sqrt(SSE);
      double maxPE =
      CEAbsolutePercentageErrors.where((element) => !element.isNaN)
          .reduce(max);

      guessRow row = (weightGuess: weightBestGuess, bolusGuess: bolusGuess, SSRE: SSRE, maxPE: maxPE, wakeCeHigh: inductionCPTarget);
      guessMatrix2.add(row);
      // print("{weighGuess: $weightGuess, bolusGuess: $bolusGuess, SSRE: $SSRE, maxPE: $maxPE}");
    }

    // Step 1: Find the min SSE
    double minSSRE2 = guessMatrix2.map((row) => row.SSRE).reduce((a, b) => a < b ? a : b);

    // Step 2: Find the max maxPE with matching mas SSE
    double minMaxPE2 = guessMatrix2.where((row) => row.SSRE == minSSRE2)
        .map((row) => row.maxPE)
        .reduce((a, b) => a < b ? a : b);

    // Step 3: Find first row which meets both criteria
    guessRow bestGuessRow = guessMatrix2.firstWhere((row) => row.SSRE == minSSRE2 && row.maxPE == minMaxPE2);


    int bolusBestGuess = bestGuessRow.bolusGuess;
    double inductionCPTarget = bestGuessRow.wakeCeHigh;

    print(goldPatient);
    print("{weightBestGuess: $weightBestGuess, bolusBestGuess: $bolusBestGuess, SSRE: ${bestGuessRow.SSRE}, maxPE: ${bestGuessRow.maxPE}, weightBoundary: $minWeightGuess to $maxWeightGuess, bolusBoundary:$minBolusGuess to $maxBolusGuess}");


    // double inductionCPTarget =
    // initialCPTarget / 4 * baselineSimulation.operation.target;
    double adjustmentBolus = bolusBestGuess / 4;

    double predictedBIS = predictBIS(
        age: goldSimulation.patient.age,
        target: goldSimulation.pump.target);


    //TODO: implement wakeup timer
    // Simulation marshABW = marshSimulations[guessIndex];
    // Pharmacokinetics

    var variables = goldSimulation.variables;
    double k21 = variables.k21;
    double k31 = variables.k31;
    double k10 = variables.k10;
    double k12 = variables.k12;
    double k13 = variables.k13;
    double V1 = variables.V1;
    double ke0 = variables.ke0;

    //List for calibrated_effect only
    List<double> A1s = [];
    List<double> A2s = [];
    List<double> A3s = [];
    List<Duration> times = [];
    List<int> steps = [];
    List<double> concentrations = [];
    List<double> concentrationsEffect = [];

    double timeStep = goldSimulation.pump.timeStep.inMilliseconds /
        1000; // this is to allow time_step in milliseconds

    dosageRate = dosageRate / 60; // mg per min

    double A1 = CP*V1; // drug amount in V1 compartment
    double A2 = (A1*(k10+k12+k13) - dosageRate)/(k21+k31) * timeStep; //drug amount in V2 compartment
    double A3 = A2;
    double CPCurrent = CP;
    double CECurrent = CE;

    int step = 0;
    Duration time = Duration.zero;

    // Record type annotation in a variable declaration:

    List<VwakeRow> Vwake = [];
    VwakeRow row1 = (time: Duration.zero, A1:A1, A2:A2, A3: A3, CP:CPCurrent, CE:CECurrent, dV1:0.0, step: step);
    VwakeRow row2 = (time: Duration.zero, A1:A1, A2:A2, A3: A3, CP:CPCurrent, CE:CECurrent, dV1:0.0, step: 1);

    Vwake.add(row1);
    Vwake.add(row2);

    // VwakeRow row = Vwake.reduce((currentMax, row) => row.step > currentMax.step ? row : currentMax);
    // print('Maximum Step: $row');

    // Vwake.add((time: Duration.zero, A1:A1, A2:A2, A3: A3, CP:CPCurrent, CE:CECurrent, dV1:0.0, step: step));
    //
    // print(Vwake.first.A1);
    //
    // // Finding the maximum step using reduce
    // int maxStep = Vwake.map((v) => v.step).reduce((a, b) => a > b ? a : b);
    // print('Maximum Age: $maxStep');








  });


}



