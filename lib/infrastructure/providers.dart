import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/comment_repository.dart';
import '../domain/repositories/feed_repository.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/post_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/reaction_repository.dart';
import '../domain/repositories/storage_repository.dart';
import 'location/geolocator_location_repository.dart';
import 'supabase/supabase_auth_repository.dart';
import 'supabase/supabase_comment_repository.dart';
import 'supabase/supabase_feed_repository.dart';
import 'supabase/supabase_post_repository.dart';
import 'supabase/supabase_profile_repository.dart';
import 'supabase/supabase_reaction_repository.dart';
import 'supabase/supabase_storage_repository.dart';

/// アプリ全体で共有する [SupabaseClient]。
///
/// [Supabase.initialize] 済みであること（`main.dart` の `--dart-define` 設定を参照）。
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// [AuthRepository] → [SupabaseAuthRepository]
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

/// [ProfileRepository] → [SupabaseProfileRepository]
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

/// [PostRepository] → [SupabasePostRepository]
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => SupabasePostRepository(ref.watch(supabaseClientProvider)),
);

/// [FeedRepository] → [SupabaseFeedRepository]
final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => SupabaseFeedRepository(ref.watch(supabaseClientProvider)),
);

/// [ReactionRepository] → [SupabaseReactionRepository]
final reactionRepositoryProvider = Provider<ReactionRepository>(
  (ref) => SupabaseReactionRepository(ref.watch(supabaseClientProvider)),
);

/// [CommentRepository] → [SupabaseCommentRepository]
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => SupabaseCommentRepository(ref.watch(supabaseClientProvider)),
);

/// [StorageRepository] → [SupabaseStorageRepository]
final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => SupabaseStorageRepository(ref.watch(supabaseClientProvider)),
);

/// [LocationRepository] → [GeolocatorLocationRepository]（Phase 3-4-1）
final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => const GeolocatorLocationRepository(),
);
