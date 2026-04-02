import 'package:equatable/equatable.dart';

/// 認証ユーザー ID（`auth.users.id` / `profiles.id` に対応する UUID）。
final class UserId extends Equatable {
  const UserId._(this.value);

  /// [raw] は非空の標準 UUID 文字列（ハイフン区切り 36 文字形式）。
  factory UserId.parse(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'UserId must be non-empty');
    }
    if (!_uuidPattern.hasMatch(v)) {
      throw FormatException('UserId must be a UUID string', raw);
    }
    return UserId._(v.toLowerCase());
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
