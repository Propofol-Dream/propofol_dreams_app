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
  test('Approximation', () async {

    // Set up for baseline model
    Model baselineModel = Model.Eleveld;
    Patient baselinePatient = Patient(weight: 80, age: 40, height: 170, gender: Gender.Male);
    Pump baselinePump = Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);
    Operation baselineOperation = Operation(target: 4, duration: Duration(minutes: 60));
    Simulation baselineSim = Simulation(
        model: baselineModel, patient: baselinePatient, pump: baselinePump, operation: baselineOperation);

    // double baselineBolus = baselineSim.estimateBolusInfused(targetIncreasedBy: baselineOperation.target);

    double trialBolus = 120;

    // Set up for compared model
    Model comparedModel = Model.Marsh;
    int adjstedWeight = 120;
    Patient comparedPatient = Patient(weight: adjstedWeight, age: 40, height: 170, gender: Gender.Male);
    Pump comparedPump = Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);
    Simulation comparedSim = Simulation(
        model: comparedModel, patient: comparedPatient, pump: comparedPump, operation: baselineOperation);

    comparedPump.infuseBolus(startsAt: Duration.zero, bolus: trialBolus);

    Map<String, List> comparedResult = comparedSim.estimate;
    List<Duration> times = comparedResult['times'] as List<Duration>;
    List<double> pumpInfs = comparedResult['pump_infs'] as List<double>;

    // Set up for final model
    Pump finalPump = Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);
    finalPump.copyPumpInfusionSequences(times: times, pumpInfs: pumpInfs);

    Simulation finalSim = Simulation(model: baselineModel, patient: baselinePatient, pump: finalPump, operation: baselineOperation);

    final filename = '/Users/eddy/Documents/output.csv';
    var file = await File(filename).writeAsString(finalSim.toCsv(finalSim.estimate));
    
    // Duration start = Duration(seconds: 200);
    // Duration end = Duration(seconds: 210);
    //
    // for (Duration i = start; i <= end; i=i+pump.timeStep) {
    //   pump.updatePumpInfusionSequence(at: i, pumpInfusion: 12000);
    //   print(i);
    // }
    //
    // final filename = '/Users/eddy/Documents/output.csv';
    // var file = await File(filename).writeAsString(sim.toCsv(sim.estimate));
  });

  // test('Update Pump Target Sequences', () async {
  //   Model model = Model.Eleveld;
  //   Patient patient =
  //   Patient(weight: 80, age: 40, height: 170, gender: Gender.Male);
  //
  //   Pump pump =
  //   Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);
  //
  //   Operation operation =
  //   Operation(target: 4, duration: Duration(seconds: 1100));
  //
  //   Simulation sim = Simulation(
  //       model: model, patient: patient, pump: pump, operation: operation);
  //
  //   pump.updateTargetSequences(at: Duration(seconds: 300), target: 10);
  //
  //   final filename = '/Users/eddy/Documents/output.csv';
  //   var file = await File(filename).writeAsString(sim.toCsv(sim.estimate));
  // });
  //
  // test('Update Pump Pump Infusion Sequences', () async {
  //   Model model = Model.Eleveld;
  //   Patient patient =
  //   Patient(weight: 80, age: 40, height: 170, gender: Gender.Male);
  //
  //   Pump pump =
  //   Pump(timeStep: Duration(seconds: 1), density: 10, maxPumpRate: 1200);
  //
  //   Operation operation =
  //   Operation(target: 4, duration: Duration(seconds: 1100));
  //
  //   Simulation sim = Simulation(
  //       model: model, patient: patient, pump: pump, operation: operation);
  //
  //   Duration start = Duration(seconds: 200);
  //   Duration end = Duration(seconds: 210);
  //
  //   for (Duration i = start; i <= end; i=i+pump.timeStep) {
  //     pump.updatePumpInfusionSequence(at: i, pumpInfusion: 12000);
  //     print(i);
  //   }
  //
  //   final filename = '/Users/eddy/Documents/output.csv';
  //   var file = await File(filename).writeAsString(sim.toCsv(sim.estimate));
  // });
}
