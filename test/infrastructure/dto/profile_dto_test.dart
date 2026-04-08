import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/infrastructure/dto/profile_dto.dart';

void main() {
  final t0 = DateTime.utc(2026, 4, 1, 12, 0, 0);

  group('ProfileDto', () {
    test('fromJson maps snake_case and name -> displayName', () {
      final dto = ProfileDto.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Alice',
        'avatar_url': 'https://example.com/a.png',
        'presence_status': 'free',
        'created_at': t0.toIso8601String(),
      });
      expect(dto.id, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
      expect(dto.displayName, 'Alice');
      expect(dto.avatarUrl, 'https://example.com/a.png');
      expect(dto.presenceStatus, 'free');
      expect(dto.createdAt, t0);
    });

    test('fromJson treats null name as empty displayName', () {
      final dto = ProfileDto.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': null,
        'created_at': t0.toIso8601String(),
      });
      expect(dto.displayName, '');
    });

    test('toJson round-trips core fields', () {
      final original = ProfileDto(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        displayName: 'Bob',
        avatarUrl: null,
        presenceStatus: 'working',
        createdAt: t0,
      );
      final json = original.toJson();
      final back = ProfileDto.fromJson(json);
      expect(back.id, original.id);
      expect(back.displayName, original.displayName);
      expect(back.avatarUrl, original.avatarUrl);
      expect(back.presenceStatus, original.presenceStatus);
      expect(back.createdAt, original.createdAt);
    });
  });
}
