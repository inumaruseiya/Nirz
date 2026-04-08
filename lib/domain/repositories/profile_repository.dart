import '../core/failure.dart';
import '../core/result.dart';
import '../entities/profile.dart';
import '../value_objects/user_presence_status.dart';

/// 現在ユーザーのプロフィール参照・更新。
abstract interface class ProfileRepository {
  Future<Result<Profile, Failure>> getCurrentProfile();

  /// 表示名・アバター URL の部分更新。未指定の引数は既存値を維持する（Infrastructure が merge する）。
  ///
  /// [updatePresenceStatus] が true のときだけ [presenceStatus] を反映する（`null` は DB 上でクリア）。
  ///
  /// [updateAvatarUrl] が true のときだけ [avatarUrl] を反映する（`null` はアバター削除）。
  Future<Result<Profile, Failure>> updateProfile({
    String? displayName,
    String? avatarUrl,
    bool updateAvatarUrl = false,
    bool updatePresenceStatus = false,
    UserPresenceStatus? presenceStatus,
  });
}
