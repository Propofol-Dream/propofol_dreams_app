

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';


void main() {
  test('Adjustment', () async {
    int weight = 70;
    int age = 65;
    int height = 170;
    Gender gender = Gender.Female;
    Duration timeStep = Duration(seconds: 1);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 4;
    Duration duration = Duration(minutes: 60);

    int weightBound = 0; // 0 = No brute force
    double bolusBound = 0.0; // 0.0 = No brute force

    // Set up for the model
    Model baselineModel = Model.Eleveld;
    Patient baselinePatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump baselinePump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate);
    Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation baselineSim = Simulation(
        model: baselineModel, patient: baselinePatient, pump: baselinePump, operation: baselineOperation);

    EleMarsh adj = EleMarsh(baselineSimulation: baselineSim, weightBound: weightBound, bolusBound: bolusBound);

    var result = adj.calculate();
    // print("weightBestGuess: ${result.weightBestGuess}");
    // print("bolusBestGuess: ${result.adjustmentBolus}");
    // print("initialCPTarget: ${result.inductionCPTarget}");
    // print(baselineSim.weightGuess);

    // print(result.comparedSimulations.length);
    Simulation resultBaselineSim = result.baselineSimulations.first;
    Simulation resultcomparedSim = result.comparedSimulations.first;
    Simulation resultFinalSim = result.finalSimulations.first;
    // final filename1 = '/Users/eddy/Documents/resultBaselineSim.csv';
    // await File(filename1).writeAsString(resultBaselineSim.toCsv(resultBaselineSim.estimate));
    //
    // final filename2 = '/Users/eddy/Documents/resultcomparedSim.csv';
    // await File(filename2).writeAsString(resultcomparedSim.toCsv(resultcomparedSim.estimate));
    //
    // final filename3 = '/Users/eddy/Documents/resultFinalSim.csv';
    // await File(filename3).writeAsString(resultFinalSim.toCsv(resultFinalSim.estimate));

  });
}



