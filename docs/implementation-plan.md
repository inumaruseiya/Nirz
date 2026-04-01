# ローカルSNS 実装計画書（Phase別タスク一覧）

| 項目 | 内容 |
|------|------|
| 文書名 | ローカルSNS 実装計画書 |
| 対象 | Flutter（nirz）+ Supabase |
| 版数 | 1.0 |
| 作成日 | 2026-04-01 |
| 参照文書 | [要件定義書](./requirements-local-sns-flutter-supabase.md) / [全体設計書](./system-design-local-sns-flutter-supabase.md) / [詳細設計書](./detailed-design-local-sns-flutter-supabase.md) |

---

## フェーズ構成（概要）

| Phase | テーマ | 主な成果物 | 優先度 |
|-------|--------|-----------|--------|
| **Phase 0** | 環境構築・プロジェクト骨格 | `pubspec.yaml` 更新、ディレクトリ構造、DI 基盤 | 必須 |
| **Phase 1** | Supabase バックエンド（DDL・RLS・RPC） | マイグレーション SQL、RPC、RLS ポリシー | 必須 |
| **Phase 2** | Domain 層 | 値オブジェクト・エンティティ・Failure 型・Repository 抽象 | 必須 |
| **Phase 3** | Infrastructure 層 | Supabase 具象 Repository・DTO・Mapper | 必須 |
| **Phase 4** | Application 層（UseCase） | ユースケース・ObfuscateLocation | 必須 |
| **Phase 5** | 認証（FR-AUTH） | ログイン・サインアップ・セッション復元 | 必須 |
| **Phase 6** | ローカルフィード（FR-FEED） | フィード画面・RPC 連携・ページング | 必須 |
| **Phase 7** | 投稿作成（FR-POST・FR-LOC） | 投稿画面・位置ぼかし・Storage 画像アップロード | 必須 |
| **Phase 8** | リアクション（FR-REACT） | 詳細画面リアクション UI・UPSERT | 必須 |
| **Phase 9** | コメント（FR-COMMENT） | コメントスレッド・1 階層返信 | MVP 後 |
| **Phase 10** | テスト | Domain UT・UseCase UT・Widget テスト | 必須 |
| **Phase 11** | モデレーション・通報・ブロック（FR-MOD） | 通報テーブル・ブロック機能 | MVP 後 |
| **Phase 12** | 非機能・仕上げ | パフォーマンス・アクセシビリティ・セキュリティ監査 | 必須（リリース前） |

---

## Phase 0: 環境構築・プロジェクト骨格

> **目標**: 全レイヤのディレクトリ骨格を揃え、依存パッケージと DI 基盤を整える。デモカウンターアプリを消去してクリーンな起動画面にする。

### 0-1. パッケージ追加（`pubspec.yaml`）

- [ ] `supabase_flutter` を追加（Supabase Auth / DB / Storage / Realtime）
- [ ] `geolocator` を追加（位置情報取得）
- [ ] `riverpod` または `flutter_bloc` を追加（状態管理。プロジェクトで統一）
  - 推奨: `flutter_riverpod` + `riverpod_annotation`（コード生成でボイラープレート削減）
- [ ] `go_router` を追加（ルーティング）
- [ ] `equatable` を追加（値オブジェクトの等値比較）
- [ ] `image_picker` を追加（投稿画像選択）
- [ ] `cached_network_image` を追加（フィードサムネイルキャッシュ）
- [ ] `freezed` / `freezed_annotation` を追加（不変クラス生成。任意だが推奨）
- [ ] `json_annotation` + `json_serializable` を追加（DTO の JSON シリアライズ）
- [ ] `build_runner` を dev に追加
- [ ] `flutter_riverpod_lint` または `flutter_lints` を最新版に更新
- [ ] `flutter pub get` と `dart pub run build_runner build` が通ることを確認

### 0-2. ディレクトリ構造の作成

全体設計書 §2 に従い、以下のディレクトリを `lib/` 配下に作成する。

```
lib/
├── main.dart                    # 書き換え（Supabase 初期化・DI・ルート設定）
├── app.dart                     # MaterialApp / Router 設定
├── core/
│   └── di/
│       └── providers.dart       # Riverpod グローバル Provider
├── domain/
│   ├── core/
│   │   └── failure.dart         # sealed class Failure
│   ├── entities/
│   │   ├── profile.dart
│   │   ├── post.dart
│   │   ├── feed_post.dart
│   │   ├── reaction.dart
│   │   └── comment.dart
│   ├── value_objects/
│   │   ├── user_id.dart
│   │   ├── post_id.dart
│   │   ├── comment_id.dart
│   │   ├── geo_coordinate.dart
│   │   ├── obfuscated_location.dart
│   │   ├── reaction_type.dart
│   │   ├── feed_radius_meters.dart
│   │   └── post_ttl.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── location_repository.dart
│       ├── post_repository.dart
│       ├── feed_repository.dart
│       ├── reaction_repository.dart
│       ├── comment_repository.dart
│       ├── profile_repository.dart
│       └── storage_repository.dart
├── application/
│   ├── auth/
│   │   └── sign_in_use_case.dart
│   ├── location/
│   │   └── obfuscate_location_use_case.dart
│   ├── posts/
│   │   └── create_post_use_case.dart
│   ├── feed/
│   │   └── load_local_feed_use_case.dart
│   ├── reactions/
│   │   └── submit_reaction_use_case.dart
│   └── comments/
│       ├── list_comments_use_case.dart
│       └── add_comment_use_case.dart
├── infrastructure/
│   ├── supabase/
│   │   ├── supabase_auth_repository.dart
│   │   ├── supabase_post_repository.dart
│   │   ├── supabase_feed_repository.dart
│   │   ├── supabase_reaction_repository.dart
│   │   ├── supabase_comment_repository.dart
│   │   ├── supabase_profile_repository.dart
│   │   └── supabase_storage_repository.dart
│   ├── location/
│   │   └── geolocator_location_repository.dart
│   └── dto/
│       ├── post_dto.dart
│       ├── rpc_feed_item_dto.dart
│       ├── reaction_dto.dart
│       └── comment_dto.dart
└── presentation/
    ├── router.dart              # go_router 定義
    ├── auth/
    │   ├── login_page.dart
    │   └── login_notifier.dart
    ├── feed/
    │   ├── feed_page.dart
    │   ├── feed_notifier.dart
    │   └── widgets/
    │       ├── local_post_card.dart
    │       └── distance_label.dart
    ├── compose/
    │   ├── compose_page.dart
    │   └── compose_notifier.dart
    ├── detail/
    │   ├── detail_page.dart
    │   ├── detail_notifier.dart
    │   └── widgets/
    │       ├── reaction_picker.dart
    │       └── comment_thread.dart
    ├── settings/
    │   └── settings_page.dart
    └── shared/
        ├── async_state_switcher.dart
        └── location_permission_callout.dart
```

