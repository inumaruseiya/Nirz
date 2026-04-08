import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/reaction_type.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/infrastructure/dto/reaction_dto.dart';
import 'package:nirz/infrastructure/mappers/reaction_mapper.dart';

void main() {
  final at = DateTime.utc(2026, 4, 1);

  group('ReactionMapper', () {
    test('toDomain parses type enum', () {
      final dto = ReactionDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        userId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        postId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        type: 'look',
        createdAt: at,
      );
      final r = ReactionMapper.toDomain(dto);
      expect(r.userId, UserId.parse(dto.userId));
      expect(r.postId, PostId.parse(dto.postId));
      expect(r.type, ReactionType.look);
      expect(r.createdAt, at);
    });
  });
}
