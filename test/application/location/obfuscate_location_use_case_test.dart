import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nirz/application/location/obfuscate_location_use_case.dart';
import 'package:nirz/domain/services/location_obfuscation_service.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';

class _MockLocationObfuscationService extends Mock
    implements LocationObfuscationService {}

void main() {
  final raw = GeoCoordinate(latitude: 35.68, longitude: 139.76);
  final blurred = ObfuscatedLocation(
    GeoCoordinate(latitude: 35.69, longitude: 139.77),
  );

  late _MockLocationObfuscationService service;
  late ObfuscateLocationUseCase useCase;

  setUpAll(() {
    registerFallbackValue(raw);
  });

  setUp(() {
    service = _MockLocationObfuscationService();
    useCase = ObfuscateLocationUseCase(service);
  });

  group('ObfuscateLocationUseCase', () {
    test('returns service obfuscate result for raw coordinate', () {
      when(() => service.obfuscate(raw)).thenReturn(blurred);

      final result = useCase(raw);

      expect(result, blurred);
      verify(() => service.obfuscate(raw)).called(1);
    });
  });
}
