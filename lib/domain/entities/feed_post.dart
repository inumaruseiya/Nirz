import 'package:equatable/equatable.dart';

import '../value_objects/obfuscated_location.dart';
import '../value_objects/post_id.dart';
import '../value_objects/user_id.dart';
import 'post.dart';

/// フィード一覧用の読み取りモデル（`Post` + RPC 集計・付帯情報）。
final class FeedPost extends Equatable {
  const FeedPost({
    required this.post,
    required this.reactionCount,
    this.authorName,
    this.distanceKm,
    this.commentCount,
  });

  final Post post;
  final int reactionCount;
  final String? authorName;

  /// 閲覧者クエリ地点からのおおよその距離（km）。取得できない場合は null。
  final double? distanceKm;

  /// コメント件数（`get_post_detail` 等で付与。フィード一覧では null）。
  final int? commentCount;

  PostId get id => post.id;
  UserId get authorId => post.authorId;
  String get content => post.content;
  Uri? get imageUrl => post.imageUrl;
  ObfuscatedLocation get location => post.location;
  DateTime get createdAt => post.createdAt;
  DateTime get expiresAt => post.expiresAt;
  bool get isExpired => post.isExpired;

  @override
  List<Object?> get props =>
      [post, reactionCount, authorName, distanceKm, commentCount];
}
