import 'package:equatable/equatable.dart';

import '../value_objects/post_id.dart';
import '../value_objects/reaction_type.dart';
import '../value_objects/user_id.dart';

/// `reactions` 行のドメイン表現（1ユーザー1投稿1種）。
final class Reaction extends Equatable {
  const Reaction({
    required this.userId,
    required this.postId,
    required this.type,
    required this.createdAt,
  });

  final UserId userId;
  final PostId postId;
  final ReactionType type;
  final DateTime createdAt;

  @override
  List<Object?> get props => [userId, postId, type, createdAt];
}
