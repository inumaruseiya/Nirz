import 'package:equatable/equatable.dart';

import '../value_objects/user_id.dart';

/// `profiles` 行のドメイン表現（`auth.users` と同一 ID）。
final class Profile extends Equatable {
  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  final UserId id;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, displayName, avatarUrl, createdAt];
}
