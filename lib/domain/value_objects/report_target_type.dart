import 'package:equatable/equatable.dart';

/// 通報対象の種別（`reports.target_type`、実装計画 Phase 10-2-3）。
enum ReportTargetType {
  post('post'),
  comment('comment');

  const ReportTargetType(this.storageValue);

  final String storageValue;
}

/// 通報 1 件の入力（UseCase へ渡す）。
final class ReportSubmission extends Equatable {
  const ReportSubmission({
    required this.targetType,
    required this.targetId,
    required this.reason,
  });

  final ReportTargetType targetType;

  /// 対象の UUID（投稿 ID またはコメント ID）。
  final String targetId;

  /// `reports.reason` に保存する文言（プリセット＋補足を含む）。
  final String reason;

  @override
  List<Object?> get props => [targetType, targetId, reason];
}
