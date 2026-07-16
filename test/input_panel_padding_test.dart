import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary screen input rows use compact horizontal padding', () {
    const screenFiles = [
      'lib/screens/tci_screen_new.dart',
      'lib/screens/tci_screen.dart',
      'lib/screens/volume_screen.dart',
      'lib/screens/duration_screen.dart',
      'lib/screens/elemarsh_screen.dart',
    ];

    for (final path in screenFiles) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains('EdgeInsets.symmetric(horizontal: kSp16)')),
        reason: '$path should use kSp8 for input row horizontal padding.',
      );
    }
  });
}