- [ ] 上記ディレクトリを `lib/` に全作成（空ファイル `.gitkeep` で構造確定）
- [ ] `lib/main.dart` のデモカウンターコードを削除し、Supabase 初期化コードの骨格に置き換え

### 0-3. Supabase プロジェクト設定

- [ ] Supabase Dashboard でプロジェクト作成（またはローカル CLI `supabase init` ）
- [ ] `supabase_flutter` 初期化用の URL / anon key を `.env` または `--dart-define` で管理
  - **git に直接コミットしない**（`.gitignore` に `.env` を追加済みか確認）
- [ ] `lib/main.dart` に `Supabase.initialize(url:, anonKey:)` を追加

### 0-4. Supabase CLI / Migration 管理フロー確立

- [ ] `supabase CLI` のインストール確認（`supabase --version`）
- [ ] `supabase/migrations/` ディレクトリの作成
- [ ] Migration 作成コマンド（`supabase migration new <名前>`）の確認

---

## Phase 1: Supabase バックエンド（DDL・RLS・RPC）

> **目標**: PostgreSQL + PostGIS の完全 DDL と RLS ポリシー、RPC 関数を Migration として管理し、ローカル Supabase またはステージングで動作確認する。

### 1-1. PostgreSQL 拡張の有効化

```sql
-- マイグレーション: 001_enable_extensions.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
```

- [ ] `uuid-ossp` 有効化（`uuid_generate_v4()` 利用）
- [ ] `postgis` 有効化（`geography` 型・`ST_DWithin` 利用）

### 1-2. `profiles` テーブルの作成

```sql
-- マイグレーション: 002_create_profiles.sql
CREATE TABLE public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        text,
  avatar_url  text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
```

- [ ] `profiles` テーブル作成
- [ ] `auth.users` 新規作成時に `profiles` 行を自動挿入するトリガの作成
  ```sql
  CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
  BEGIN
    INSERT INTO public.profiles (id, name)
    VALUES (new.id, new.raw_user_meta_data->>'name');
    RETURN new;
  END;
  $$;

  CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
  ```
- [ ] RLS 有効化: `ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;`
- [ ] RLS ポリシー:
  - `SELECT`: 認証ユーザーは全プロフィールを閲覧可
  - `INSERT`: 自分の `id` のみ
  - `UPDATE`: 自分の `id` のみ

### 1-3. `posts` テーブルの作成

```sql
-- マイグレーション: 003_create_posts.sql
CREATE TABLE public.posts (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     text NOT NULL,
  image_url   text,
  location    geography(Point, 4326) NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  expires_at  timestamptz NOT NULL
);

CREATE INDEX idx_posts_location ON public.posts USING GIST (location);
CREATE INDEX idx_posts_expires_at ON public.posts (expires_at);
CREATE INDEX idx_posts_created_at ON public.posts (created_at DESC);
```

- [ ] `posts` テーブル作成（`geography(Point,4326)` 型の `location` 含む）
- [ ] GiST インデックス `idx_posts_location` 作成（NFR-SCALE-02 必須）
- [ ] `expires_at`、`created_at` にインデックス追加（クエリ性能）
- [ ] RLS 有効化
- [ ] RLS ポリシー:
  - `SELECT`: 認証ユーザーは読み取り可（地理・TTL フィルタは RPC 内で強制）
  - `INSERT`: `auth.uid() = user_id` のみ
  - `DELETE`: `auth.uid() = user_id` のみ（NFR-SEC-02）

### 1-4. `reactions` テーブルの作成

```sql
-- マイグレーション: 004_create_reactions.sql
CREATE TYPE public.reaction_type AS ENUM ('like', 'look', 'fire');

CREATE TABLE public.reactions (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id     uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  type        public.reaction_type NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, post_id)
);
```

- [ ] `reaction_type` enum 作成（`like`, `look`, `fire`）
- [ ] `reactions` テーブル作成
- [ ] `UNIQUE (user_id, post_id)` 制約確認（FR-REACT-02）
- [ ] RLS 有効化
- [ ] RLS ポリシー:
  - `SELECT`: 認証ユーザーは読み取り可
  - `INSERT`: `auth.uid() = user_id` のみ
  - `UPDATE`: `auth.uid() = user_id` のみ（upsert 用）
  - `DELETE`: `auth.uid() = user_id` のみ

### 1-5. `comments` テーブルの作成

```sql
-- マイグレーション: 005_create_comments.sql
CREATE TABLE public.comments (
  id                  uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id             uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  parent_comment_id   uuid REFERENCES public.comments(id) ON DELETE CASCADE,
  content             text NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_post_id ON public.comments (post_id);
```

- [ ] `comments` テーブル作成（`parent_comment_id` NULL 許容・1 階層ネスト用）
- [ ] `post_id` インデックス追加
- [ ] RLS 有効化
- [ ] RLS ポリシー:
  - `SELECT`: 認証ユーザーは読み取り可
  - `INSERT`: `auth.uid() = user_id` のみ
  - `DELETE`: `auth.uid() = user_id` のみ

