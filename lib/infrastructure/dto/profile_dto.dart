/// `profiles` テーブル行の JSON 入出力用 DTO。
///
/// PostgREST / Supabase は snake_case。Dart 側は camelCase プロパティとする。
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
  final String displayName;

  /// `profiles.avatar_url`。
  final String? avatarUrl;

  /// `profiles.created_at`。
  final DateTime createdAt;

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      id: json['id'] as String,
      displayName: (json['name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': displayName,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
