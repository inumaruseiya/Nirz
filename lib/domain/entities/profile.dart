import 'package:equatable/equatable.dart';

import '../value_objects/user_id.dart';
import '../value_objects/user_presence_status.dart';

/// `profiles` 行のドメイン表現（`auth.users` と同一 ID）。
final class Profile extends Equatable {
  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.presenceStatus,
    required this.createdAt,
  });

  final UserId id;
  final String? displayName;
  final String? avatarUrl;

  /// 設定など軽量 UI のみ。フィードカードには出さない（FR-STATUS-02）。
  final UserPresenceStatus? presenceStatus;

  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, displayName, avatarUrl, presenceStatus, createdAt];
}