### 1-6. Storage バケットの設定

- [ ] `post-images` バケット作成（Supabase Dashboard または SQL）
- [ ] バケットポリシー:
  - `SELECT`（公開 or 署名 URL）: 認証ユーザーが読み取り可
  - `INSERT`: 認証ユーザーが自分のパス（`{userId}/...`）にのみアップロード可
  - `DELETE`: `{userId}` と `auth.uid()` が一致する場合のみ（NFR-SEC-03）

### 1-7. RPC: `get_local_feed` の作成

```sql
-- マイグレーション: 006_rpc_get_local_feed.sql
CREATE OR REPLACE FUNCTION public.get_local_feed(
  lat      double precision,
  lng      double precision,
  lim      int DEFAULT 20,
  cursor_created_at timestamptz DEFAULT NULL,
  cursor_id         uuid         DEFAULT NULL,
  sort_mode text DEFAULT 'new'
)
RETURNS TABLE (
  id           uuid,
  user_id      uuid,
  content      text,
  image_url    text,
  lat_blurred  double precision,
  lng_blurred  double precision,
  created_at   timestamptz,
  expires_at   timestamptz,
  reaction_count bigint,
  author_name  text
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    p.id,
    p.user_id,
    p.content,
    p.image_url,
    ST_Y(p.location::geometry) AS lat_blurred,
    ST_X(p.location::geometry) AS lng_blurred,
    p.created_at,
    p.expires_at,
    COUNT(r.id) AS reaction_count,
    pr.name AS author_name
  FROM public.posts p
  LEFT JOIN public.reactions r ON r.post_id = p.id
  LEFT JOIN public.profiles pr ON pr.id = p.user_id
  WHERE ST_DWithin(
    p.location,
    ST_MakePoint(lng, lat)::geography,
    5000
  )
  AND p.expires_at > now()
  AND (
    cursor_created_at IS NULL
    OR (p.created_at, p.id) < (cursor_created_at, cursor_id)
  )
  GROUP BY p.id, pr.name
  ORDER BY
    CASE WHEN sort_mode = 'popular' THEN COUNT(r.id) END DESC NULLS LAST,
    p.created_at DESC,
    p.id DESC
  LIMIT lim;
$$;
```

- [ ] `get_local_feed` RPC 作成
  - パラメータ: `lat`, `lng`, `lim`, `cursor_created_at`, `cursor_id`, `sort_mode`
  - 出力: 投稿行 + `reaction_count` + `author_name`
  - `ST_DWithin(..., 5000)` で 5km 以内に限定（FR-FEED-01）
  - `expires_at > now()` で TTL 切れを除外（FR-POST-01）
  - カーソルページング（`(created_at, id) < (cursor, cursor_id)`）
  - `sort_mode = 'popular'` は MVP 後に有効化してよい
- [ ] `SECURITY DEFINER` で RLS をバイパスして安全に実行（RPC 内でフィルタ強制）
- [ ] `GRANT EXECUTE ON FUNCTION public.get_local_feed TO authenticated;`

### 1-8. RPC: `create_post` の作成（推奨）

```sql
-- マイグレーション: 007_rpc_create_post.sql
CREATE OR REPLACE FUNCTION public.create_post(
  content       text,
  lat_blurred   double precision,
  lng_blurred   double precision,
  image_url     text DEFAULT NULL
)
RETURNS public.posts LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_post public.posts;
BEGIN
  INSERT INTO public.posts (user_id, content, image_url, location, expires_at)
  VALUES (
    auth.uid(),
    content,
    image_url,
    ST_MakePoint(lng_blurred, lat_blurred)::geography,
    now() + interval '24 hours'
  )
  RETURNING * INTO new_post;
  RETURN new_post;
END;
$$;
```

- [ ] `create_post` RPC 作成
  - `expires_at = now() + 24h` をサーバ側で強制（FR-POST-01）
  - `lat_blurred`, `lng_blurred` のみ受け付け、**正確座標は受け取らない**（FR-LOC-02）
  - `auth.uid()` で `user_id` を自動設定
- [ ] `GRANT EXECUTE ON FUNCTION public.create_post TO authenticated;`

### 1-9. Migration の適用・動作確認

- [ ] `supabase db reset` または `supabase migration up` でローカル DB に適用
- [ ] `supabase studio` または psql で各テーブル・RPC の動作確認
- [ ] `get_local_feed` に対して `EXPLAIN ANALYZE` を実行し、GiST インデックスが使われていることを確認

---

## Phase 2: Domain 層

> **目標**: Flutter / Supabase に依存しない純粋な型・インターフェースを実装する。テストが書けるレベルの完成度にする。

### 2-1. `Failure` sealed class の実装

ファイル: `lib/domain/core/failure.dart`

- [ ] `sealed class Failure` を定義
- [ ] `final class NetworkFailure extends Failure` を追加
- [ ] `final class AuthFailure extends Failure` を追加
- [ ] `final class ValidationFailure extends Failure` を追加（`message` フィールド付き）
- [ ] `final class NotFoundFailure extends Failure` を追加（任意）
- [ ] `final class ServerFailure extends Failure` を追加（Supabase エラー汎用）

### 2-2. `Result` 型の定義

ファイル: `lib/domain/core/result.dart`

- [ ] `typedef Result<T, E> = ({T? value, E? error})` または `sealed class Result<T>` のどちらかで統一
  - 推奨: `package:fpdart` の `Either` または自前 `sealed class`
- [ ] 全ユースケースの戻り値型として `Future<Result<T, Failure>>` を使用することを決定

### 2-3. 値オブジェクトの実装

各値オブジェクトは **不変**・**等値比較可能**（`Equatable` または `==` オーバーライド）とする。

