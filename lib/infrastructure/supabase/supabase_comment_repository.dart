import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/value_objects/comment_id.dart';
import '../../domain/value_objects/post_id.dart';
import '../dto/comment_dto.dart';
import '../mappers/comment_mapper.dart';
import 'postgrest_failure_mapper.dart';

/// [CommentRepository] の Supabase 実装（`comments` テーブル）。
final class SupabaseCommentRepository implements CommentRepository {
  SupabaseCommentRepository(this._client);

  final SupabaseClient _client;

  static const _selectColumns =
      'id, post_id, user_id, parent_comment_id, content, created_at';

  @override
  Future<Result<List<Comment>, Failure>> listByPost(PostId postId) async {
    if (_client.auth.currentUser == null) {
      return const Err(AuthFailure());
    }
    try {
      final rows = await _client
          .from('comments')
          .select(_selectColumns)
          .eq('post_id', postId.value)
          .order('created_at', ascending: true);
      final out = <Comment>[];
      for (final row in rows) {
        try {
          final dto = CommentDto.fromJson(
            Map<String, dynamic>.from(row as Map),
          );
          out.add(CommentMapper.toDomain(dto));
        } on FormatException catch (e) {
          return Err(ValidationFailure(e.message));
        }
      }
      return Ok(out);
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(mapPostgrestException(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<Comment, Failure>> addComment({
    required PostId postId,
    required String content,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      final row = await _client
          .from('comments')
          .insert({
            'post_id': postId.value,
            'user_id': uid,
            'content': content,
            'parent_comment_id': null,
          })
          .select(_selectColumns)
          .single();
      final dto = CommentDto.fromJson(Map<String, dynamic>.from(row));
      return Ok(CommentMapper.toDomain(dto));
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(mapPostgrestException(e));
    } on FormatException catch (e) {
      return Err(ValidationFailure(e.message));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<Comment, Failure>> addReply({
    required PostId postId,
    required CommentId parentId,
    required String content,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }
    try {
      final row = await _client
          .from('comments')
          .insert({
            'post_id': postId.value,
            'user_id': uid,
            'content': content,
            'parent_comment_id': parentId.value,
          })
          .select(_selectColumns)
          .single();
      final dto = CommentDto.fromJson(Map<String, dynamic>.from(row));
      return Ok(CommentMapper.toDomain(dto));
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(mapPostgrestException(e));
    } on FormatException catch (e) {
      return Err(ValidationFailure(e.message));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }
}
