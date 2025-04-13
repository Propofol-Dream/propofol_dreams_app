
import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/sex.dart';


void main() {
  int weight = 128;
  int age = 40;
  int height = 160;
  Sex gender = Sex.Female;
  Duration timeStep = const Duration(seconds: 1);
  int density = 10;
  int maxPumpRate = 2000;
  double target = 2.5;
  Duration duration = const Duration(minutes: 10);

  test('Peak', () async {
    Model model = Model.Eleveld;
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

    print(sim);
    print("abw guess: ${sim.weightGuess}");
    print("bolus guess: ${sim.bolusGuess}");


  });


  // Set up for the model

  // test('Peak', () async {
  //   Model model = Model.Eleveld;
  //   Patient patient =
  //       Patient(weight: weight, age: age, height: height, gender: gender);
  //   Pump pump = Pump(
  //       timeStep: timeStep,
  //       density: density,
  //       maxPumpRate: maxPumpRate,
  //       target: target,
  //       duration: duration);
  //
  //
  //   // print(pump.pumpInfusionSequences);
  //
  //   // Operation operation = Operation(target: target, duration: duration);
  //   Simulation sim = Simulation(
  //       model: model, patient: patient, pump: pump);
  //   final filename = '/Users/eddy/Documents/new_sim.csv';
  //   await File(filename).writeAsString(sim.toCsv());
  //
  //
  //   // pump.infuseBolus(startsAt: Duration.zero, bolus: 180);
  //
  //   pump.wakeUPCe = 2.4;
  //
  //   final anotherFileName = '/Users/eddy/Documents/another_sim.csv';
  //   await File(anotherFileName).writeAsString(sim.toCsv());
  //   // final anotherFilename = '/Users/eddy/Documents/bolus_sim.json';
  //   // await File(anotherFilename).writeAsString(jsonEncode(sim.toJson()));
  //
  // });
}
