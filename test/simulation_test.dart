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

  test('Peaking Fn', () async {
    Model model = Model.Eleveld;
    Patient patient =
        Patient(weight: 58, age: 50, height: 160, gender: Gender.Female);

    Pump pump = Pump(
        timeStep: Duration(milliseconds: 1000),
        density: 10,
        maxPumpRate: 10000);

    Operation operation = Operation(
      target: 3,
      duration: Duration(minutes: 30),
    );

    // pump.updateBolusSequence(bolus: 120);
    // pump.updatePumpInfusionSequence(start: Duration.zero, end: Duration(minutes: 15), pumpInfusion: 650);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump, operation: operation);

    print(sim.maxCe);
    print(sim.maxCeReachesAt);
    print(sim.ceAt(duration: Duration(seconds: 90)));

    // final filename = '/Users/eddy/Documents/output.csv';
    // var file = await File(filename).writeAsString(sim.toCsv(sim.peak));
  });
}
