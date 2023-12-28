import 'dart:convert';

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
  int weight = 75;
  int age = 20;
  int height = 170;
  Gender gender = Gender.Male;
  Duration timeStep = Duration(seconds: 1);
  int density = 10;
  int maxPumpRate = 20000;
  double target = 2.5;
  // Duration duration = Duration(minutes: 60);
  Duration duration = Duration(minutes: 10);

  // Set up for the model

  test('Peak', () async {
    Model model = Model.Eleveld;
    Patient patient =
        Patient(weight: weight, age: age, height: height, gender: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);


    // print(pump.pumpInfusionSequences);

    // Operation operation = Operation(target: target, duration: duration);
    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);
    final filename = '/Users/eddy/Documents/new_sim.csv';
    await File(filename).writeAsString(sim.toCsv());


    pump.infuseBolus(startsAt: Duration.zero, bolus: 180);

    final anotherFileName = '/Users/eddy/Documents/bolus_sim.csv';
    await File(anotherFileName).writeAsString(sim.toCsv());
    // final anotherFilename = '/Users/eddy/Documents/bolus_sim.json';
    // await File(anotherFilename).writeAsString(jsonEncode(sim.toJson()));





  });
}
