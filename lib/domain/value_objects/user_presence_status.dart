/// 軽量ユーザーステータス（FR-STATUS-01）。フィードカードには出さない（FR-STATUS-02）。
enum UserPresenceStatus {
  /// 暇
  free,

  /// 作業中
  working,

  /// 外出中
  out;

  /// `profiles.presence_status` の値（PostgREST snake_case 列と対応）。
  String get dbValue => switch (this) {
    UserPresenceStatus.free => 'free',
    UserPresenceStatus.working => 'working',
    UserPresenceStatus.out => 'out',
  };

  static UserPresenceStatus? tryParseDb(String? raw) {
    if (raw == null) return null;
    switch (raw.trim()) {
      case 'free':
        return UserPresenceStatus.free;
      case 'working':
        return UserPresenceStatus.working;
      case 'out':
        return UserPresenceStatus.out;
      default:
        return null;
    }
  }
}
