import 'package:equatable/equatable.dart';

import '../value_objects/obfuscated_location.dart';
import '../value_objects/post_id.dart';
import '../value_objects/user_id.dart';

/// `posts` 行のドメイン表現。位置は常にぼかし済み。
final class Post extends Equatable {
  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    required this.location,
    required this.createdAt,
    required this.expiresAt,
  });

  final PostId id;
  final UserId authorId;
  final String content;
  final Uri? imageUrl;
  final ObfuscatedLocation location;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// 表示期限切れ（`expires_at > now()` の否定と整合: 同一時刻は期限切れ扱い）。
  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  @override
  List<Object?> get props =>
      [id, authorId, content, imageUrl, location, createdAt, expiresAt];
}
