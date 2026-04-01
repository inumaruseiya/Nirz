# ローカルSNS 実装フェーズ分解（docs 準拠）

| 項目 | 内容 |
|------|------|
| 目的 | [要件定義書](./requirements-local-sns-flutter-supabase.md)、[全体設計書](./system-design-local-sns-flutter-supabase.md)、[詳細設計書](./detailed-design-local-sns-flutter-supabase.md)に基づき、実装者が順に着手できる**細かい作業単位**をフェーズ別に列挙する |
| 前提 | MVP（要件 §9.1）: 認証、投稿（テキスト＋任意画像・ぼかし位置・24h TTL）、5km フィード（新着）、リアクション（3種・1ユーザー1投稿1種） |
| 版 | 1.0 |

---

## Phase 0 — プロジェクト準備・合意

### 0.1 リポジトリ・ブランチ

- [ ] 開発ブランチ方針・レビュー運用を決める
- [ ] Supabase プロジェクト（開発 / ステージング）の作成または紐付け先を決める
- [ ] 機密情報（`anon` key 等）の管理方法（`.env` / `--dart-define` / CI シークレット）を決める

### 0.2 技術スタックの固定

- [ ] Flutter SDK 下限バージョンを README または `pubspec.yaml` と整合させる
- [ ] 状態管理パターンを1つに決める（`ChangeNotifier` / Riverpod / Bloc 等、全体設計 §2 の方針に合わせる）
- [ ] iOS / Android の最小 OS バージョンを決める
- [ ] OAuth プロバイダ（Google / Apple 等）を要件 FR-AUTH-01 に沿って列挙し、Supabase ダッシュボードで有効化する項目をリスト化する

### 0.3 法務・プロダクト（軽量）

- [ ] プライバシーポリシー草案（正確座標非保存・ぼかし方針）の担当と期限を決める
- [ ] 距離表示の注記文言（詳細設計 §4.3「おおよその目安」）の確定フローを決める

---

## Phase 1 — Supabase プロジェクト初期設定

### 1.1 拡張・基本設定

- [ ] PostgreSQL で `postgis` 拡張を有効化する
- [ ] タイムゾーン方針（`timestamptz` は UTC で統一）をマイグレーション方針に書く

### 1.2 Auth

- [ ] メール認証の有効化・メールテンプレート確認
- [ ] 採用する OAuth ごとに Redirect URL・クライアント ID を設定
- [ ] 匿名ログインを使わない方針なら無効のまま確認（要件: 未ログインは書き込み禁止）

### 1.3 Storage

- [ ] 投稿画像用バケット名を決める（例: `post-images`）
- [ ] バケットを private / public のどちらにするか決め、公開 URL または署名 URL 方針を決める
- [ ] バケットのファイルパス規約（`user_id/post_id/...` 等）を決める

---

## Phase 2 — データベーススキーマ（DDL）

### 2.1 `profiles`（public）

- [ ] `id` uuid PK、`auth.users.id` と同一
- [ ] `name` text（ニックネーム）、`created_at` timestamptz
- [ ] 新規ユーザー作成時に `profiles` 行を自動生成するトリガ（または Edge Function）を設計・実装
- [ ] `avatar_url` 等を後から足す場合はマイグレーション方針だけ先に決める

### 2.2 `posts`

- [ ] `id` uuid PK、`user_id` uuid FK → `auth.users` または `profiles`
- [ ] `content` text NOT NULL、`image_url` text NULL 可
- [ ] `location` を `geography(Point, 4326)` で定義
- [ ] `created_at` / `expires_at` timestamptz（`expires_at` はアプリまたは RPC で `created_at + 24h` を強制）
- [ ] **GiST インデックス** `idx_posts_location` を作成（要件 NFR-SCALE-02）

### 2.3 `reactions`

- [ ] `id` uuid PK、`user_id`、`post_id`、`type` text（`like` / `look` / `fire` を CHECK または enum で制約）
- [ ] `created_at` timestamptz
- [ ] `UNIQUE (user_id, post_id)` を追加（要件 FR-REACT-02）
- [ ] `post_id` に FK、`user_id` に FK

### 2.4 `comments`（MVP 後だがスキーマ先行なら）

- [ ] `id`、`user_id`、`post_id`、`parent_comment_id` NULL 可、`content`、`created_at`
- [ ] `parent_comment_id` は NULL または「トップレベルコメント ID」のみ許可する CHECK（1階層まで）

