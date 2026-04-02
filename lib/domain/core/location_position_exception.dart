/// [LocationRepository.getCurrentPosition] が位置を返せないときにスローする。
///
/// Application 層で捕捉し [LocationFailure] 等へマップする（Infrastructure の geolocator 例外を外に漏らさない）。
enum LocationPositionIssue {
  permissionDenied,
  permissionDeniedForever,
  locationServicesDisabled,
  timeout,
  unknown,
}

final class LocationPositionException implements Exception {
  LocationPositionException(this.issue);

  final LocationPositionIssue issue;

  @override
  String toString() => 'LocationPositionException($issue)';
}
