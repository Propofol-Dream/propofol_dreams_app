import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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
  test('Trial for Eleveld', () async {
    // Duration duration = Duration.zero;

    Model model = Model.Eleveld;
    Patient patient =
        Patient(weight: 75, age: 20, height: 170, gender: Gender.Male);
    Pump pump = Pump(
        time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);
    Operation operation = Operation(
      depth: 3,
      duration: Duration(minutes: 15),
    );

    Simulation sim = Simulation(
        model: model, patient: patient, pump: pump, operation: operation);

    Pump trialPump = Pump(
        time_step: Duration(seconds: 1), dilution: 10, max_pump_rate: 10000);

    Simulation trailSimulation = Simulation(
        model: model, patient: patient, pump: trialPump, operation: operation);

    Trial trial = Trial(simulation: trailSimulation);

    var res = trial.propose(start: Duration.zero, end: Duration(minutes: 15));
    res.forEach((element) {print(element);});




    // var res = trial.findPumpInfusionInterval(start: Duration(seconds: 101), end: Duration(minutes: 15));
    // var res = trial.calculate(duration: Duration(minutes: 17));
    // print(trial.simulation.toCsv(res));
    // print(trial.bolus);
    // print(trial.trialBolus(last: 3));
    // print(trial.bolusExpiresTime);
    // print(trial.findPumpInfusionInterval(end: Duration(minutes: 15)));


    // Duration start = Duration(minutes: 3);
    // Duration end = Duration(minutes: 15);
    // var test = trial.findPumpInfusionInterval(start: start, end: end);
    // print(test);
    // print(trial.trialBolus(last: 3));


    // print(res);
    // double pump_inf = (res['end']! - res['start']! - res['bolus']!)  / (end - start).inMilliseconds * pump.time_step.inMilliseconds * 3600;
    // print(pump_inf);


    // print(trial.calculate(duration: Duration(seconds: 2)));
    // var proposed1 = trial.estimate(bolus:120, manual_pump_rate: 650, duration: Duration(seconds: 900));

    // trialPump.updateBolusSequence(bolus: 120);
    // trialPump.updatePumpInfusionSequence(start: Duration.zero, end: Duration(minutes: 15), pumpInfusion: 575);

    // trialPump.updateDepthSequence(at: Duration(minutes: 5), depth: 5);
    // trialPump.updateDepthSequence(at: Duration(minutes: 7,seconds: 30), depth: 7);
    // trialPump.updateDepthSequence(at: Duration(minutes: 10), depth: 2);
    //
    // var proposed1 = trial.estimate(manualPump: trialPump, duration: Duration(minutes: 15));
    // var baseline = trial.estimate(duration: Duration(minutes: 15));
    // print(trial.compare(baseline: baseline, proposed: proposed1));

    // final filename = '/Users/eddy/Documents/proposed.csv';
    // var file = await File(filename).writeAsString(sim.toCsv(proposed1));

    // final filename1 = '/Users/eddy/Documents/baseline.csv';
    // var file1 = await File(filename1).writeAsString(sim.toCsv(baseline));
    // print(trial.compare(baseline: baseline, proposed: proposed2));
    // print(trial.compare(baseline: baseline, proposed: proposed3));

   //  Duration start = Duration(minutes: 15);
   //  Duration end = Duration(minutes: 15, seconds: 2);
   //
   // print( trial.estimatedInterval(start: start, end: end));

  });
}
