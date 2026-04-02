import '../../domain/services/location_obfuscation_service.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../../domain/value_objects/obfuscated_location.dart';

final class ObfuscateLocationUseCase {
  ObfuscateLocationUseCase(this._service);

  final LocationObfuscationService _service;

  ObfuscatedLocation call(GeoCoordinate raw) => _service.obfuscate(raw);
}