- [ ] `UserId` — `String` UUID をラップ。空文字禁止の factory 検証
- [ ] `PostId` — 同上
- [ ] `CommentId` — 同上
- [ ] `GeoCoordinate` — `latitude`, `longitude` の `double`。範囲検証（-90〜90, -180〜180）
  - コメント: 「このオブジェクトはサーバに直接送信しない。ぼかし後のみ送信可能」と明記
- [ ] `ObfuscatedLocation` — `GeoCoordinate` をラップしたブランド型。「ぼかし済みのみ永続化可」を表現
- [ ] `ReactionType` — `enum`（`like`, `look`, `fire`）
  - `fromString` factory（不明値は `null` または例外）
  - `toDbString` getter（DB の text 値へマッピング）
- [ ] `FeedRadiusMeters` — `const double value = 5000` をラップした const クラス
- [ ] `PostTtl` — `const Duration value = Duration(hours: 24)` をラップ

### 2-4. エンティティの実装

- [ ] `Profile` — `UserId id`, `String? displayName`, `DateTime createdAt`
  - `copyWith` を実装（`freezed` または手動）
- [ ] `Post` — `PostId id`, `UserId authorId`, `String content`, `Uri? imageUrl`, `ObfuscatedLocation location`, `DateTime createdAt`, `DateTime expiresAt`
  - `bool get isExpired => DateTime.now().isAfter(expiresAt)` メソッドを実装
- [ ] `FeedPost` — `Post post`, `int reactionCount`, `String? authorName`, `double distanceKm`
  - `distanceKm` は Presentation 用（RPC 結果から計算または提供）
- [ ] `Reaction` — `UserId userId`, `PostId postId`, `ReactionType type`, `DateTime createdAt`
- [ ] `Comment` — `CommentId id`, `PostId postId`, `UserId authorId`, `CommentId? parentId`, `String content`, `DateTime createdAt`
  - `bool get isTopLevel => parentId == null`

### 2-5. Repository インターフェースの実装

各 `abstract interface class` に対し、Dart doc コメントでメソッドの意味を明記する。

- [ ] `AuthRepository`
  - `Stream<AuthState> watchSession()`
  - `Future<Result<void, Failure>> signInWithEmail({required String email, required String password})`
  - `Future<void> signOut()`
  - `UserId? get currentUserId`
- [ ] `LocationRepository`
  - `Future<LocationPermissionStatus> requestPermission()`
  - `Future<GeoCoordinate> getCurrentPosition()`
  - `bool get isPermissionGranted`
- [ ] `PostRepository`
  - `Future<Result<Post, Failure>> createPost({required ObfuscatedLocation location, required String content, Uri? imageUrl})`
  - `Future<Result<void, Failure>> deletePost(PostId postId)`
- [ ] `FeedRepository`
  - `Future<Result<List<FeedPost>, Failure>> fetchFeed({required GeoCoordinate queryPoint, FeedCursor? cursor, FeedSort sort = FeedSort.newest})`
  - ※ `FeedCursor`（`createdAt` + `id`）・`FeedSort`（`enum`）も Domain に定義
- [ ] `ReactionRepository`
  - `Future<Result<void, Failure>> upsertReaction({required PostId postId, required ReactionType type})`
  - `Future<Result<void, Failure>> deleteReaction(PostId postId)`
- [ ] `CommentRepository`
  - `Future<Result<List<Comment>, Failure>> listByPost(PostId postId)`
  - `Future<Result<Comment, Failure>> addComment({required PostId postId, required String content, CommentId? parentId})`
- [ ] `ProfileRepository`
  - `Future<Result<Profile, Failure>> getCurrentProfile()`
  - `Future<Result<void, Failure>> updateProfile({String? displayName})`
- [ ] `StorageRepository`
  - `Future<Result<Uri, Failure>> uploadPostImage(Uint8List bytes, String contentType)`

---

## Phase 3: Infrastructure 層

> **目標**: Supabase SDK・geolocator を使った具象 Repository と DTO / Mapper を実装する。Domain インターフェースを満たすことを `implements` で強制する。

### 3-1. Supabase クライアントの注入設定

ファイル: `lib/core/di/providers.dart`

- [ ] `SupabaseClient` を Riverpod Provider として定義
  ```dart
  final supabaseClientProvider = Provider<SupabaseClient>(
    (ref) => Supabase.instance.client,
  );
  ```
- [ ] 各 Repository の Provider を定義（`SupabaseAuthRepository` etc.）

### 3-2. DTO の実装

- [ ] `PostDto` — `fromJson(Map<String, dynamic>)` / `toInsertMap()` を実装
  - `created_at`, `expires_at` は UTC `DateTime` として `parse`
- [ ] `RpcFeedItemDto` — `get_local_feed` RPC の 1 行をマップ
  - フィールド: `id`, `user_id`, `content`, `image_url`, `lat_blurred`, `lng_blurred`, `created_at`, `expires_at`, `reaction_count`, `author_name`
- [ ] `ReactionDto` — `fromJson` / `toMap`
- [ ] `CommentDto` — `fromJson` / `toMap`

### 3-3. Mapper の実装

- [ ] `PostMapper`
  - `FeedPost fromRpcItem(RpcFeedItemDto dto, GeoCoordinate queryPoint)`
    - `ObfuscatedLocation` を `GeoCoordinate(dto.latBlurred, dto.lngBlurred)` から構築
    - `distanceKm` は `GeoCoordinate.distanceTo(queryPoint)` で計算（Haversine 等）
  - `Post fromDto(PostDto dto)`
- [ ] `CommentMapper`
  - `Comment fromDto(CommentDto dto)`
- [ ] `ReactionMapper`
  - `Reaction fromDto(ReactionDto dto)`

### 3-4. `GeolocatorLocationRepository` の実装

ファイル: `lib/infrastructure/location/geolocator_location_repository.dart`

