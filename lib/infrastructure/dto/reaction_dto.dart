import 'package:json_annotation/json_annotation.dart';

part 'reaction_dto.g.dart';

/// `reactions` テーブル行の JSON 入出力用 DTO。
///
/// `type` は DB の `text` 列そのまま（`like` / `look` / `fire`）。ドメインの `ReactionType` への変換は Mapper 側。
@JsonSerializable()
final class ReactionDto {
  const ReactionDto({
    required this.id,
    required this.userId,
    required this.postId,
    required this.type,
    required this.createdAt,
  });

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'post_id')
  final String postId;

  /// `reactions.type`
  final String type;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory ReactionDto.fromJson(Map<String, dynamic> json) =>
      _$ReactionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionDtoToJson(this);
}
