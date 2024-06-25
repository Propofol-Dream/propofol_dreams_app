

import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/operation.dart';




void main() {

  test('copy()', (){
    double target = 4;
    Duration duration = const Duration(minutes: 180);

    Operation baselineOperation = Operation(target: target, duration: duration);
    Operation newOp = baselineOperation.copy();
    newOp.target = 20;
    print(newOp.target);
    print (baselineOperation.target);

  });
}