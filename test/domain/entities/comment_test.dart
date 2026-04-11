import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/entities/comment.dart';
import 'package:nirz/domain/value_objects/comment_id.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';

void main() {
  final postId = PostId.parse('11111111-1111-4111-8111-111111111111');
  final authorId = UserId.parse('22222222-2222-4222-8222-222222222222');
  final topId = CommentId.parse('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
  final replyId = CommentId.parse('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
  final createdAt = DateTime.utc(2026, 4, 1);

  group('Comment.isTopLevelComment', () {
    test('is true when parentId is null', () {
      final c = Comment(
        id: topId,
        postId: postId,
        authorId: authorId,
        parentId: null,
        content: 'top',
        createdAt: createdAt,
      );
      expect(c.isTopLevelComment, isTrue);
    });

    test('is false when parentId is set (direct reply to top-level)', () {
      final c = Comment(
        id: replyId,
        postId: postId,
        authorId: authorId,
        parentId: topId,
        content: 'reply',
        createdAt: createdAt,
      );
      expect(c.isTopLevelComment, isFalse);
    });
  });

  group('Comment one-level nesting (FR-COMMENT-02)', () {
    Comment topLevel() => Comment(
      id: topId,
      postId: postId,
      authorId: authorId,
      parentId: null,
      content: 'root',
      createdAt: createdAt,
    );

    test('valid: reply references top-level id on same post', () {
      final top = topLevel();
      final reply = Comment(
        id: replyId,
        postId: postId,
        authorId: authorId,
        parentId: topId,
        content: 're',
        createdAt: createdAt,
      );
      expect(top.isTopLevelComment, isTrue);
      expect(reply.parentId, top.id);
      expect(reply.postId, top.postId);
    });

    test('invalid thread shape: parent is itself a reply (nested reply)', () {
      final mid = Comment(
        id: CommentId.parse('cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
        postId: postId,
        authorId: authorId,
        parentId: topId,
        content: 'first reply',
        createdAt: createdAt,
      );
      final nestedReply = Comment(
        id: CommentId.parse('dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
        postId: postId,
        authorId: authorId,
        parentId: mid.id,
        content: 'reply to reply',
        createdAt: createdAt,
      );
      expect(mid.isTopLevelComment, isFalse);
      expect(nestedReply.parentId, mid.id);
      // UseCase 層で拒否すべき形: 親がトップレベルでない
      expect(mid.isTopLevelComment, isFalse);
    });
  });

  group('Comment equality', () {
    test('uses id, postId, authorId, parentId, content, createdAt', () {
      final a = Comment(
        id: topId,
        postId: postId,
        authorId: authorId,
        parentId: null,
        content: 'x',
        createdAt: createdAt,
      );
      final b = Comment(
        id: topId,
        postId: postId,
        authorId: authorId,
        parentId: null,
        content: 'x',
        createdAt: createdAt,
      );
      final otherContent = Comment(
        id: topId,
        postId: postId,
        authorId: authorId,
        parentId: null,
        content: 'y',
        createdAt: createdAt,
      );
      expect(a, b);
      expect(a, isNot(otherContent));
    });
  });
}
