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
  // test('Pump Infusion Sequence', ()  {
  //   Pump pump = Pump(time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);
  //   pump.updatePumpInfusionSequence(start: Duration.zero, end: Duration(seconds: 4), pumpInfusion: 650);
  //   pump.updatePumpInfusionSequence(start: Duration(seconds: 2), end: Duration(seconds: 2), pumpInfusion: 500);
  //   print(pump.pumpInfusionSequences);
  // });
  //
  // test('Depth Sequence', ()  {
  //   Pump pump = Pump(time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);
  //   pump.updateDepthSequence(at: Duration(seconds: 4), depth: 3.3);
  //   pump.updateDepthSequence(at: Duration(seconds: 2), depth: 4.5);
  //   print(pump.depthSequences);
  // });

  // test('Pump Infusion & Depth Sequence', ()  {
  //   Pump pump = Pump(time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);
  //   pump.updatePumpInfusionSequence(start: Duration.zero, end: Duration(seconds: 4), pumpInfusion: 650);
  //   pump.updatePumpInfusionSequence(start: Duration(seconds: 2), end: Duration(seconds: 2), pumpInfusion: 500);
  //   pump.updateDepthSequence(start: Duration.zero, end: Duration(seconds: 4), depth: 3.3);
  //   pump.updateDepthSequence(start: Duration(seconds: 2), end: Duration(seconds: 2), depth: 4.5);
  //   print(pump.pumpInfusionSequences);
  //   print(pump.depthSequences);
  // });

  test('Boluse Sequence', (){
    Pump pump = Pump(time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);
    pump.updateBolusSequence(bolus: 138.888);
    print(pump.bolusSequence);
    print(pump.bolusSequence![Duration(seconds: 1)]);
    pump.updateDepthSequence(at: Duration(seconds: 4), depth: 3.3);
    pump.updateDepthSequence(at: Duration(seconds: 2), depth: 4.5);
    print(pump.isManual);
    print(pump);

  });
}