- [ ] `LocationRepository` を `implements`
- [ ] `requestPermission()`: `Geolocator.requestPermission()` を呼び、`LocationPermissionStatus` に変換
- [ ] `getCurrentPosition()`: `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)` → `GeoCoordinate` に変換
- [ ] `isPermissionGranted`: `Geolocator.checkPermission()` の結果をキャッシュ

### 3-5. `SupabaseAuthRepository` の実装

- [ ] `AuthRepository` を `implements`
- [ ] `watchSession()`: `supabaseClient.auth.onAuthStateChange` を `Stream` に変換
- [ ] `signInWithEmail()`: `supabaseClient.auth.signInWithPassword(email:, password:)`、失敗を `AuthFailure` に変換
- [ ] `signOut()`: `supabaseClient.auth.signOut()`
- [ ] `currentUserId`: `supabaseClient.auth.currentUser?.id` を `UserId` にラップ

### 3-6. `SupabasePostRepository` の実装

- [ ] `PostRepository` を `implements`
- [ ] `createPost()`: `rpc('create_post', params: {lat_blurred, lng_blurred, content, image_url})` を呼び出し
  - ネットワークエラー → `NetworkFailure`
  - Supabase エラー → `ServerFailure`
- [ ] `deletePost()`: `from('posts').delete().eq('id', postId.value)` を実行
  - RLS により本人のみ削除可

### 3-7. `SupabaseFeedRepository` の実装

- [ ] `FeedRepository` を `implements`
- [ ] `fetchFeed()`: `rpc('get_local_feed', params: {lat, lng, lim, cursor_created_at, cursor_id, sort_mode})` を呼び出し
- [ ] レスポンスを `List<RpcFeedItemDto>` にデシリアライズ → `PostMapper.fromRpcItem` で `FeedPost` に変換
- [ ] 次ページカーソルを戻り値に含める（`FeedCursor?`）

### 3-8. `SupabaseReactionRepository` の実装

- [ ] `ReactionRepository` を `implements`
- [ ] `upsertReaction()`: `from('reactions').upsert({user_id, post_id, type}, onConflict: 'user_id,post_id')` を実行
- [ ] `deleteReaction()`: `from('reactions').delete().eq('user_id', uid).eq('post_id', postId.value)` を実行

### 3-9. `SupabaseCommentRepository` の実装

- [ ] `CommentRepository` を `implements`
- [ ] `listByPost()`: `from('comments').select('*, profiles(name)').eq('post_id', postId.value).order('created_at')` を実行
- [ ] `addComment()`: INSERT。`parent_comment_id` の階層チェック（2 階層目以降は `ValidationFailure`）

### 3-10. `SupabaseProfileRepository` の実装

- [ ] `ProfileRepository` を `implements`
- [ ] `getCurrentProfile()`: `from('profiles').select().eq('id', uid).single()` を実行
- [ ] `updateProfile()`: `from('profiles').update({name: displayName}).eq('id', uid)` を実行

### 3-11. `SupabaseStorageRepository` の実装

- [ ] `StorageRepository` を `implements`
- [ ] `uploadPostImage()`: `storage.from('post-images').uploadBinary('{uid}/{uuid}.jpg', bytes)` を実行
- [ ] アップロード後に公開 URL または署名 URL を `Uri` で返す

---

## Phase 4: Application 層（UseCase）

> **目標**: ユースケースクラスを実装し、ビジネスロジックをレイヤに集約する。Repository はモック可能な形で注入する。

### 4-1. `ObfuscateLocationUseCase` の実装

ファイル: `lib/application/location/obfuscate_location_use_case.dart`

- [ ] 入力: `GeoCoordinate rawCoordinate`
- [ ] 処理:
  1. ランダムな方位角（0〜360°）と距離（300m〜1000m）を生成
  2. WGS84 上で目標座標を計算（`Haversine` の逆算または簡易直交近似）
  3. 生成した座標で `GeoCoordinate` を作成し `ObfuscatedLocation` にラップ
- [ ] 出力: `ObfuscatedLocation`
- [ ] 単体テストを書ける形にする（オフセット距離が 300m〜1000m 内に収まること）

### 4-2. `CreatePostUseCase` の実装

- [ ] コンストラクタ: `LocationRepository`, `StorageRepository`, `PostRepository`, `ObfuscateLocationUseCase` を DI
- [ ] `call({required String content, Uint8List? imageBytes, String? imageContentType})` を実装
  1. `LocationRepository.getCurrentPosition()` で生座標を取得
  2. `ObfuscateLocationUseCase` でぼかし
  3. 画像があれば `StorageRepository.uploadPostImage()` でアップロード → `Uri` 取得
  4. `PostRepository.createPost(location, content, imageUrl)` を呼び出し
- [ ] 失敗時は適切な `Failure` を返す（位置権限なし → `ValidationFailure`）

### 4-3. `LoadLocalFeedUseCase` の実装

- [ ] コンストラクタ: `LocationRepository`, `FeedRepository` を DI
- [ ] `call({FeedCursor? cursor, FeedSort sort = FeedSort.newest})` を実装
  1. 位置権限確認
  2. `LocationRepository.getCurrentPosition()` でクエリ用座標を取得（**永続化しない**）
  3. `FeedRepository.fetchFeed(queryPoint, cursor, sort)` を呼び出し
- [ ] 位置オフ時は `ValidationFailure` を返す（FR-LOC-04）

### 4-4. `SubmitReactionUseCase` の実装

- [ ] コンストラクタ: `ReactionRepository` を DI
- [ ] `call({required PostId postId, required ReactionType type})`: `upsertReaction` を呼び出し

### 4-5. `AddCommentUseCase` の実装

- [ ] コンストラクタ: `CommentRepository` を DI
- [ ] `call({required PostId postId, required String content, CommentId? parentId})`:
  - `content` の空チェック → `ValidationFailure`
  - `CommentRepository.addComment()` を呼び出し

