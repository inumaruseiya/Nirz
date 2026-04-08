import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/domain/value_objects/user_presence_status.dart';
import 'package:nirz/infrastructure/dto/profile_dto.dart';
import 'package:nirz/infrastructure/mappers/profile_mapper.dart';

void main() {
  final t0 = DateTime.utc(2026, 4, 1);

  group('ProfileMapper', () {
    test('maps display name trim and empty to null', () {
      final dto = ProfileDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        displayName: '  Ann  ',
        avatarUrl: null,
        presenceStatus: null,
        createdAt: t0,
      );
      final p = ProfileMapper.toDomain(dto);
      expect(p.id, UserId.parse('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'));
      expect(p.displayName, 'Ann');
    });

    test('blank displayName becomes null', () {
      final dto = ProfileDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        displayName: '   ',
        createdAt: t0,
      );
      final p = ProfileMapper.toDomain(dto);
      expect(p.displayName, isNull);
    });

    test('parses presence and trims avatar URL', () {
      final dto = ProfileDto(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        displayName: 'x',
        avatarUrl: ' https://x.test/a.png ',
        presenceStatus: 'out',
        createdAt: t0,
      );
      final p = ProfileMapper.toDomain(dto);
      expect(p.avatarUrl, 'https://x.test/a.png');
      expect(p.presenceStatus, UserPresenceStatus.out);
    });
  });
}
