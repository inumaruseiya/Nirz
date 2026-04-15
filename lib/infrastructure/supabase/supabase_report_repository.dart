import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/report_repository.dart';
import 'postgrest_failure_mapper.dart';
import '../../domain/value_objects/report_target_type.dart';

/// [ReportRepository] の Supabase 実装（`reports` INSERT）。
final class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void, Failure>> submitReport(
    ReportSubmission submission,
  ) async {
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
      return Err(mapPostgrestException(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }
}
