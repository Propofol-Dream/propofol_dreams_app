import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propofol_dreams_app/components/collapsible_input_section.dart';

void main() {
  test('CollapsibleInputSection rejects both collapsed chip parameters', () {
    expect(
      () => CollapsibleInputSection(
        child: const SizedBox.shrink(),
        collapsedChips: const [Chip(label: Text('Single row'))],
        collapsedChipRows: const [
          [Chip(label: Text('Multiple rows'))],
        ],
      ),
      throwsA(
        isA<AssertionError>().having(
          (error) => error.message,
          'message',
          'Use either collapsedChips or collapsedChipRows, not both.',
        ),
      ),
    );
  });
}
