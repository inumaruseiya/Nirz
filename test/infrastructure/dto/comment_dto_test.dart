import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/infrastructure/dto/comment_dto.dart';

void main() {
  final at = DateTime.utc(2026, 4, 1);

  group('CommentDto', () {
    test('fromJson / toJson with parent_comment_id', () {
      final original = CommentDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        postId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        userId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        parentCommentId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        content: 'reply',
        createdAt: at,
      );
      final back = CommentDto.fromJson(original.toJson());
      expect(back.parentCommentId, original.parentCommentId);
      expect(back.content, original.content);
    });

    test('fromJson allows null parent_comment_id', () {
      final dto = CommentDto.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'post_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'user_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'parent_comment_id': null,
        'content': 'top',
        'created_at': at.toIso8601String(),
      });
      expect(dto.parentCommentId, isNull);
    });
  });
}
