import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/managers/csv_utils.dart';

void main() {
  group('sanitizeCsvField', () {
    test('quotes a plain value without altering its content', () {
      expect(sanitizeCsvField('Leg Day'), '"Leg Day"');
    });

    test('escapes embedded double quotes', () {
      expect(sanitizeCsvField('My "Custom" Routine'), '"My ""Custom"" Routine"');
    });

    test('neutralizes a leading = to prevent formula injection', () {
      expect(sanitizeCsvField('=HYPERLINK("http://evil")'), startsWith('"\''));
    });

    for (final prefix in ['=', '+', '-', '@']) {
      test('prefixes a value starting with "$prefix" with an apostrophe', () {
        final result = sanitizeCsvField('${prefix}cmd|calc');
        expect(result, '"\'${prefix}cmd|calc"');
      });
    }

    test('does not alter a value that merely contains, but does not start with, a formula character', () {
      expect(sanitizeCsvField('Bench Press (Barbell) - 3x5'), '"Bench Press (Barbell) - 3x5"');
    });

    test('handles an empty value', () {
      expect(sanitizeCsvField(''), '""');
    });
  });
}
