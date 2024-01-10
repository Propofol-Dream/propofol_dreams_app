

import 'package:flutter_test/flutter_test.dart';





 void main() {

   test('stopwatch', () async {
    final stopwatch = Stopwatch();
    print(stopwatch.elapsedMilliseconds); // 0
    print(stopwatch.isRunning); // false
    stopwatch.start();
    print(stopwatch.isRunning); // true
    // stopwatch.stop();
    print(stopwatch.isRunning); // false
    Duration elapsed = stopwatch.elapsed;
    await Future.delayed(const Duration(seconds: 1));
    // assert(stopwatch.elapsed == elapsed); // No measured time elapsed.
    // stopwatch.start(); // Continue measuring.
    // stopwatch.stop();
    print(stopwatch.elapsed); // Likely > 0.
    stopwatch.reset();
    print(stopwatch.elapsed); // 0



  });
}