# Nirz Supabase バックエンドセットアップ手順

## 前提条件

- [Supabase CLI](https://supabase.com/docs/guides/cli) がインストール済み
- Supabaseプロジェクトが作成済み

## セットアップ手順

### 1. Supabase CLIのログイン

```bash
supabase login
```

### 2. プロジェクトのリンク

`config.toml` の `project.id` にSupabaseプロジェクトIDを設定後：

```bash
supabase link --project-ref <your-project-id>
```

### 3. マイグレーションの実行

```bash
supabase db push
```

これにより `migrations/` 内の全マイグレーションが順番に実行されます。

### 4. SMS認証の有効化

Supabase管理画面 > Authentication > Providers で電話番号認証を有効化：

1. Phone provider を ON にする
2. Twilio の認証情報を設定（Account SID, Auth Token, Messaging Service SID）

### 5. 定期実行の設定（期限切れ投稿削除）

**方法A: pg_cron（推奨）**

Supabase管理画面 > Database > Extensions から `pg_cron` を有効化後、SQL Editorで実行：

```sql
SELECT cron.schedule(
    'delete-expired-posts',
    '0 * * * *',
    $$SELECT delete_expired_posts()$$
);
```

**方法B: Edge Function**

pg_cronが利用できない場合は、Supabase Edge Functionで代替してください。

## その他のCLIコマンド

```bash
# ローカル開発環境の起動
supabase start

# マイグレーション状態の確認
supabase migration list

# 新しいマイグレーションの作成
supabase migration new <migration_name>

# データベースのリセット（ローカルのみ）
supabase db reset

# シードデータの投入
supabase db seed
```

## ディレクトリ構成

```
supabase/
├── config.toml                                    # Supabase CLI設定
├── setup.md                                       # このファイル
├── seed/
│   └── seed.sql                                   # シードデータ
└── migrations/
    ├── 20260130000000_enable_extensions.sql        # PostGIS有効化
    ├── 20260130000001_create_profiles.sql          # profilesテーブル
    ├── 20260130000002_create_user_locations.sql    # user_locationsテーブル
    ├── 20260130000003_create_posts.sql             # postsテーブル
    ├── 20260130000004_create_post_images.sql       # post_imagesテーブル
    ├── 20260130000005_create_likes.sql             # likesテーブル
    ├── 20260130000006_create_comments.sql          # commentsテーブル
    ├── 20260130000007_create_blocks.sql            # blocksテーブル
    ├── 20260130000008_create_reports.sql           # reportsテーブル
    ├── 20260130000009_create_functions.sql         # カスタム関数
    ├── 20260130000010_create_triggers.sql          # トリガー
    ├── 20260130000011_enable_rls.sql               # RLS有効化
    ├── 20260130000012_policies_profiles.sql        # profilesポリシー
    ├── 20260130000013_policies_user_locations.sql  # user_locationsポリシー
    ├── 20260130000014_policies_posts.sql           # postsポリシー
    ├── 20260130000015_policies_post_images.sql     # post_imagesポリシー
    ├── 20260130000016_policies_likes.sql           # likesポリシー
    ├── 20260130000017_policies_comments.sql        # commentsポリシー
    ├── 20260130000018_policies_blocks.sql          # blocksポリシー
    ├── 20260130000019_policies_reports.sql         # reportsポリシー
    ├── 20260130000020_create_storage_buckets.sql   # Storageバケット作成
    ├── 20260130000021_storage_policies_avatars.sql # avatarsポリシー
    └── 20260130000022_storage_policies_post_images.sql # post-imagesポリシー
```

## セットアップ確認チェックリスト

- [ ] PostGIS拡張が有効化されている
- [ ] 全テーブルが作成されている（8テーブル）
- [ ] 全インデックスが作成されている
- [ ] カスタム関数が作成されている（4関数）
- [ ] トリガーが作成されている（いいね・コメントカウント用）
- [ ] RLSポリシーが全テーブルに設定されている
- [ ] Storageバケットが作成されている（avatars, post-images）
- [ ] SMS認証プロバイダーが有効化されている
- [ ] 定期実行（期限切れ投稿削除）が設定されている
