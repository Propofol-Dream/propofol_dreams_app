import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/adjustement.dart';
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

    int weightBound = 4; // 0 = No brute force
    double bolusBound = 0.1; // 0.0 = No brute force

    // Set up for the model
    Model baselineModel = Model.Eleveld;
    Patient baselinePatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump baselinePump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate);
    Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation baselineSim = Simulation(
        model: baselineModel, patient: baselinePatient, pump: baselinePump, operation: baselineOperation);

    Adjustment adj = Adjustment(baselineSimulation: baselineSim, weightBound: weightBound, bolusBound: bolusBound);

    var result = adj.calculate();
    print(result.weightBestGuess);
    print(result.bolusBestGuess);

  });
}



