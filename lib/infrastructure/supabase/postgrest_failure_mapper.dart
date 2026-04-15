import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';

/// [PostgrestException] を [Failure] に変換する（Supabase / PostgREST 共通）。
///
/// PostgREST の API エラーコードは
/// https://postgrest.org/en/stable/errors.html を参照。
Failure mapPostgrestException(PostgrestException e) {
  final code = e.code;
  if (code == '22023' || code == 'P0001') {
    final msg = e.message.trim();
    return ValidationFailure(msg.isEmpty ? 'Invalid request' : msg);
  }
  if (code == '23514') {
    final msg = e.message.trim();
    return ValidationFailure(msg.isEmpty ? 'Invalid request' : msg);
  }
  if (code == '28000' || code == '42501') {
    return const AuthFailure();
  }
  // PostgreSQL: undefined_function / undefined_table（マイグレーション未適用など）
  if (code == '42883' || code == '42P01') {
    return const ValidationFailure(
      'サーバー側のデータやプログラムが未更新の可能性があります。しばらくしてから再度お試しください。',
    );
  }
  // PostgREST: schema cache 上に関数が見つからない（シグネチャ不一致・未デプロイなど）
  if (code == 'PGRST202') {
    return const ValidationFailure(
      'サーバー側のデータやプログラムが未更新の可能性があります。しばらくしてから再度お試しください。',
    );
  }
  if (kDebugMode) {
    debugPrint(
      'mapPostgrestException: code=${e.code} message=${e.message} details=${e.details}',
    );
  }
  return const ServerFailure();
}
