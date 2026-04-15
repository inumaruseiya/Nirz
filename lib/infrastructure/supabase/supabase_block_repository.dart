import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/block_repository.dart';
import '../../domain/value_objects/user_id.dart';
import 'postgrest_failure_mapper.dart';

/// [BlockRepository] の Supabase 実装（`blocks` INSERT）。
final class SupabaseBlockRepository implements BlockRepository {
  SupabaseBlockRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void, Failure>> addBlock(UserId blockedUserId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Err(AuthFailure());
    }

    try {
      await _client.from('blocks').insert({
        'blocker_id': uid,
        'blocked_id': blockedUserId.value,
      });
      return const Ok(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Err(ValidationFailure('すでにブロック済みです。'));
      }
      if (e.code == '23514') {
        final msg = e.message.trim();
        return Err(
          ValidationFailure(msg.isEmpty ? 'ブロックできません。' : msg),
        );
      }
      return Err(mapPostgrestException(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

}
