import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/location_permission_state.dart';

final class RequestLocationPermissionUseCase {
  RequestLocationPermissionUseCase(this._location);

  final LocationRepository _location;

  Future<LocationPermissionState> call() => _location.requestPermission();
}
