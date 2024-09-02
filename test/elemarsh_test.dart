import 'dart:io';
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

typedef vWakeRow = ({
  int step,
  Duration time,
  double A1,
  double A2,
  double A3,
  double CP,
  double CE,
});

typedef wakeUpRow = ({
  int wakeUpBIS,
  double CEBISEleveld,
  Duration ETABIS,
  double CEBISEleMarsh
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

  ({double fit, double shiftFit}) ce50Calc({required double CE, required int BIS, double shiftRatio = 0.3}){
    double baseBIS = 93;

    //This is the analytical solution to the Sigmoid Emax equation
    double ce50Fit = CE / (pow((baseBIS/BIS-1),(1/1.47)) + shiftRatio);
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
    // Duration timeStepSim = Duration(milliseconds: 100);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 3;
    Duration duration = const Duration(hours: 3);

    // Set up for the model
    Model goldModel = Model.Eleveld;
    Patient goldPatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump goldPump = Pump(timeStep: timeStepSim, density: density, maxPumpRate: maxPumpRate,target: target, duration: duration);
    // Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation goldSimulation = Simulation(
        model: goldModel, patient: goldPatient, pump: goldPump);


    // estimate's parameters
    double weightBoundary = 0;
    double bolusBoundary = 0;

    double dosageRate = 100; // mg/hr
    double CPCurrent = 3;
    double CECurrent = 3;
    int BISCurrent = 40;
    List<int> wakeUpBISs = [60,70];
    bool verbose = true;
    verbose? print("parameters: {weightBoundary: $weightBoundary, bolusBoundary: $bolusBoundary, dosageRate: $dosageRate mg/hr, CPCurrent: $CPCurrent, CECurrent:$CECurrent, BISCurrent: $BISCurrent, wakupBISs: $wakeUpBISs}"):();



    // Start of the estimate()
    List<guessRow> guessMatrix = [];

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
      for (int bolusGuess = minBolusGuess;
      bolusGuess <= maxBolusGuess;
      bolusGuess=bolusGuess + 2) {

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
        // double MDPE = calculateMedian(CEPercentageErrors);
        // double MDAPE = calculateMedian(CEAbsolutePercentageErrors);

        double SSRE = sqrt(SSE);
        double maxPE =
        CEAbsolutePercentageErrors.where((element) => !element.isNaN)
            .reduce(max);

        guessRow row = (weightGuess: weightGuess, bolusGuess: bolusGuess, SSRE: SSRE, maxPE: maxPE, wakeCeHigh: inductionCPTarget);
        guessMatrix.add(row);

      }
    }

    // Find the min SSE
    double minSSRE = guessMatrix.map((row) => row.SSRE).reduce((a, b) => a < b ? a : b);

    // Find the max maxPE wiht matching mas SSE
    double minMaxPE = guessMatrix.where((row) => row.SSRE == minSSRE)
        .map((row) => row.maxPE)
        .reduce((a, b) => a < b ? a : b);

    // Find first row which meets both criteria
    guessRow row = guessMatrix.firstWhere((row) => row.SSRE == minSSRE && row.maxPE == minMaxPE);

    int weightBestGuess = row.weightGuess;
    int bolusBestGuess = row.bolusGuess;
    double inductionCPTarget = row.wakeCeHigh;

    double adjustmentBolus = bolusBestGuess / 4;

    double predictedBIS = predictBIS(
        age: goldSimulation.patient.age,
        target: goldSimulation.pump.target);

    verbose? print(goldPatient) : ();
    verbose? print("{weightBestGuess: $weightBestGuess, bolusBestGuess: $bolusBestGuess, inductionCPTarget: $inductionCPTarget, adjustmentBolus: $adjustmentBolus, predictedBIS: $predictedBIS, SSRE: ${row.SSRE}, maxPE: ${row.maxPE}, weightBoundary: $minWeightGuess to $maxWeightGuess, bolusBoundary:$minBolusGuess to $maxBolusGuess}"):();



    //TODO: implement wakeup timer
    List<wakeUpRow> wakeUpMatrix = [];

    for (var wakeUpBIS in wakeUpBISs) {
      var ce50 = ce50Calc(CE: CECurrent, BIS: BISCurrent);
      double CEBISEleveld = pow((93/wakeUpBIS-1), (1/1.47)) * ce50.fit + ce50.shiftFit;
      double CEBISEleMarsh = -1;
      Duration ETABIS = Duration.zero;

      wakeUpMatrix.add((wakeUpBIS: wakeUpBIS, CEBISEleveld: CEBISEleveld, ETABIS: ETABIS, CEBISEleMarsh: CEBISEleMarsh));
    }
    // verbose? wakeUpMatrix.forEach((element) {
    //   print(element);
    // }):();

    // Pharmacokinetics
    double timeStep = goldSimulation.pump.timeStep.inMilliseconds /
        1000; // this is to allow time_step in milliseconds
    dosageRate = dosageRate / 60; // mg per min

    var variables = goldSimulation.variables;
    double k21 = variables.k21;
    double k31 = variables.k31;
    double k10 = variables.k10;
    double k12 = variables.k12;
    double k13 = variables.k13;
    double V1 = variables.V1;
    double ke0 = variables.ke0;

    double A1 = CPCurrent*V1; // drug amount in V1 compartment
    double A2 = (A1 * ( k10 + k12 + k13) - dosageRate) / ( k21 + k31 ) * timeStep / 60; //drug amount in V2 compartment
    double A3 = A2;

    int step = 0;
    Duration time = Duration.zero;

    double minCEBISEleveld = wakeUpMatrix.map((v) => v.CEBISEleveld).reduce((a, b) => a < b ? a : b);
    verbose? print("minCEBISEleveld: $minCEBISEleveld"):();

    List<vWakeRow> vWakeEleveld = [];

    vWakeEleveld.add((time: time, A1:A1, A2:A2, A3: A3, CP:CPCurrent, CE:CECurrent, step: step));
    // verbose? print("vWakeEleveld.last.CE:  ${vWakeEleveld.last.CE}"):();

    while(vWakeEleveld.last.CE > minCEBISEleveld){
      step = step + 1;
      time = goldSimulation.pump.timeStep * step;
      A1 =  vWakeEleveld.last.A1
            + ( k21 * vWakeEleveld.last.A2
                + k31 * vWakeEleveld.last.A3
                - (k10 + k12 + k13) * vWakeEleveld.last.A1
              ) * timeStep / 60;
      A2 =  vWakeEleveld.last.A2
            + ( k12 * vWakeEleveld.last.A1
                - k21 * vWakeEleveld.last.A2
              ) * timeStep / 60;
      A3 =  vWakeEleveld.last.A3
            + ( k13 * vWakeEleveld.last.A1
                - k31 * vWakeEleveld.last.A3
              ) * timeStep / 60;
      double CP = A1 / V1;
      double CE =  vWakeEleveld.last.CE
            + ( vWakeEleveld.last.CP
                - vWakeEleveld.last.CE
              ) * ke0 * timeStep / 60;
      vWakeEleveld.add((time: time, A1:A1, A2:A2, A3: A3, CP:CP, CE:CE, step: step));
      for (var row in wakeUpMatrix) {
        if(row.ETABIS == Duration.zero){
          if(CE < row.CEBISEleveld){
            wakeUpMatrix.add((wakeUpBIS: row.wakeUpBIS, CEBISEleveld: row.CEBISEleveld, ETABIS: time, CEBISEleMarsh: row.CEBISEleMarsh));
            wakeUpMatrix.remove(row);
          }
        }
      }
    }

    String vWakeEleveldCSV = 'step,time,A1,A2,A3,CP,CE\n';
    verbose? vWakeEleveld.forEach((row) {
      vWakeEleveldCSV += '${row.step},${row.time.toString()},${row.A1},${row.A2},${row.A3},${row.CP},${row.CE}\n';
    }):();

    const vWakeEleveldFileName = '/Users/eddy/Developer/Dart/Propofol Dreams/propofol_dreams_app/test/vWakeEleveld.csv';
    verbose? await File(vWakeEleveldFileName).writeAsString(vWakeEleveldCSV) : ();

    // verbose? wakeUpMatrix.forEach((row) {
    //   print(row);
    // }):();


    //Convert Eleveld Ce to EleMarsh Cp

    // Now that we worked out ETA BIS60 and ETA BIS70, we can work backwards and
    // deduce the corresponding "wake up" EleMarsh Cp
    // This is based on the assumption that at equilibrium:
    // (1) EleMarsh infnrate = Eleveld infnrate
    // (2) EleMarsh Cp = Eleveld Ce

    Simulation EleMarsh = goldSimulation.copy();
    EleMarsh.model = Model.Marsh;
    EleMarsh.patient.weight = weightBestGuess;
    // verbose? print(EleMarsh) : ();

    variables = EleMarsh.variables;
    k21 = variables.k21;
    k31 = variables.k31;
    k10 = variables.k10;
    k12 = variables.k12;
    k13 = variables.k13;
    V1 = variables.V1;
    ke0 = variables.ke0;

    A1 = CPCurrent * V1; // drug amount in V1 compartment
    A2 = (A1 * ( k10 + k12 + k13) - dosageRate) / ( k21 + k31 ) * timeStep / 60; //drug amount in V2 compartment
    A3 = A2;

    step = 0;
    time = Duration.zero;

    List<vWakeRow> vWakeEleMarsh = [];

    vWakeEleMarsh.add((time: time, A1:A1, A2:A2, A3: A3, CP:CPCurrent, CE:-1, step: step));

    Duration maxETA = wakeUpMatrix.map((v) => v.ETABIS).reduce((a, b) => a > b ? a : b);
    verbose ? print("maxETA: $maxETA") : ();

    while (time < maxETA){
      step = step + 1;
      time = EleMarsh.pump.timeStep * step;

      A1 =  vWakeEleMarsh.last.A1
          + ( k21 * vWakeEleMarsh.last.A2
              + k31 * vWakeEleMarsh.last.A3
              - (k10 + k12 + k13) * vWakeEleMarsh.last.A1
          ) * timeStep / 60;
      A2 =  vWakeEleMarsh.last.A2
          + ( k12 * vWakeEleMarsh.last.A1
              - k21 * vWakeEleMarsh.last.A2
          ) * timeStep / 60;
      A3 =  vWakeEleMarsh.last.A3
          + ( k13 * vWakeEleMarsh.last.A1
              - k31 * vWakeEleMarsh.last.A3
          ) * timeStep / 60;
      double CP = A1 / V1;
      vWakeEleMarsh.add((time: time, A1:A1, A2:A2, A3: A3, CP:CP, CE:-1, step: step));
      for (var row in wakeUpMatrix) {
        if(row.CEBISEleMarsh == -1){
          if(time == row.ETABIS){
            wakeUpMatrix.add((wakeUpBIS: row.wakeUpBIS, CEBISEleveld: row.CEBISEleveld, ETABIS: row.ETABIS, CEBISEleMarsh: CP));
            wakeUpMatrix.remove(row);
          }
        }
      }
    }

    String vWakeEleMarshCSV = 'step,time,A1,A2,A3,CP,CE\n';
    verbose? vWakeEleMarsh.forEach((row) {
      vWakeEleMarshCSV += '${row.step},${row.time.toString()},${row.A1},${row.A2},${row.A3},${row.CP},${row.CE}\n';
    }):();

    const vWakeEleMarshFileName = '/Users/eddy/Developer/Dart/Propofol Dreams/propofol_dreams_app/test/vWakeEleMarsh.csv';
    verbose? await File(vWakeEleMarshFileName).writeAsString(vWakeEleMarshCSV) : ();


    verbose? wakeUpMatrix.forEach((row) {
      print(row);
    }):();




    // VwakeRow row = vWakeEleveld.reduce((currentMax, row) => row.step > currentMax.step ? row : currentMax);
    // print('Maximum Step: $row');

    // // Finding the maximum step using reduce
    // int maxStep = vWakeEleveld.map((v) => v.step).reduce((a, b) => a > b ? a : b);
    // print('Maximum Age: $maxStep');








  });


}



