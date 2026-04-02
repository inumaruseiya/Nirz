/// `reactions` テーブル行の JSON 入出力用 DTO。
///
/// `type` は DB の `text` 列そのまま（`like` / `look` / `fire`）。ドメインの `ReactionType` への変換は Mapper 側。
final class ReactionDto {
  const ReactionDto({
    required this.id,
    required this.userId,
    required this.postId,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String postId;

  /// `reactions.type`
  final String type;

  final DateTime createdAt;

  factory ReactionDto.fromJson(Map<String, dynamic> json) {
    return ReactionDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'post_id': postId,
        'type': type,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
