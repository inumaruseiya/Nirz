# Nirz Supabase バックエンドセットアップ手順

## 前提条件

- Supabaseアカウント作成済み
- Supabaseプロジェクト作成済み

## セットアップ手順

### 1. PostGIS拡張の有効化

Supabase管理画面 > Database > Extensions から `postgis` を有効化するか、SQL Editorで以下を実行：

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 2. SQLファイルの実行順序

Supabase管理画面のSQL Editorで、以下の順序でファイルを実行してください：

1. **`schema.sql`** - テーブル・インデックス作成
2. **`functions.sql`** - カスタム関数・トリガー作成
3. **`policies.sql`** - Row Level Security ポリシー設定
4. **`storage.sql`** - Storageバケット・ポリシー設定

### 3. SMS認証の有効化

Supabase管理画面 > Authentication > Providers で電話番号認証を有効化：

1. Phone provider を ON にする
2. Twilio の認証情報を設定（Account SID, Auth Token, Messaging Service SID）

### 4. 定期実行の設定

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

## ファイル構成

| ファイル | 内容 |
|---------|------|
| `schema.sql` | テーブル定義、インデックス |
| `functions.sql` | カスタム関数、トリガー |
| `policies.sql` | Row Level Security ポリシー |
| `storage.sql` | Storageバケット、ポリシー |

## テーブル一覧

| テーブル | 説明 |
|---------|------|
| `profiles` | ユーザープロフィール |
| `user_locations` | ユーザー位置情報 |
| `posts` | 投稿（24時間で自動削除） |
| `post_images` | 投稿画像（最大4枚） |
| `likes` | いいね |
| `comments` | コメント |
| `blocks` | ブロック |
| `reports` | 通報 |

## カスタム関数一覧

| 関数 | 説明 |
|------|------|
| `get_radius_for_city(city_code)` | 都市コードから表示範囲（1km/5km）を判定 |
| `get_nearby_posts(lat, lng, radius, limit, offset)` | タイムライン用の近隣投稿取得 |
| `get_map_posts(lat, lng, radius)` | マップ用の近隣投稿取得（最大200件） |
| `delete_expired_posts()` | 期限切れ投稿の一括削除 |

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
