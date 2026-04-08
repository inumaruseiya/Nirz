import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/infrastructure/dto/reaction_dto.dart';

void main() {
  final at = DateTime.utc(2026, 4, 1);

  group('ReactionDto', () {
    test('fromJson / toJson round-trip', () {
      final original = ReactionDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        userId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        postId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        type: 'fire',
        createdAt: at,
      );
      final back = ReactionDto.fromJson(original.toJson());
      expect(back.id, original.id);
      expect(back.userId, original.userId);
      expect(back.postId, original.postId);
      expect(back.type, original.type);
      expect(back.createdAt, original.createdAt);
    });
  });
}
