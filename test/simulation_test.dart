import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:flutter/foundation.dart';

import 'dart:math';

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

  test('Simulate for Schnider', () {
    Duration duration = Duration.zero;
    for (int i = 0; i < cycle; i++) {
      Simulation sim = Simulation(
          model: Model.Schnider,
          weight: 70,
          height: 170,
          age: 40,
          gender: Gender.Female,
          time_step: 1);
      // var variables = sim.variables;
      // var res = sim.simulate(depth: 10, duration: 200, propofol_density: 20);
      // var start = DateTime.now();
      // var res = sim.simulate(depth: 10, duration: 200, propofol_density: 20);
      // var finish = DateTime.now();
      // duration += (start.difference(finish));
      sim.estimate(target: 3.0, duration: 10);
      // print(res['times'].last);
      // print(res['cumulative_infused_volumes'].last);
      // print(sim.calibrated_effect);
      // print(sim.variables);
    }
    // print('Test Duration: ${duration}');
  });
}
