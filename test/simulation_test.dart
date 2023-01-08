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
  int cycle = 1;

  // test('Simuate for Marsh', () {
  //   Duration duration = Duration.zero;
  //
  //   for (int i = 0; i < cycle; i++) {
  //     Simulation sim = Simulation.marsh(weight: 100, refresh_rate: 5);
  //     var start = DateTime.now();
  //     var res = sim.simulate(depth: 10, duration: 90, verbose: true);
  //     var finish = DateTime.now();
  //     duration += (start.difference(finish));
  //     print(res);
  //   }
  //   print('Test Duration: ${duration}');
  // });
  //
  // test('Simulate for Schnider', () {
  //   Duration duration = Duration.zero;
  //   for (int i = 0; i < cycle; i++) {
  //
  //     Simulation sim = Simulation.schnider(
  //         weight: 70, height: 170, age: 40, gender: Gender.Male, refresh_rate: 60);
  //     var variables = sim.variables;
  //     var start = DateTime.now();
  //     var res = sim.simulate(depth: 10, duration: 200, propofol_density: 20);
  //     var finish = DateTime.now();
  //     duration += (start.difference(finish));
  //     print(variables);
  //     // print(res);
  //   }
  //   print('Test Duration: ${duration}');
  // });

  // test('Simulate for Eleveld', () {
  //   Duration duration = Duration.zero;
  //   for (int i = 0; i < cycle; i++) {
  //
  //     Model model = Model.Eleveld;
  //     Patient patient = Patient(weight: 75, age: 20, height: 170, gender: Gender.Male);
  //     Pump pump = Pump(time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 1200);
  //     Operation operation = Operation(depth: 3, duration: Duration(minutes: 200), );
  //
  //     Simulation sim = Simulation(
  //         model: model,
  //         patient: patient,
  //         pump: pump,
  //         operation: operation);
  //
  //     Pump trialPump = Pump(time_step: Duration(seconds: 1), dilution: pump.dilution, max_pump_rate: 10000);
  //     Operation trialOperation = Operation(depth: operation.depth, duration: Duration(seconds: 100));
  //
  //     Simulation trialSim = Simulation(
  //         model: Model.Eleveld,
  //         patient:
  //             patient,
  //         pump: trialPump,
  //         operation: trialOperation);
  //     // sim.estimate(target: 2.5, duration: 5,dilution: 20,max_pump_rate: 1200);
  //     var res = trialSim.estimate;
  //     // print(res);
  //     // var json = trialSim.toJson(res);
  //     // print(json);
  //     // var res = sim.bolus;
  //     // print(res['times'].last);
  //     // print(res.values);
  //     // print(res);
  //     print(trialSim.toJson(res));
  //
  //     // print(sim.calibrated_effect);
  //     // print(sim.variables);
  //   }
  //   // print('Test Duration: ${duration}');
  // });

  test('Simulate', () async {
    Model model = Model.Eleveld;
    Patient patient =
        Patient(weight: 75, age: 20, height: 170, gender: Gender.Male);

    Pump pump = Pump(
        time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);

    Operation operation = Operation(
      depth: 3,
      duration: Duration(minutes:15),
    );

    pump.updateBolusSequence(bolus: 120);
    pump.updatePumpInfusionSequence(start: Duration.zero, end: Duration(minutes: 15), pumpInfusion: 650);

    Simulation sim = Simulation(
        model: model,
        patient: patient,
        pump: pump,
        operation: operation);

    // print(sim.calibrate['peak_effect']);
    final filename = '/Users/eddy/Documents/output.csv';
    var file = await File(filename).writeAsString(sim.toCsv(sim.estimate));
  });
}