### 4-6. `ListCommentsUseCase` の実装

- [ ] `call(PostId postId)`: `CommentRepository.listByPost(postId)` を呼び出し

### 4-7. `SignInUseCase` / `SignUpUseCase` の実装

- [ ] `SignInUseCase.call({email, password})`: `AuthRepository.signInWithEmail()`
- [ ] `SignUpUseCase.call({email, password})`: `AuthRepository.signUp()` を追加（`AuthRepository` に `signUp` メソッドを追記）

---

## Phase 5: 認証（FR-AUTH）

> **目標**: ログイン・登録・セッション復元の UI と状態を実装する。HIG §2.1「コントロール」の原則でエラーをフィールド近傍に表示する。

### 5-1. スプラッシュ / セッション確認

ファイル: `lib/presentation/router.dart`, `lib/main.dart`

- [ ] アプリ起動時に `AuthRepository.watchSession()` を listen
- [ ] セッションあり → ホーム（`/feed`）、セッションなし → ログイン（`/login`）にリダイレクト
- [ ] `go_router` の `redirect` 機能を使ってガードを実装

### 5-2. ログイン画面 UI

ファイル: `lib/presentation/auth/login_page.dart`

- [ ] メールフォーム `TextField` + パスワード `TextField`（マスキング・表示トグル）
- [ ] 「ログイン」ボタン（送信中は `CircularProgressIndicator` に切り替え）
- [ ] OAuth ボタン（`signInWithOAuth` 実装は任意。MVP は Email のみでも可）
- [ ] エラーはフィールド近傍または `SnackBar` で表示
- [ ] パスワード再設定導線（`supabase.auth.resetPasswordForEmail`）
- [ ] 新規登録への切り替え

### 5-3. `LoginNotifier` の実装

- [ ] `state`: `LoginState`（`initial`, `loading`, `success`, `error(message)`）
- [ ] `signIn(email, password)`: `SignInUseCase.call()` → 結果に応じて state 更新
- [ ] エラー文言は `Failure` マッパー経由

### 5-4. 認証後のプロフィール初回設定（任意）

- [ ] 初回ログイン時にニックネーム入力を促すボトムシートまたはダイアログ
- [ ] `ProfileRepository.updateProfile(displayName: input)` を呼び出し

---

## Phase 6: ローカルフィード（FR-FEED）

> **目標**: ホーム画面にリアルタイムに近いフィードを表示する。新着順・カーソルページング・Pull-to-refresh を実装する。

### 6-1. `FeedNotifier` / `FeedState` の実装

ファイル: `lib/presentation/feed/feed_notifier.dart`

- [ ] `FeedState` を定義: `initial`, `loading`, `ready(posts, nextCursor)`, `empty`, `locationDenied`, `error(message)`
- [ ] `loadFeed()`: `LoadLocalFeedUseCase.call()` → state 更新
- [ ] `loadMore(cursor)`: 追加ロード
- [ ] `refresh()`: カーソルをリセットして再取得
- [ ] 位置権限なし → `locationDenied` 状態に遷移

### 6-2. フィード画面 UI

ファイル: `lib/presentation/feed/feed_page.dart`

- [ ] `CustomScrollView` + `SliverAppBar`（タイトル「近くの投稿」）
- [ ] `AsyncStateSwitcher` で各状態（ロード・空・エラー・位置オフ）を切り替え
- [ ] `RefreshIndicator` で Pull-to-refresh
- [ ] `ListView.builder` で `LocalPostCard` を並べる
- [ ] 末尾検知で `loadMore()` を呼ぶ（`ScrollController`）
- [ ] 並び替えボタン（MVP は新着のみ表示でも可）
- [ ] 投稿作成 FAB または NavigationBar のボタン

### 6-3. `LocalPostCard` ウィジェット

ファイル: `lib/presentation/feed/widgets/local_post_card.dart`

- [ ] ニックネーム（`profile.displayName ?? '匿名'`）
- [ ] 相対時刻（`createdAt` を「○分前」「○時間前」に変換）
- [ ] `DistanceLabel`（「約 x.x km」）
- [ ] 本文テキスト
- [ ] 任意サムネイル（`cached_network_image`）
- [ ] リアクションサマリ（👍 / 👀 / 🔥 の数）
- [ ] タップで投稿詳細ページへ遷移
- [ ] タップ領域が 44×44 論理 px 以上を確保（アクセシビリティ）

### 6-4. `DistanceLabel` ウィジェット

- [ ] `double? kilometers` を受け取り「約 x.x km」または「不明」を表示
- [ ] `semanticsLabel` で「${x}キロメートル」と読み上げ可能に

### 6-5. 空状態・エラー UI

- [ ] 件数 0: イラストまたはアイコン + 「近くにまだ投稿がありません」+ 「投稿する」CTA
- [ ] 位置オフ: `LocationPermissionCallout` ウィジェット + OS 設定へのディープリンク
- [ ] エラー: エラーテキスト + 「再試行」ボタン

---

## Phase 7: 投稿作成（FR-POST・FR-LOC）

> **目標**: テキスト入力・画像ピッカー・位置ぼかし・送信のフローを実装する。位置取得中はボタン無効化し、プライバシー説明を明示する。

### 7-1. `ComposeNotifier` / `ComposeState` の実装

- [ ] `ComposeState`: `editing`, `obfuscating`, `submitting`, `success`, `failure(message)`
- [ ] `pickImage()`: `image_picker` で画像選択 → bytes をメモリに保持
- [ ] `submit(content)`:
  1. `state = obfuscating` に変更
  2. `CreatePostUseCase.call(content, imageBytes)` を呼び出し
  3. 成功 → `success` → ルートを `/feed` に `go()`
  4. 失敗 → `failure` → エラーメッセージ表示

### 7-2. 投稿作成画面 UI

ファイル: `lib/presentation/compose/compose_page.dart`

