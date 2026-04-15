import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/ng_word_list_repository.dart';
import '../supabase/postgrest_failure_mapper.dart';

/// Supabase `ng_words` テーブルから NG ワードを読み込む（Phase 10-1-1）。
final class SupabaseNgWordListRepository implements NgWordListRepository {
  SupabaseNgWordListRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<String>, Failure>> loadNgWords() async {
    try {
      final rows = await _client.from('ng_words').select('word');
      final list =
          rows
              .map(
                (row) => (row['word'] as String?)?.trim().toLowerCase() ?? '',
              )
              .where((w) => w.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return Ok(List.unmodifiable(list));
    } on PostgrestException catch (e) {
      return Err(mapPostgrestException(e));
    } catch (_) {
      return const Err(ServerFailure());
    }
  }
}
