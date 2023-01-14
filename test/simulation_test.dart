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
    Model model = Model.Eleveld;
    Patient patient =
        Patient(weight: 58, age: 50, height: 160, gender: Gender.Female);

    Pump pump =
        Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);

    Operation operation = Operation(
      target: 4,
      duration: Duration(minutes: 30)
    );

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump, operation: operation);

    pump.updateTarget(at: Duration(minutes: 10), target: 8);
    pump.updateBolus(at: Duration(minutes: 10), bolus: sim.estimateBolus(8-operation.target));


    print(sim.estimateBolus(8-operation.target));
    print(pump.infuseBolusRate(bolus: sim.estimateBolus(4)));
    print(pump.infuseBolusDuration(bolus: sim.estimateBolus(4)));

    final filename = '/Users/eddy/Documents/output.csv';
    var file = await File(filename).writeAsString(sim.toCsv(sim.estimate2));
  });
}
