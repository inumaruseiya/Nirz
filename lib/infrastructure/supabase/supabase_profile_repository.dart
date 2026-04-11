import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/value_objects/user_presence_status.dart';
import '../dto/profile_dto.dart';
import '../mappers/profile_mapper.dart';

/// [ProfileRepository] の Supabase（`profiles` テーブル）実装。
final class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<Profile, Failure>> getCurrentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      final row = await _client
          .from('profiles')
          .select('id, name, avatar_url, presence_status, created_at')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) {
        return const Err(ServerFailure());
      }
      final dto = ProfileDto.fromJson(Map<String, dynamic>.from(row));
      return Ok(ProfileMapper.toDomain(dto));
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException {
      return const Err(ServerFailure());
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<Profile, Failure>> updateProfile({
    String? displayName,
    String? avatarUrl,
    bool updateAvatarUrl = false,
    bool updatePresenceStatus = false,
    UserPresenceStatus? presenceStatus,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      final row = await _client
          .from('profiles')
          .select('id, name, avatar_url, presence_status, created_at')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) {
        return const Err(ServerFailure());
      }
      final current = ProfileDto.fromJson(Map<String, dynamic>.from(row));

      final hasNameChange = displayName != null;
      final hasAvatarChange = updateAvatarUrl;
      if (!hasNameChange && !hasAvatarChange && !updatePresenceStatus) {
        return Ok(ProfileMapper.toDomain(current));
      }

      final mergedName = displayName ?? current.displayName;
      final String? mergedAvatar = updateAvatarUrl
          ? avatarUrl
          : current.avatarUrl;
      final payload = <String, dynamic>{
        'name': mergedName,
        'avatar_url': mergedAvatar,
      };
      if (updatePresenceStatus) {
        payload['presence_status'] = presenceStatus?.dbValue;
      }

      final updated = await _client
          .from('profiles')
          .update(payload)
          .eq('id', uid)
          .select('id, name, avatar_url, presence_status, created_at')
          .single();

      final dto = ProfileDto.fromJson(Map<String, dynamic>.from(updated));
      return Ok(ProfileMapper.toDomain(dto));
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException {
      return const Err(ServerFailure());
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }
}
