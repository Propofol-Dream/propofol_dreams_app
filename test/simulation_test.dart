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
  //     Simulation sim = Simulation.schnider(
  //         weight: 100, height: 180, age: 30, gender: Gender.Male, refresh_rate: 5);
  //     var start = DateTime.now();
  //     var res = sim.simulate(depth: 10, duration: 200, propofol_density: 20);
  //     var finish = DateTime.now();
  //     duration += (start.difference(finish));
  //     print(res);
  //   }
  //   print('Test Duration: ${duration}');
  // });

  test('Simulate for Eleveld', () {
    Duration duration = Duration.zero;
    for (int i = 0; i < cycle; i++) {
      Simulation sim = Simulation(model: Model.Eleveld,
          weight: 80, height: 170, age: 40, gender: Gender.Male, refresh_rate: 5);
      var res = sim.variables;
      // var start = DateTime.now();
      // var res = sim.simulate(depth: 10, duration: 200, propofol_density: 20);
      // var finish = DateTime.now();
      // duration += (start.difference(finish));
      print(res);
    }
    print('Test Duration: ${duration}');
  });

}