- [ ] `fullscreenDialog: true` でモーダルとして開く
- [ ] 本文 `TextField`（必須、NGワード補助フィルタ）
- [ ] 画像プレビュー + 画像選択/削除ボタン
- [ ] 位置ぼかし中のインジケータ + 「現在地を取得しています...」テキスト
- [ ] 送信ボタン: 位置未確定・送信中は disabled
- [ ] キャンセルボタン（未送信なら確認ダイアログ）

### 7-3. 位置ぼかしの実装詳細

ファイル: `lib/application/location/obfuscate_location_use_case.dart`

- [ ] ランダムオフセット生成:
  - 方位角: `Random().nextDouble() * 360`（度数法）
  - 距離: `300 + Random().nextDouble() * 700`（300〜1000m）
- [ ] WGS84 近似変換（緯度方向: `1deg ≈ 111320m`、経度方向: `cos(lat) * 111320m`）
- [ ] 結果が緯度・経度の有効範囲に収まることを検証

### 7-4. NGワードフィルタ（FR-MOD-01 クライアント側）

- [ ] ハードコードまたはリモート設定で NGワードリストを管理
- [ ] 本文入力時または送信直前にチェック → `ValidationFailure` でエラー表示

---

## Phase 8: リアクション（FR-REACT）

> **目標**: 投稿詳細画面でリアクション選択・変更・削除を実装する。1 ユーザー 1 投稿 1 種の制約を UI で表現する。

### 8-1. 投稿詳細画面

ファイル: `lib/presentation/detail/detail_page.dart`

- [ ] ヘッダ（投稿者・相対時刻・`DistanceLabel`）
- [ ] 本文テキスト
- [ ] 画像（フルサイズ表示 or モーダル拡大）
- [ ] `ReactionPicker` ウィジェット
- [ ] コメントリスト（Phase 9 で実装、MVP では非表示または空）
- [ ] 自分の投稿なら削除ボタン（`PostRepository.deletePost()`）

### 8-2. `ReactionPicker` ウィジェット

ファイル: `lib/presentation/detail/widgets/reaction_picker.dart`

- [ ] 3 種（👍 / 👀 / 🔥）を `ChoiceChip` または `SegmentedButton` で表示
- [ ] 現在の選択状態をハイライト
- [ ] タップで `SubmitReactionUseCase.call()` → UPSERT
- [ ] 同じ種類を再タップで解除（`deleteReaction()`）
- [ ] タップ中はローディング表示（二重送信防止）

### 8-3. `DetailNotifier` の実装

- [ ] `loadPost(postId)`: 投稿 + リアクション状態を取得
- [ ] `submitReaction(type)`: `SubmitReactionUseCase` 呼び出し
- [ ] `deletePost()`: `PostRepository.deletePost()` 呼び出し → フィードに戻る

---

## Phase 9: コメント（FR-COMMENT）【MVP 後】

> **目標**: 投稿詳細画面にコメントスレッドを追加する。1 階層のネストのみサポートする。

### 9-1. `CommentThread` ウィジェット

ファイル: `lib/presentation/detail/widgets/comment_thread.dart`

- [ ] トップレベルコメントの一覧表示
- [ ] 各コメントに「返信」ボタン → 子コメントを `ListTile` で indent 表示
- [ ] `CommentComposer`（テキスト入力 + 送信）をリスト末尾に配置

### 9-2. コメント投稿 UI

- [ ] `TextField` + 「投稿」ボタン
- [ ] 返信時: 返信先コメントのプレビューを `CommentComposer` 上部に表示
- [ ] 送信中の二重送信防止

### 9-3. `DetailNotifier` へのコメント機能追加

- [ ] `loadComments(postId)`: `ListCommentsUseCase.call()`
- [ ] `addComment(content, parentId)`: `AddCommentUseCase.call()`

---

## Phase 10: テスト

> **目標**: 全体設計書 §9 のテスト戦略に従い、リリース前に最低限のテストカバレッジを確保する。

### 10-1. Domain ユニットテスト

ファイル: `test/domain/`

- [ ] `GeoCoordinate` — 範囲外の緯度・経度で例外がスローされること
- [ ] `Post.isExpired` — `expiresAt` が過去なら `true`、未来なら `false`
- [ ] `ReactionType.fromString` — 不明値が `null` または例外になること
- [ ] `ObfuscateLocationUseCase` — オフセット距離が 300m〜1000m の範囲に収まること（100 回試行）

### 10-2. Application ユニットテスト（モック Repository 使用）

ファイル: `test/application/`

- [ ] `CreatePostUseCase`:
  - 位置権限なし → `ValidationFailure` を返す
  - 画像アップロード失敗 → `NetworkFailure` を返す
  - 正常系 → `Post` を返す
- [ ] `LoadLocalFeedUseCase`:
  - 位置権限なし → `ValidationFailure` を返す
  - フィード取得成功 → `List<FeedPost>` を返す
- [ ] `ObfuscateLocationUseCase`:
  - 出力座標が元座標と同一にならない
  - オフセット距離が仕様範囲内

### 10-3. Widget テスト

ファイル: `test/presentation/`

- [ ] `LoginPage` — ボタンタップで `LoginNotifier` が呼ばれること
- [ ] `FeedPage` — `loading` 状態でスケルトンが表示されること
- [ ] `FeedPage` — `locationDenied` 状態で `LocationPermissionCallout` が表示されること
- [ ] `FeedPage` — `empty` 状態で「投稿する」CTA が表示されること
- [ ] `ReactionPicker` — タップで onSelect が呼ばれること

### 10-4. Infrastructure 結合テスト（任意）

- [ ] Supabase ローカル CLI 起動（`supabase start`）
- [ ] `SupabaseFeedRepository.fetchFeed` — 実際の DB で 5km フィルタが機能すること
- [ ] `SupabasePostRepository.createPost` — ぼかし後の座標で INSERT されること

---

