import 'package:equatable/equatable.dart';

import 'geo_coordinate.dart';

/// ぼかし済み位置（WGS84）。
///
/// ドメイン上「この型だけサーバ・DB に送ってよい」という意味のブランド型として扱う。
/// 生成は [LocationObfuscationService]（Phase 2-5-1）に限定するのが望ましい。
final class ObfuscatedLocation extends Equatable {
  const ObfuscatedLocation(this.coordinate);

  final GeoCoordinate coordinate;

  @override
  List<Object?> get props => [coordinate];

  @override
  String toString() => 'ObfuscatedLocation($coordinate)';
}
