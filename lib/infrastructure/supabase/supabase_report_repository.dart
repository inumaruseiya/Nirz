import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/value_objects/report_target_type.dart';

/// [ReportRepository] の Supabase 実装（`reports` INSERT）。
final class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void, Failure>> submitReport(ReportSubmission submission) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Err(AuthFailure());
    }

    try {
      await _client.from('reports').insert({
        'reporter_id': uid,
        'target_type': submission.targetType.storageValue,
        'target_id': submission.targetId,
        'reason': submission.reason,
        'status': 'open',
      });
      return const Ok(null);
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

  static Failure _mapPostgrest(PostgrestException e) {
    final code = e.code;
    if (code == '22023' || code == 'P0001' || code == '23514') {
      final msg = e.message.trim();
      return ValidationFailure(msg.isEmpty ? 'Invalid request' : msg);
    }
    if (code == '28000' || code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
