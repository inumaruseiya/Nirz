import 'package:nirz/domain/core/failure.dart';
import 'package:nirz/infrastructure/supabase/postgrest_failure_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapPostgrestException', () {
    test('PGRST202 maps to ValidationFailure (schema / RPC mismatch)', () {
      final f = mapPostgrestException(
        const PostgrestException(
          message: 'Could not find the function',
          code: 'PGRST202',
        ),
      );
      expect(f, isA<ValidationFailure>());
    });

    test('42883 maps to ValidationFailure', () {
      final f = mapPostgrestException(
        const PostgrestException(
          message: 'function does not exist',
          code: '42883',
        ),
      );
      expect(f, isA<ValidationFailure>());
    });

    test('42501 maps to AuthFailure', () {
      final f = mapPostgrestException(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(f, isA<AuthFailure>());
    });

    test('unknown code maps to ServerFailure', () {
      final f = mapPostgrestException(
        const PostgrestException(message: 'internal', code: 'XX000'),
      );
      expect(f, isA<ServerFailure>());
    });
  });
}