### 2.5 将来用（要件 §4.8、MVP 外）

- [ ] `reports` テーブル案をメモまたは別チケットに残す
- [ ] `blocks`（ブロッカー・被ブロッカー）テーブル案を残す

---

## Phase 3 — Row Level Security（RLS）とポリシー

### 3.1 共通

- [ ] `profiles` / `posts` / `reactions` / `comments` で RLS を有効化（要件 NFR-SEC-01）
- [ ] **サービスロール**と**匿名**の挙動をテーブルごとに確認する

### 3.2 `profiles`

- [ ] 認証ユーザーは自分の行の SELECT / UPDATE
- [ ] INSERT はトリガ経由のみ、など方針を固定

### 3.3 `posts`

- [ ] SELECT: 「認証済み read 可」か「RPC のみ」かを決め、要件 §6.2 の推奨（RPC 集約）と整合させる
- [ ] INSERT: `user_id = auth.uid()` のみ
- [ ] UPDATE: 本人のみ（必要最小限のカラム）
- [ ] DELETE: 本人のみ（要件 NFR-SEC-02）

### 3.4 `reactions`

- [ ] INSERT / UPDATE / DELETE: 自分の `user_id` のみ
- [ ] SELECT: フィード RPC 内で集計するなら直接 SELECT ポリシーは簡略化可能

### 3.5 `comments`（実装タイミングで）

- [ ] トップレベル・返信の INSERT ルール
- [ ] ブロック連携時は取得 RPC で除外（将来）

### 3.6 Storage ポリシー

- [ ] アップロード: 認証ユーザーのみ、パスに `auth.uid()` を含める等
- [ ] 他ユーザーのオブジェクト更新・削除禁止（要件 NFR-SEC-03）

---

## Phase 4 — RPC（SECURITY DEFINER）とサーバ側強制

### 4.1 `get_local_feed`

- [ ] 入力: `lat`, `lng`, `limit`, `cursor`（任意）, `sort`（`new` / `popular` ※MVP は `new` のみでも可）
- [ ] 条件: `ST_DWithin(location, ST_MakePoint(lng, lat)::geography, 5000)` かつ `expires_at > now()`（要件 FR-FEED-01）
- [ ] 並び: デフォルト `created_at DESC`（FR-FEED-02）
- [ ] 戻り: 投稿列 ＋ リアクション数集計 ＋ `next_cursor`（詳細設計 §8.1）
- [ ] `SECURITY DEFINER` + 適切な `search_path` 固定
- [ ] `EXPLAIN ANALYZE` で GiST 利用を確認（要件 §10 リスク対策）

### 4.2 `create_post`（推奨）

- [ ] 入力: `content`, `image_url`（任意）, `lat_blurred`, `lng_blurred`（**ぼかし後のみ**、FR-LOC-02）
- [ ] サーバで `expires_at = now() + interval '24 hours'` を強制（FR-POST-01）
- [ ] `user_id = auth.uid()` を RPC 内で固定
- [ ] 出力: 作成行

### 4.3 オプション

- [ ] NG ワードは DB トリガまたは RPC 内バリデーション（FR-MOD-01 サーバ側）

---

## Phase 5 — Flutter プロジェクト構造（クリーンアーキテクチャ）

### 5.1 ディレクトリ

- [ ] `lib/domain` / `lib/application` / `lib/infrastructure` / `lib/presentation` を作成（全体設計 §2）
- [ ] feature 分割方針（横割りレイヤ vs feature 内レイヤ）を決め、空フォルダまたは README で明示

### 5.2 依存パッケージ

- [ ] `supabase_flutter` を追加し `Supabase.initialize` を `main` で実行
- [ ] `geolocator`（または同等）を追加
- [ ] 状態管理・ルーティング・DI（`get_it` 等）を `pubspec.yaml` に追加

### 5.3 Domain 型（全体設計 §4）

- [ ] `UserId`, `PostId`, `GeoCoordinate`, `ObfuscatedLocation`, `FeedRadiusMeters`（const 5000）, `ReactionType` enum
- [ ] `Post`, `FeedPost`, `Profile`, `Reaction`, `Comment`（後続でも可）
- [ ] `Failure` sealed class 階層と `Result` 型（または `Either`）の方針

