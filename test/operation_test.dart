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

  test('copy()', (){
    double target = 4;
    Duration duration = Duration(minutes: 180);

    Operation baselineOperation = Operation(target: target, duration: duration);
    Operation newOp = baselineOperation.copy();
    newOp.target = 20;
    print(newOp.target);
    print (baselineOperation.target);

  });
}