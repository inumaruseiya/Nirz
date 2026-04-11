import '../core/failure.dart';

/// 投稿・コメント本文に NG ワードが含まれるか検査する（実装計画 Phase 10-1-2）。
///
/// [ngWords] は小文字・trim 済みの語を想定（[NgWordListRepository] の戻り値）。
ValidationFailure? ngWordValidationFailure(
  String content,
  List<String> ngWords,
) {
  final normalized = content.toLowerCase();
  for (final w in ngWords) {
    if (w.isEmpty) continue;
    if (normalized.contains(w)) {
      return const ValidationFailure('不適切な表現が含まれています。内容を修正してください。');
    }
  }
  return null;
}
