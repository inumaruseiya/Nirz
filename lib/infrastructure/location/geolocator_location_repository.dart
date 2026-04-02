import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/core/location_position_exception.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../../domain/value_objects/location_permission_state.dart';

/// [LocationRepository] の geolocator 実装（FR-LOC-01〜02）。
final class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  @override
  Future<LocationPermissionState> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionState.deniedForever;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _mapPermission(permission);
    } on PermissionDefinitionsNotFoundException {
      return LocationPermissionState.denied;
    }
  }

  static LocationPermissionState _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionState.granted;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.denied;
    }
  }

  @override
  Future<GeoCoordinate> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationPositionException(
        LocationPositionIssue.locationServicesDisabled,
      );
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        throw LocationPositionException(
          LocationPositionIssue.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw LocationPositionException(
          LocationPositionIssue.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        throw LocationPositionException(
          LocationPositionIssue.permissionDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      throw LocationPositionException(
        LocationPositionIssue.locationServicesDisabled,
      );
    } on PermissionDeniedException {
      throw LocationPositionException(
        LocationPositionIssue.permissionDenied,
      );
    } on TimeoutException {
      throw LocationPositionException(LocationPositionIssue.timeout);
    } on PermissionDefinitionsNotFoundException {
      throw LocationPositionException(LocationPositionIssue.unknown);
    }
  }
}