### 5.4 Repository 抽象（interface）

- [ ] `AuthRepository`, `LocationRepository`, `PostRepository`, `FeedRepository`, `ReactionRepository`, `CommentRepository`, `ProfileRepository`, `StorageRepository`（全体設計 §5.1）

### 5.5 Application ユースケース

- [ ] `ObfuscateLocationUseCase`（または Domain サービス）: ±300m〜1km のランダムオフセット（FR-LOC-03）、WGS84 メートル換算
- [ ] `CreatePostUseCase`: Storage → `create_post` RPC の順（全体設計 §8.1 シーケンス）
- [ ] `LoadLocalFeedUseCase`: 位置取得 → `get_local_feed`（クエリ座標は永続化しない方針をコードコメントで固定）
- [ ] `SubmitReactionUseCase`（または `UpsertReactionUseCase`）

### 5.6 Infrastructure 実装

- [ ] DTO（`PostDto`, `RpcFeedParams`, `RpcFeedItemDto` 等）と Mapper
- [ ] `SupabaseProfileRepository`, `SupabasePostRepository`, `SupabaseFeedRepository`, `SupabaseReactionRepository`, `SupabaseStorageRepository`
- [ ] `GeolocatorLocationRepository`（権限・現在地取得）

### 5.7 DI

- [ ] 本番用に Supabase 実装を束ねるモジュール
- [ ] テスト用にモック差し替え可能にする

---

## Phase 6 — 位置情報フロー（クライアント）

### 6.1 権限

- [ ] iOS `Info.plist` に位置用途の説明文を追加
- [ ] Android `AndroidManifest.xml` に権限を追加
- [ ] 初回またはフィード利用前に `requestPermission`（FR-LOC-01）

### 6.2 ぼかし

- [ ] 生座標は **どこにもサーバ送信しない**（投稿 RPC にはぼかし後のみ）
- [ ] ぼかし距離分布（一様など）をユニットテストで範囲検証（全体設計 §9）

### 6.3 拒否・オフライン

- [ ] 位置なし時はフィード取得しない、または明示メッセージ（FR-LOC-04）
- [ ] 設定画面から OS 設定への導線（詳細設計 §4.6）

---

## Phase 7 — 認証 UI・セッション（Presentation + Application）

### 7.1 スプラッシュ / セッション復元（詳細設計 §4.1）

- [ ] 起動時に Supabase セッション確認
- [ ] セッションあり → ホーム、なし → ログイン
- [ ] ネットワークエラー時の再試行 UI

### 7.2 ログイン・登録（§4.2）

- [ ] メール + パスワード（`signInWithPassword` / `signUp`）
- [ ] OAuth ボタンと Deep Link / Redirect 設定
- [ ] フィールド近傍エラーとスナックバーの重複回避
- [ ] パスワードリセット導線
- [ ] `Semantics` / ラベル（アクセシビリティ）

### 7.3 ガード

- [ ] 未ログインで投稿・リアクション・コメント操作を UI 上も禁止（FR-AUTH-03、RLS と二重化）

---

## Phase 8 — ホーム（ローカルフィード）UI

### 8.1 レイアウト（§4.3）

- [ ] `CustomScrollView` + `SliverAppBar`
- [ ] MVP は新着のみ（人気順は Phase 12 またはフラグで後付け）

### 8.2 カード（コンポーネント §6）

- [ ] `LocalPostCard`: ニックネーム、相対時刻、`DistanceLabel`（「約 x km」）
- [ ] 本文、任意サムネイル、リアクションサマリ
- [ ] タップで投稿詳細へ

### 8.3 リスト制御

- [ ] Pull-to-refresh
- [ ] カーソルページング（`FeedCursor`、`next_cursor`）
- [ ] `ListView.builder`、画像キャッシュ（NFR-PERF-01）

### 8.4 状態機械（§5.1）

- [ ] `initial` / `loading` / `ready` / `empty` / `locationDenied` / `error` を実装
- [ ] `AsyncStateSwitcher` 等で分岐を共通化

### 8.5 プライバシー表示

- [ ] 距離が推定である旨の短い注記または情報アイコン

---

## Phase 9 — 投稿作成 UI

### 9.1 フォーム（§4.4）

- [ ] テキスト必須、空なら送信不可
- [ ] 画像ピッカー、削除、プレビュー
- [ ] クライアント側 NG ワード補助（FR-MOD-01）

