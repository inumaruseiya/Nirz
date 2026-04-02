import '../core/failure.dart';
import '../core/result.dart';
import '../entities/profile.dart';

/// 現在ユーザーのプロフィール参照・更新。
abstract interface class ProfileRepository {
  Future<Result<Profile, Failure>> getCurrentProfile();

  /// 表示名・アバター URL の部分更新。未指定の引数は既存値を維持する（Infrastructure が merge する）。
  Future<Result<Profile, Failure>> updateProfile({
    String? displayName,
    String? avatarUrl,
  });
}
