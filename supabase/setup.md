# Nirz Supabase バックエンドセットアップ手順

## 前提条件

- Supabaseアカウント作成済み
- Supabaseプロジェクト作成済み

## セットアップ手順

Supabase管理画面のSQL Editorで、以下の順序でファイルを実行してください。

### 1. 拡張機能

| # | ファイル | 内容 |
|---|---------|------|
| 1 | `schemas/00_extensions.sql` | PostGIS拡張の有効化 |

### 2. テーブル作成

| # | ファイル | 内容 |
|---|---------|------|
| 1 | `schemas/01_profiles.sql` | ユーザープロフィール |
| 2 | `schemas/02_user_locations.sql` | ユーザー位置情報 |
| 3 | `schemas/03_posts.sql` | 投稿 |
| 4 | `schemas/04_post_images.sql` | 投稿画像 |
| 5 | `schemas/05_likes.sql` | いいね |
| 6 | `schemas/06_comments.sql` | コメント |
| 7 | `schemas/07_blocks.sql` | ブロック |
| 8 | `schemas/08_reports.sql` | 通報 |

### 3. インデックス作成

| # | ファイル | 内容 |
|---|---------|------|
| 1 | `indexes/01_user_locations.sql` | 位置情報GISTインデックス |
| 2 | `indexes/02_posts.sql` | 投稿の地理空間・時刻・ユーザーインデックス |
| 3 | `indexes/03_comments.sql` | コメントのインデックス |
| 4 | `indexes/04_blocks.sql` | ブロックのインデックス |

### 4. カスタム関数

| # | ファイル | 内容 |
|---|---------|------|
| 1 | `functions/01_get_radius_for_city.sql` | 都市コードから表示範囲判定 |
| 2 | `functions/02_get_nearby_posts.sql` | タイムライン用近隣投稿取得 |
| 3 | `functions/03_get_map_posts.sql` | マップ用近隣投稿取得 |
| 4 | `functions/04_delete_expired_posts.sql` | 期限切れ投稿の一括削除 |

### 5. トリガー

| # | ファイル | 内容 |
|---|---------|------|
| 1 | `triggers/01_like_count.sql` | いいね数の自動更新 |
| 2 | `triggers/02_comment_count.sql` | コメント数の自動更新 |

### 6. Row Level Security

| # | ファイル | 内容 |
|---|---------|------|
| 0 | `policies/00_enable_rls.sql` | 全テーブルのRLS有効化 |
| 1 | `policies/01_profiles.sql` | プロフィールのポリシー |
| 2 | `policies/02_user_locations.sql` | 位置情報のポリシー |
| 3 | `policies/03_posts.sql` | 投稿のポリシー |
| 4 | `policies/04_post_images.sql` | 投稿画像のポリシー |
| 5 | `policies/05_likes.sql` | いいねのポリシー |
| 6 | `policies/06_comments.sql` | コメントのポリシー |
| 7 | `policies/07_blocks.sql` | ブロックのポリシー |
| 8 | `policies/08_reports.sql` | 通報のポリシー |

### 7. Storage

| # | ファイル | 内容 |
|---|---------|------|
| 1 | `storage/01_buckets.sql` | バケット作成（avatars, post-images） |
| 2 | `storage/02_avatars_policies.sql` | アバター画像のポリシー |
| 3 | `storage/03_post_images_policies.sql` | 投稿画像のポリシー |

### 8. SMS認証の有効化

Supabase管理画面 > Authentication > Providers で電話番号認証を有効化：

1. Phone provider を ON にする
2. Twilio の認証情報を設定（Account SID, Auth Token, Messaging Service SID）

### 9. 定期実行の設定

期限切れ投稿の自動削除用に、以下のいずれかを設定：

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

## ディレクトリ構成

```
supabase/
├── schemas/           # テーブル定義
│   ├── 00_extensions.sql
│   ├── 01_profiles.sql
│   ├── 02_user_locations.sql
│   ├── 03_posts.sql
│   ├── 04_post_images.sql
│   ├── 05_likes.sql
│   ├── 06_comments.sql
│   ├── 07_blocks.sql
│   └── 08_reports.sql
├── indexes/           # インデックス定義
│   ├── 01_user_locations.sql
│   ├── 02_posts.sql
│   ├── 03_comments.sql
│   └── 04_blocks.sql
├── functions/         # カスタム関数
│   ├── 01_get_radius_for_city.sql
│   ├── 02_get_nearby_posts.sql
│   ├── 03_get_map_posts.sql
│   └── 04_delete_expired_posts.sql
├── triggers/          # トリガー
│   ├── 01_like_count.sql
│   └── 02_comment_count.sql
├── policies/          # RLSポリシー
│   ├── 00_enable_rls.sql
│   ├── 01_profiles.sql
│   ├── 02_user_locations.sql
│   ├── 03_posts.sql
│   ├── 04_post_images.sql
│   ├── 05_likes.sql
│   ├── 06_comments.sql
│   ├── 07_blocks.sql
│   └── 08_reports.sql
├── storage/           # Storage設定
│   ├── 01_buckets.sql
│   ├── 02_avatars_policies.sql
│   └── 03_post_images_policies.sql
└── setup.md           # このファイル
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
