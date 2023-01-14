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
import 'package:propofol_dreams_app/models/trial.dart';
import 'dart:io';




void main() {

  test('New Boluse Sequence', (){
    Pump pump = Pump(timeStep: Duration(milliseconds: 1000), density: 10, maxPumpRate: 750);
    // pump.updateBolusSequence(bolus: 138.88888888);
    // print(pump.bolusSequence);
    // print(pump.bolusSequence![Duration(seconds: 1)]);
    // pump.updateTargetSequence(at: Duration(seconds: 4), target: 3.3);
    // pump.updateTargetSequence(at: Duration(seconds: 2), target: 4.5);
    // print(pump.isManual);
    print(pump.pumpInfusionSequences);

  });
}