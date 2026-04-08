import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/core/failure.dart';
import 'package:nirz/domain/services/ng_word_moderation.dart';

void main() {
  group('ngWordValidationFailure', () {
    test('returns null when list is empty', () {
      expect(ngWordValidationFailure('hello', []), isNull);
    });

    test('detects substring case-insensitively', () {
      final f = ngWordValidationFailure('Hello BAD world', ['bad']);
      expect(f, isA<ValidationFailure>());
    });

    test('skips empty tokens in list', () {
      expect(ngWordValidationFailure('ok', ['', '  ']), isNull);
    });
  });
}
