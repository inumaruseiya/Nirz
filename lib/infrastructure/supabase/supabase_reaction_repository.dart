import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/reaction.dart';
import '../../domain/repositories/reaction_repository.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/reaction_type.dart';
import '../dto/reaction_dto.dart';
import '../mappers/reaction_mapper.dart';

/// [ReactionRepository] の Supabase 実装（`reactions` テーブル）。
final class SupabaseReactionRepository implements ReactionRepository {
  SupabaseReactionRepository(this._client);

  final SupabaseClient _client;

  static const _selectColumns = 'id, user_id, post_id, type, created_at';

  @override
  Future<Result<void, Failure>> upsertReaction(
    PostId postId,
    ReactionType type,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      await _client.from('reactions').upsert(
        {
          'user_id': uid,
          'post_id': postId.value,
          'type': type.storageValue,
        },
        onConflict: 'user_id, post_id',
      );
      return const Ok<void, Failure>(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrest(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<void, Failure>> removeReaction(PostId postId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      await _client
          .from('reactions')
          .delete()
          .eq('user_id', uid)
          .eq('post_id', postId.value);
      return const Ok<void, Failure>(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrest(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<Reaction?, Failure>> getMyReaction(PostId postId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      final row = await _client
          .from('reactions')
          .select(_selectColumns)
          .eq('user_id', uid)
          .eq('post_id', postId.value)
          .maybeSingle();
      if (row == null) {
        return const Ok(null);
      }
      final dto = ReactionDto.fromJson(Map<String, dynamic>.from(row));
      return Ok(ReactionMapper.toDomain(dto));
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrest(e));
    } on FormatException catch (e) {
      return Err(ValidationFailure(e.message));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  static Failure _mapPostgrest(PostgrestException e) {
    final code = e.code;
    if (code == '22023' || code == 'P0001') {
      final msg = e.message.trim();
      return ValidationFailure(msg.isEmpty ? 'Invalid request' : msg);
    }
    if (code == '28000' || code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
