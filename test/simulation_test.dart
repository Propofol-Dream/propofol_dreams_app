
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
  Duration duration = Duration(seconds: 10);

  // Set up for the model


  test('Peak', () async {

    Model model = Model.Eleveld;
    Patient patient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump pump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate);
    // pump.infuseBolus(startsAt: Duration.zero, bolus: 146);

    // print(pump.pumpInfusionSequences);

    Operation operation = Operation(target: target, duration: duration);
    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump, operation: operation);
    final filename = '/Users/eddy/Documents/sim.csv';
    var file = await File(filename).writeAsString(sim.toCsv());

    // final filename = '/Users/eddy/Documents/sim.json';
    // var file = await File(filename).writeAsString(jsonEncode(sim.toJson()));


  });

}
