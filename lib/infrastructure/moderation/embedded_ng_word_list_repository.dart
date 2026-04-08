import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/ng_word_list_repository.dart';

/// 開発・オフライン用の既定 NG ワード（実装計画 Phase 10-1-1）。
///
/// 本番では [SupabaseNgWordListRepository] を優先し、失敗時のみこの一覧を使う。
const List<String> kDefaultEmbeddedNgWords = <String>[
  // プレースホルダ（運用では Supabase `ng_words` で管理し、空なら制限なし）
];

/// クライアント埋め込みの NG ワードソース。
final class EmbeddedNgWordListRepository implements NgWordListRepository {
  const EmbeddedNgWordListRepository([this._words = kDefaultEmbeddedNgWords]);

  final List<String> _words;

  @override
  Future<Result<List<String>, Failure>> loadNgWords() async {
    final normalized = _words
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    return Ok(List.unmodifiable(normalized));
  }
}
