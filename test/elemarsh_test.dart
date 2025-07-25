

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';

void main() {
  test('EleMarsh handBolus', () async {
    int weight = 130;
    int age = 45;
    int height = 170;
    Sex gender = Sex.Male;
    Duration timeStep = const Duration(seconds: 1);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 4;
    Duration duration = const Duration(minutes: 60);

    // Set up for the model
    Model goldModel = Model.EleveldPropofol;
    Patient goldPatient = Patient(weight: weight, age: age, height: height, sex: gender);
    Pump goldPump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate,target: target, duration: duration);
    // Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation goldSimulation = Simulation(
        model: goldModel, patient: goldPatient, pump: goldPump);

    EleMarsh em = EleMarsh(goldSimulation: goldSimulation);

    var result = em.estimate(weightBound: 0, bolusBound: 0);
    print('bolusBestGuess: ${result.bolusBestGuess}');
    print('ABW: ${result.weightBestGuess}');
    print('handBolus: ${result.manualBolus}');
  });
}



