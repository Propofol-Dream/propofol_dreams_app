
import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';


void main() {

  Duration timeStep = const Duration(seconds: 1);
  int density = 10;
  int maxPumpRate = 2000;
  double target = 2.5;
  // Duration duration = Duration(minutes: 60);
  Duration duration = const Duration(minutes: 10);

  test('Patient 1', () async {
    Model model = Model.EleveldPropofol;
    int age = 5;
    int weight = 30;
    int height = 100;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
            model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

  test('Patient 1', () async {
    Model model = Model.EleveldPropofol;
    int age = 5;
    int weight = 30;
    int height = 100;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

  test('Patient 2', () async {
    Model model = Model.EleveldPropofol;
    int age = 6;
    int weight = 50;
    int height = 130;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

  test('Patient 3', () async {
    Model model = Model.EleveldPropofol;
    int age = 7;
    int weight = 70;
    int height = 140;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

  test('Patient 4', () async {
    Model model = Model.EleveldPropofol;
    int age = 8;
    int weight = 80;
    int height = 150;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

  test('Patient 5', () async {
    Model model = Model.EleveldPropofol;
    int age = 13;
    int weight = 190;
    int height = 200;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

  test('Patient 6', () async {
    Model model = Model.EleveldPropofol;
    int age = 14;
    int weight = 190;
    int height = 200;
    Sex gender = Sex.Female;
    Patient patient =
    Patient(weight: weight, age: age, height: height, sex: gender);
    Pump pump = Pump(
        timeStep: timeStep,
        density: density,
        maxPumpRate: maxPumpRate,
        target: target,
        duration: duration);

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump);

    print("patient: $patient");
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");

  });

}
