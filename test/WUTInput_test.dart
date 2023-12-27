import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/WUTInput.dart';

import 'dart:collection';

void main() {

  List<int> durationInSeconds = [
    762,
    1338,
    11787,
    1808,
    11966,
    3672,
    4691,
    11846,
    8724,
    9427,
    11407,
    11513,
    11653,
    11741
  ];
  List<Duration> durationInputs =
      durationInSeconds.map((sec) => Duration(seconds: sec)).toList();

  List<double> cumulativeInfuseDosageInputs = [
    285,
    380,
    442,
    664,
    784,
    1240,
    1360,
    1630,
    1630,
    1630,
    1630,
    1630,
    1630,
    1630
  ];

  List<double> eBISInputs = [
    41,
    45,
    41,
    45,
    43,
    59,
    52,
    53,
    47,
    54,
    68,
    66,
    73,
    97
  ];


  test('WakeUpTimer Records', () async {

    SplayTreeSet<WUTInput> inputs = SplayTreeSet<WUTInput>();

    for (int i = 0; i<durationInputs.length; i++) {
      inputs.add(WUTInput(durationInput: durationInputs[i], dosageInput: cumulativeInfuseDosageInputs[i], eBISInput: eBISInputs[i]));
    }
    // The records are automatically sorted by duration.
    for (var input in inputs) {
      // print(input);
    }
    
    var testInput = inputs.firstWhere((record) => record.durationInput == Duration(seconds: 8724));
    print(testInput);
    print(testInput.toCsv());

    testInput.concentrationEffect = 100;
    print(testInput);
    print(testInput.toCsv());
  });
}
