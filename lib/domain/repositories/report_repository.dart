import '../core/failure.dart';
import '../core/result.dart';
import '../value_objects/report_target_type.dart';

/// 通報の永続化（実装計画 Phase 10-2-3、FR-MOD-02）。
abstract interface class ReportRepository {
  Future<Result<void, Failure>> submitReport(ReportSubmission submission);
}
