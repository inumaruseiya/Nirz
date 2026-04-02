import 'package:equatable/equatable.dart';

/// 投稿 ID（`posts.id` に対応する UUID）。
final class PostId extends Equatable {
  const PostId._(this.value);

  /// [raw] は非空の標準 UUID 文字列（ハイフン区切り 36 文字形式）。
  factory PostId.parse(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'PostId must be non-empty');
    }
    if (!_uuidPattern.hasMatch(v)) {
      throw FormatException('PostId must be a UUID string', raw);
    }
    return PostId._(v.toLowerCase());
  }

  final String value;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
