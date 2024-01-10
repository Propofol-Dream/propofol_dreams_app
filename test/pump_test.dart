import 'dart:ffi';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/constants.dart';
import 'package:propofol_dreams_app/models/operation.dart';
import 'package:propofol_dreams_app/models/patient.dart';
import 'package:propofol_dreams_app/models/pump.dart';
import 'package:propofol_dreams_app/models/simulation.dart';
import 'package:propofol_dreams_app/models/model.dart';
import 'package:propofol_dreams_app/models/gender.dart';
import 'dart:io';

void main() {
  test('New Boluse Sequence', () {
    Pump pump = Pump(
        timeStep: const Duration(seconds: 1),
        density: 10,
        maxPumpRate: 1200,
        target: 4,
        duration: Duration(minutes: 60));
    // pump.infuseBolus(startsAt: Duration.zero, bolus: 146);
    // print(pump.pumpInfusionSequences);

    List<Duration> times = [Duration(seconds: 1),Duration(seconds: 2)];
    List<double> pumpInfs = [1000.0,900.0];

    pump.copyPumpInfusionSequences(times: times, pumpInfs: pumpInfs);
    print(pump.pumpInfusionSequences);

    Pump pump2 = pump.copy();
    List<Duration> times2 = [Duration(seconds: 3),Duration(seconds: 4)];
    List<double> pumpInfs2 = [800.0,900.0];
    pump2.copyPumpInfusionSequences(times: times2, pumpInfs: pumpInfs2);

    print(pump2.pumpInfusionSequences);

    print(pump.pumpInfusionSequences);

  });
}
