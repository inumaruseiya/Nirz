import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
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
          .select('id, name, avatar_url, created_at')
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
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      final row = await _client
          .from('profiles')
          .select('id, name, avatar_url, created_at')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) {
        return const Err(ServerFailure());
      }
      final current = ProfileDto.fromJson(Map<String, dynamic>.from(row));

      if (displayName == null && avatarUrl == null) {
        return Ok(ProfileMapper.toDomain(current));
      }

      final mergedName = displayName ?? current.displayName;
      final mergedAvatar = avatarUrl ?? current.avatarUrl;

      final updated = await _client
          .from('profiles')
          .update({
            'name': mergedName,
            'avatar_url': mergedAvatar,
          })
          .eq('id', uid)
          .select('id, name, avatar_url, created_at')
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
