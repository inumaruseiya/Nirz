import 'package:equatable/equatable.dart';

import '../value_objects/comment_id.dart';
import '../value_objects/post_id.dart';
import '../value_objects/user_id.dart';

/// `comments` 行のドメイン表現。`parentId == null` がトップレベル。
final class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentId,
    required this.content,
    required this.createdAt,
  });

  final CommentId id;
  final PostId postId;
  final UserId authorId;

  /// 返信先（トップレベルコメントの ID）。トップレベル本人は null。
  final CommentId? parentId;

  final String content;
  final DateTime createdAt;

  /// トップレベル（返信の親になりうる）。`parentId == null`。
  bool get isTopLevelComment => parentId == null;

  @override
  List<Object?> get props =>
      [id, postId, authorId, parentId, content, createdAt];
}
