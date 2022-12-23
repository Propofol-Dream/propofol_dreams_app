import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';


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

  test('Simulate for Eleveld', () {
    Duration duration = Duration.zero;
    for (int i = 0; i < cycle; i++) {
      Simulation sim = Simulation(
        model: Model.Eleveld,
        patient: Patient(weight: 80, age: 40, height: 170, gender: Gender.Male),
        pump: Pump(time_step: 5, dilution: 20, max_pump_rate: 1200),
      );
      // sim.estimate(target: 2.5, duration: 5,dilution: 20,max_pump_rate: 1200);
      sim.estimate(operation: Operation(duration: 10, depth: 2.5));
      // print(res['times'].last);
      // print(res['cumulative_infused_volumes'].last);
      // print(sim.calibrated_effect);
      // print(sim.variables);
    }
    // print('Test Duration: ${duration}');
  });
}
