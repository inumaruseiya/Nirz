import 'package:json_annotation/json_annotation.dart';

part 'profile_dto.g.dart';

String _profileDisplayNameFromJson(Object? json) => (json as String?) ?? '';

/// `profiles` テーブル行の JSON 入出力用 DTO。
///
/// PostgREST / Supabase は snake_case。Dart 側は camelCase プロパティとする。
@JsonSerializable()
final class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  /// `profiles.id`（UUID 文字列）。
  final String id;

  /// `profiles.name`（表示名。DB カラム名は `name`）。
  @JsonKey(name: 'name', fromJson: _profileDisplayNameFromJson)
  final String displayName;

  /// `profiles.avatar_url`。
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// `profiles.created_at`。
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDtoToJson(this);
}