## Phase 11: モデレーション・通報・ブロック（FR-MOD）【MVP 後】

> **目標**: 通報・ブロック機能をバックエンドとフロントエンドに追加する。

### 11-1. `reports` テーブルの作成

```sql
CREATE TABLE public.reports (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id     uuid REFERENCES public.posts(id) ON DELETE SET NULL,
  comment_id  uuid REFERENCES public.comments(id) ON DELETE SET NULL,
  reason      text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
```

- [ ] テーブル作成
- [ ] RLS: INSERT のみ認証ユーザーが可（`reporter_id = auth.uid()`）、SELECT は管理者のみ

### 11-2. `blocks` テーブルの作成

```sql
CREATE TABLE public.blocks (
  blocker_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id)
);
```

- [ ] テーブル作成
- [ ] `get_local_feed` RPC を更新してブロック済みユーザーの投稿を除外

### 11-3. 通報 UI

- [ ] 投稿詳細のメニューに「通報」項目追加
- [ ] 理由選択（ドロップダウン）+ 送信

### 11-4. ブロック UI

- [ ] プロフィール画面に「ブロック」ボタン追加
- [ ] ブロック後はフィードからそのユーザーの投稿が消えること

---

## Phase 12: 非機能・仕上げ

> **目標**: NFR（パフォーマンス・セキュリティ・プライバシー・アクセシビリティ）の基準を満たしてリリース判定できる状態にする。

### 12-1. パフォーマンス確認（NFR-PERF）

- [ ] `get_local_feed` の `EXPLAIN ANALYZE` でインデックス使用を確認
- [ ] 代表エリアでフィード取得を計測し、500ms 以内を確認（NFR-PERF-01）
- [ ] 投稿後にフィードを手動リフレッシュして 1 秒以内に自投稿が見えること（NFR-PERF-02）
- [ ] `ListView.builder` でスクロール FPS が 60fps 近辺を維持すること（`Flutter DevTools` で確認）

### 12-2. セキュリティ確認（NFR-SEC）

- [ ] 全テーブルで `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` が適用済みか確認
- [ ] 他ユーザーの投稿を削除しようとしたときに RLS エラーになること（手動テスト）
- [ ] Storage ポリシーで他ユーザーのファイルをアップロード・削除できないことを確認
- [ ] `anon` ロールでのアクセスが拒否されること

### 12-3. プライバシー確認（NFR-PRIV）

- [ ] DB に保存された `location` 列が元の正確座標と異なること（±300m〜1km のオフセット確認）
- [ ] `get_local_feed` の戻り値に正確座標が含まれないこと（`lat_blurred`, `lng_blurred` のみ）
- [ ] フィードカードに「距離はおおよその目安」の注記を表示
- [ ] 設定画面に「正確な位置は保存しません」の説明を表示

### 12-4. アクセシビリティ確認（詳細設計書 §10 チェックリスト）

- [ ] 主要ボタンが 44×44 論理 px 以上を満たすこと
- [ ] 動的フォント（`textScaler`）でレイアウトが崩れないこと
- [ ] 画像に意味がある場合は `Semantics(label:)` を設定
- [ ] コントラスト比を `flutter_a11y_tools` または手動で確認（WCAG 2.1 AA 目安）
- [ ] VoiceOver / TalkBack でフィード 1 件の読み上げ順が「投稿者 → 時刻 → 距離 → 本文」になること

### 12-5. リリース前チェックリスト

- [ ] `flutter analyze` がエラーなしで通ること
- [ ] `flutter test` が全テスト Pass すること
- [ ] iOS Info.plist に位置情報使用説明（`NSLocationWhenInUseUsageDescription`）を追加
- [ ] Android `AndroidManifest.xml` に `ACCESS_FINE_LOCATION` パーミッション追加
- [ ] Supabase の本番プロジェクトで `PITR`（ポイントインタイムリカバリ）設定確認
- [ ] プライバシーポリシーの URL を設定画面に追加
- [ ] `flutter build apk --release` / `flutter build ipa --release` が通ること

---

## 付録: タスク依存関係図（実装順序の目安）

```
Phase 0 ──▶ Phase 1（DDL）
         ├──▶ Phase 2（Domain）
         └──▶ Phase 2 ──▶ Phase 3（Infrastructure）
                       ├──▶ Phase 4（UseCase）──▶ Phase 5（Auth）
                       │                      ├──▶ Phase 6（Feed）
                       │                      ├──▶ Phase 7（Post）
                       │                      └──▶ Phase 8（Reaction）
                       └──▶ Phase 10（テスト）←─── Phase 4〜8 全て
Phase 9（Comment）は Phase 8 完了後
Phase 11（Mod）は Phase 9 完了後
Phase 12（仕上げ）は Phase 10 完了後
```

---

## 付録: MVP に含まれるタスクの一覧

MVP（要件定義書 §9.1）に必要なタスクのみを抜粋したチェックリスト。

### 必須（MVP）

- [x] Phase 0: 全タスク
- [x] Phase 1: 1-1 〜 1-9
- [x] Phase 2: 全タスク
- [x] Phase 3: 3-1 〜 3-11
- [x] Phase 4: 4-1 〜 4-5（コメント系は 4-5 のみ省略可）
- [x] Phase 5: 全タスク
- [x] Phase 6: 全タスク
- [x] Phase 7: 全タスク
- [x] Phase 8: 全タスク
- [x] Phase 10: 10-1 〜 10-3
- [x] Phase 12: 全タスク

### MVP 後（後回し可）

- [ ] Phase 9: コメント
- [ ] Phase 11: モデレーション・通報・ブロック
- [ ] Phase 4: 4-5, 4-6（コメント用 UseCase）
- [ ] Phase 6: 人気順フィルタ（`sort_mode = 'popular'`）

---

*本文書は要件定義書・全体設計書・詳細設計書から導出したタスク分解であり、実装の進捗に合わせて随時更新すること。*
