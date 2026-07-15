import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/calculator.dart';
import 'package:propofol_dreams_app/models/model.dart';

void main() {
  test('Calculator WakeUpCE', () async {

    Calculator c = Calculator();
    var result = c.calcWakeUpCE(ce: 2.6, se: 45 , m: Model.Eleveld);
    print(result.lower);
    print(result.upper);
  });
}



