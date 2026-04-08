import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/services/location_obfuscation_service.dart';
import '../infrastructure/providers.dart';
import 'auth/request_password_reset_use_case.dart';
import 'auth/sign_in_with_email_use_case.dart';
import 'auth/sign_in_with_oauth_use_case.dart';
import 'auth/sign_out_use_case.dart';
import 'auth/sign_up_with_email_use_case.dart';
import 'auth/watch_session_use_case.dart';
import 'comments/add_comment_use_case.dart';
import 'comments/add_reply_use_case.dart';
import 'comments/load_comments_use_case.dart';
import 'feed/load_local_feed_use_case.dart';
import 'feed/load_more_feed_use_case.dart';
import 'feed/load_post_detail_use_case.dart';
import 'location/get_current_position_use_case.dart';
import 'location/obfuscate_location_use_case.dart';
import 'location/request_location_permission_use_case.dart';
import 'moderation/block_user_use_case.dart';
import 'moderation/submit_report_use_case.dart';
import 'posts/create_post_use_case.dart';
import 'posts/delete_post_use_case.dart';
import 'reactions/get_my_reaction_use_case.dart';
import 'reactions/remove_reaction_use_case.dart';
import 'reactions/submit_reaction_use_case.dart';

/// [LocationObfuscationService]（状態なし・ドメイン純粋ロジック）。
final locationObfuscationServiceProvider = Provider<LocationObfuscationService>(
  (ref) => LocationObfuscationService(),
);

// --- Auth (Phase 4-1) ---

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>(
  (ref) => SignInWithEmailUseCase(ref.watch(authRepositoryProvider)),
);

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>(
  (ref) => SignUpWithEmailUseCase(ref.watch(authRepositoryProvider)),
);

final signInWithOAuthUseCaseProvider = Provider<SignInWithOAuthUseCase>(
  (ref) => SignInWithOAuthUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final watchSessionUseCaseProvider = Provider<WatchSessionUseCase>(
  (ref) => WatchSessionUseCase(ref.watch(authRepositoryProvider)),
);

/// 現在の認証セッション（UI で「自分の投稿」判定などに利用）。
final sessionStateProvider = StreamProvider<SessionState>((ref) {
  return ref.watch(watchSessionUseCaseProvider)();
});

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>(
  (ref) => RequestPasswordResetUseCase(ref.watch(authRepositoryProvider)),
);

// --- Location (Phase 4-2) ---

final requestLocationPermissionUseCaseProvider =
    Provider<RequestLocationPermissionUseCase>(
  (ref) =>
      RequestLocationPermissionUseCase(ref.watch(locationRepositoryProvider)),
);

final getCurrentPositionUseCaseProvider = Provider<GetCurrentPositionUseCase>(
  (ref) => GetCurrentPositionUseCase(ref.watch(locationRepositoryProvider)),
);

final obfuscateLocationUseCaseProvider = Provider<ObfuscateLocationUseCase>(
  (ref) => ObfuscateLocationUseCase(
    ref.watch(locationObfuscationServiceProvider),
  ),
);

// --- Posts (Phase 4-3) ---

final createPostUseCaseProvider = Provider<CreatePostUseCase>(
  (ref) => CreatePostUseCase(
    ref.watch(postRepositoryProvider),
    ref.watch(storageRepositoryProvider),
    ref.watch(ngWordListRepositoryProvider),
  ),
);

final deletePostUseCaseProvider = Provider<DeletePostUseCase>(
  (ref) => DeletePostUseCase(ref.watch(postRepositoryProvider)),
);

// --- Feed (Phase 4-4) ---

final loadLocalFeedUseCaseProvider = Provider<LoadLocalFeedUseCase>(
  (ref) => LoadLocalFeedUseCase(
    ref.watch(feedRepositoryProvider),
    ref.watch(locationRepositoryProvider),
  ),
);

final loadMoreFeedUseCaseProvider = Provider<LoadMoreFeedUseCase>(
  (ref) => LoadMoreFeedUseCase(
    ref.watch(feedRepositoryProvider),
    ref.watch(locationRepositoryProvider),
  ),
);

final loadPostDetailUseCaseProvider = Provider<LoadPostDetailUseCase>(
  (ref) => LoadPostDetailUseCase(
    ref.watch(feedRepositoryProvider),
    ref.watch(locationRepositoryProvider),
  ),
);

// --- Reactions (Phase 4-5) ---

final submitReactionUseCaseProvider = Provider<SubmitReactionUseCase>(
  (ref) => SubmitReactionUseCase(ref.watch(reactionRepositoryProvider)),
);

final removeReactionUseCaseProvider = Provider<RemoveReactionUseCase>(
  (ref) => RemoveReactionUseCase(ref.watch(reactionRepositoryProvider)),
);

final getMyReactionUseCaseProvider = Provider<GetMyReactionUseCase>(
  (ref) => GetMyReactionUseCase(ref.watch(reactionRepositoryProvider)),
);

// --- Comments (Phase 4-6) ---

final loadCommentsUseCaseProvider = Provider<LoadCommentsUseCase>(
  (ref) => LoadCommentsUseCase(ref.watch(commentRepositoryProvider)),
);

final addCommentUseCaseProvider = Provider<AddCommentUseCase>(
  (ref) => AddCommentUseCase(
    ref.watch(commentRepositoryProvider),
    ref.watch(ngWordListRepositoryProvider),
  ),
);

final addReplyUseCaseProvider = Provider<AddReplyUseCase>(
  (ref) => AddReplyUseCase(
    ref.watch(commentRepositoryProvider),
    ref.watch(ngWordListRepositoryProvider),
  ),
);

// --- Moderation (Phase 10-2-3) ---

final submitReportUseCaseProvider = Provider<SubmitReportUseCase>(
  (ref) => SubmitReportUseCase(ref.watch(reportRepositoryProvider)),
);

final blockUserUseCaseProvider = Provider<BlockUserUseCase>(
  (ref) => BlockUserUseCase(
    ref.watch(blockRepositoryProvider),
    ref.watch(authRepositoryProvider),
  ),
);
