

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/elemarsh.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';



void main() {
  test('EleMarsh ce50Shift', () async {
    int weight = 70;
    int age = 40;
    int height = 170;
    Gender gender = Gender.Female;
    Duration timeStep = const Duration(seconds: 1);
    int density = 10;
    int maxPumpRate = 1200;
    double target = 3;
    Duration duration = const Duration(minutes: 60);

    // Set up for the model
    Model goldModel = Model.Eleveld;
    Patient goldPatient = Patient(weight: weight, age: age, height: height, gender: gender);
    Pump goldPump = Pump(timeStep: timeStep, density: density, maxPumpRate: maxPumpRate,target: target, duration: duration);
    // Operation baselineOperation = Operation(target: target, duration: duration);
    Simulation goldSimulation = Simulation(
        model: goldModel, patient: goldPatient, pump: goldPump);

    EleMarsh em = EleMarsh(goldSimulation: goldSimulation);


    var calcRsult = em.ce50Calc(ce: 4, bis: 55);
    print("ce50: ${calcRsult.ce50}");
    print("ce50Shift: ${calcRsult.ce50Shift}");

    var plotResult = em.ce50Plot(ce50: calcRsult.ce50, ce50Shift: calcRsult.ce50Shift);
    print("ceList: ${plotResult.ceList}");
    print("bisList: ${plotResult.bisList}");

  });
}