### 9.2 位置フロー

- [ ] 送信前に位置取得 → ぼかし → 成功まで送信ボタン disabled
- [ ] `obfuscating` 状態の文言「位置を準備しています」

### 9.3 送信

- [ ] 画像を Storage にアップロード → URL を `create_post` に渡す
- [ ] 二重送信防止（`submitting`）
- [ ] 成功後フィードへ戻し、リフレッシュで自分の投稿を反映（NFR-PERF-02）

---

## Phase 10 — 投稿詳細 + リアクション（MVP 内）

### 10.1 レイアウト（§4.5）

- [ ] ヘッダ（投稿者・時刻・距離）、本文、画像
- [ ] `ReactionPicker`（👍 / 👀 / 🔥）— UPSERT（詳細設計 §8.3）
- [ ] 自分の投稿のみ削除メニュー（DELETE ポリシーと連動）

### 10.2 リアクション状態

- [ ] 現在ユーザーの選択状態を表示（フィード RPC の戻りに含めるか、別クエリかを決定）

---

## Phase 11 — 設定画面（MVP 推奨）

### 11.1 項目（§4.6）

- [ ] 位置情報の説明（正確座標は保存しない）
- [ ] OS 設定へのディープリンク
- [ ] ログアウト

### 11.2 UX

- [ ] 位置オフにした結果フィードが見られない旨をトグル下に常時表示

---

## Phase 12 — テスト・品質・リリース準備

### 12.1 自動テスト（全体設計 §9）

- [ ] Domain: ぼかし距離、期限切れ判定、`ReactionType` マッピング
- [ ] Application: Repository モックでユースケース分岐
- [ ] Widget: スプラッシュ、フィード空状態、位置拒否、ログインフォーム主要経路

### 12.2 結合・手動

- [ ] Supabase ステージングで E2E 相当（投稿→フィード反映→リアクション）
- [ ] RLS の「他ユーザーが更新できない」ネガティブテスト

### 12.3 パフォーマンス

- [ ] フィード RPC のレイテンシ目安 500ms（NFR-PERF-01）を計測環境で記録
- [ ] 投稿から一覧反映 1 秒目標（NFR-PERF-02）の確認

### 12.4 アクセシビリティ（詳細設計 §10）

- [ ] 最小タップ領域 44×44、`textScaler`、コントラスト、VoiceOver / TalkBack 読み上げ順

---

## Phase 13 — MVP 後（要件 §9.2）

### 13.1 コメント

- [ ] `CommentRepository` 実装、`CommentThread` / `CommentComposer`
- [ ] 1 階層返信のバリデーション（ユースケース）
- [ ] RLS ポリシー完成

### 13.2 フィード人気順（FR-FEED-03）

- [ ] `get_local_feed` の `sort=popular` と集計（ビュー / マテビュー / サブクエリ）
- [ ] UI に並び替えトグル

### 13.3 通報・ブロック（FR-MOD-02/03）

- [ ] `reports` / `blocks` テーブルと管理者フロー
- [ ] フィード・コメント取得からブロック除外

### 13.4 ユーザーステータス（FR-STATUS、任意）

- [ ] DB カラムまたはテーブル
- [ ] 設定画面のみ表示（フィードカードには出さない）

### 13.5 リアルタイム（任意）

- [ ] Supabase Realtime でフィード差分購読（MVP はポーリングでも可）

### 13.6 分析・KPI（要件 §3.2）

- [ ] DAU / 投稿数 / インプレッション計測の仕組みを別基盤と接続

---

## 付録: ドキュメントとの対応早見表

| フェーズ群 | 主な参照 |
|------------|----------|
| Phase 0–1 | 要件 §2, §5, 全体設計 §6 |
| Phase 2–4 | 要件 §6, §7, 詳細設計 §8 |
| Phase 5 | 全体設計 §2–§5, §8 シーケンス |
| Phase 7–11 | 詳細設計 §3–§7, 要件 §4, §8 |
| Phase 12–13 | 要件 §9–§11, 全体設計 §9, 詳細設計 §9–§11 |

---

## 改訂履歴

| 版 | 日付 | 変更内容 |
|----|------|----------|
| 1.0 | 2026-04-01 | 初版（docs 3 文書に基づくフェーズ分解） |
