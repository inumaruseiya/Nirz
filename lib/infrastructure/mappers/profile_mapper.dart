import '../../domain/entities/profile.dart';
import '../../domain/value_objects/user_id.dart';
import '../dto/profile_dto.dart';

/// [ProfileDto] → [Profile]
final class ProfileMapper {
  const ProfileMapper._();

  static Profile toDomain(ProfileDto dto) {
    final name = dto.displayName.trim();
    return Profile(
      id: UserId.parse(dto.id),
      displayName: name.isEmpty ? null : name,
      avatarUrl: _trimOrNull(dto.avatarUrl),
      createdAt: dto.createdAt,
    );
  }

  static String? _trimOrNull(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }
}
