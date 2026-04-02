/// リアクション種別。`reactions.type`（text）と 1:1（`like` / `look` / `fire`）。
enum ReactionType {
  like,
  look,
  fire;

  /// DB / RPC から受け取った文字列をパースする。
  static ReactionType parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'like':
        return ReactionType.like;
      case 'look':
        return ReactionType.look;
      case 'fire':
        return ReactionType.fire;
      default:
        throw FormatException('Unknown reaction type', raw);
    }
  }

  /// Supabase 等へ送るストレージ値（enum 名と同一）。
  String get storageValue => name;
}
