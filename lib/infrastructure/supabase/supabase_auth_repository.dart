import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/user_id.dart';

/// [AuthRepository] の Supabase Auth 実装。
///
/// [client] は通常 `Supabase.instance.client`（[Supabase.initialize] 後）を渡す。
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<SessionState> watchSession() {
    return _client.auth.onAuthStateChange.map(_mapAuthState);
  }

  SessionState _mapAuthState(AuthState state) {
    final session = state.session;
    final userId = session?.user.id;
    if (userId == null || userId.isEmpty) {
      return const SessionSignedOut();
    }
    try {
      return SessionSignedIn(UserId.parse(userId));
    } on FormatException {
      return const SessionSignedOut();
    } on ArgumentError {
      return const SessionSignedOut();
    }
  }

  @override
  Future<Result<void, Failure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return const Ok<void, Failure>(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<void, Failure>> signInWithOAuth(
    AuthOAuthProvider provider,
  ) async {
    final oauth = switch (provider) {
      AuthOAuthProvider.google => OAuthProvider.google,
      AuthOAuthProvider.apple => OAuthProvider.apple,
    };
    try {
      final launched = await _client.auth.signInWithOAuth(oauth);
      if (!launched) {
        return const Err(AuthFailure());
      }
      return const Ok<void, Failure>(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Ok<void, Failure>(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<UserId?> getCurrentUserId() async {
    final id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      return null;
    }
    try {
      return UserId.parse(id);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}
