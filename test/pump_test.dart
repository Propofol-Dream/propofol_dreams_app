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

  test('New Boluse Sequence', (){
    Pump pump = Pump(timeStep: const Duration(seconds: 1), density: 10, maxPumpRate: 1200,target: 4,duration: Duration(minutes: 60));
    pump.infuseBolus(startsAt: Duration.zero, bolus: 146);
    print(pump.pumpInfusionSequences);

  });
}