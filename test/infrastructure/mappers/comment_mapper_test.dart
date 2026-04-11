import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/comment_id.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/infrastructure/dto/comment_dto.dart';
import 'package:nirz/infrastructure/mappers/comment_mapper.dart';

void main() {
  final at = DateTime.utc(2026, 4, 1);

  group('CommentMapper', () {
    test('toDomain maps parent id when present', () {
      final dto = CommentDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        postId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        userId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        parentCommentId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        content: 'r',
        createdAt: at,
      );
      final c = CommentMapper.toDomain(dto);
      expect(c.id, CommentId.parse(dto.id));
      expect(c.postId, PostId.parse(dto.postId));
      expect(c.authorId, UserId.parse(dto.userId));
      expect(
        c.parentId,
        CommentId.parse('dddddddd-dddd-4ddd-8ddd-dddddddddddd'),
      );
      expect(c.content, 'r');
    });

    test('toDomain leaves parentId null for top-level', () {
      final dto = CommentDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        postId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        userId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        parentCommentId: null,
        content: 't',
        createdAt: at,
      );
      final c = CommentMapper.toDomain(dto);
      expect(c.parentId, isNull);
      expect(c.isTopLevelComment, isTrue);
    });
  });
}
