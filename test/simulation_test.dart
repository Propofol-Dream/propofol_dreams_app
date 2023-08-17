import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';

import 'dart:io';
import 'package:propofol_dreams_app/constants.dart';

void main() {
  test('Bolus', () async {
    int weight = 80;
    int age = 40;
    int height = 170;
    Gender gender = Gender.Male;
    Duration timeStep = Duration(seconds: 1);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 4;
    Duration duration = Duration(minutes: 180);

    // Set up for the model
    Model baselineModel = Model.Eleveld;
    Patient baselinePatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump baselinePump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate);
    Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation baselineSim = Simulation(
        model: baselineModel, patient: baselinePatient, pump: baselinePump, operation: baselineOperation);

    print(baselineSim.estimateBolusInfused(targetIncreasedBy: target));

    // final filename = '/Users/eddy/Documents/output.csv';
    // var file = await File(filename).writeAsString(sim.toCsv(sim.estimate2));
  });
}
