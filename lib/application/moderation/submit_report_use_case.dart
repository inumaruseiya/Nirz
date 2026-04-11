import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/value_objects/comment_id.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/report_target_type.dart';

/// 通報を検証して [ReportRepository] に保存する（Phase 10-2-3）。
final class SubmitReportUseCase {
  SubmitReportUseCase(this._reports);

  final ReportRepository _reports;

  static const int _maxReasonLength = 2000;

  Future<Result<void, Failure>> call(ReportSubmission submission) async {
    final reason = submission.reason.trim();
    if (reason.isEmpty) {
      return const Err(ValidationFailure('通報理由を入力してください。'));
    }
    if (reason.length > _maxReasonLength) {
      return Err(ValidationFailure('通報理由は $_maxReasonLength 文字以内にしてください。'));
    }

    try {
      switch (submission.targetType) {
        case ReportTargetType.post:
          PostId.parse(submission.targetId);
        case ReportTargetType.comment:
          CommentId.parse(submission.targetId);
      }
    } catch (_) {
      return const Err(ValidationFailure('無効な通報対象です。'));
    }

    return _reports.submitReport(
      ReportSubmission(
        targetType: submission.targetType,
        targetId: submission.targetId.trim().toLowerCase(),
        reason: reason,
      ),
    );
  }
}
