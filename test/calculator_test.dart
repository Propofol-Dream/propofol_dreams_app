import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/models/calculator.dart';

void main() {
  test('Calculator WakeUpCE', () async {

    Calculator c = Calculator();
    var (wakece, eegce) = c.calcWakeUpCE(ce: 2.6, se: 45);
    print(wakece);
    print(eegce);
  });
}



