# Nirz 要件定義書

**バージョン**: 1.0
**作成日**: 2026年1月30日
**最終更新**: 2026年1月30日

-----

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
1. [ターゲット・ペルソナ](#2-ターゲットペルソナ)
1. [機能要件](#3-機能要件)
1. [非機能要件](#4-非機能要件)
1. [技術スタック](#5-技術スタック)
1. [データベース設計](#6-データベース設計)
1. [UI/UX設計](#7-uiux設計)
1. [セキュリティ・プライバシー](#8-セキュリティプライバシー)
1. [広告実装](#9-広告実装)
1. [開発スケジュール](#10-開発スケジュール)
1. [コスト試算](#11-コスト試算)
1. [リスクと対策](#12-リスクと対策)
1. [マーケティング戦略](#13-マーケティング戦略)
1. [今後の検討事項](#14-今後の検討事項)

-----

## 1. プロジェクト概要

### 1.1 サービス名

**Nirz(ニルズ)**

### 1.2 ブランドアイデンティティ

#### ロゴデザイン

- 2人の人物が繋がるシンボル
- 出会いと繋がりを象徴
- シンプルで認識しやすい

#### カラースキーム

- **プライマリカラー**: `#1B8FCE` (鮮やかなブルー)
- **セカンダリカラー**: `#147AB8` (濃いブルー)
- **アクセントカラー**: `#4DA8E0` (明るいブルー)
- **背景**: `#FFFFFF` (ホワイト)
- **テキスト**: `#1A1A1A` (ダークグレー)

#### ブランドコンセプト

- 「今、ここで、近くの人と繋がる」
- 偶然の出会いを楽しむ
- カジュアルで気軽な交流

### 1.3 サービスコンセプト

**その場限りの出会い**を重視した位置情報ベースSNS

- 自分の周辺(1kmまたは5km)で投稿された内容を閲覧・交流できる
- 投稿は24時間で自動削除される「今」にフォーカスしたプラットフォーム
- Twitter的なタイムライン + Yahoo天気的なマップビューの2つの閲覧方法
- フォロー機能なし、DM機能なし(MVP版)でシンプルに

### 1.4 主要な特徴

- **距離ベースの投稿表示**: 首都圏・主要都市は1km、その他は5km範囲
- **24時間限定投稿**: すべての投稿は24時間後に自動削除
- **距離の曖昧化**: プライバシー保護のため、距離は「500m以内」「1km以内」などと表示
- **シンプルな機能**: フォロー機能なし、DM機能なし(MVP版)
- **2つのビュー**: タイムラインとマップで投稿を閲覧可能

-----

## 2. ターゲット・ペルソナ

### 2.1 ターゲットユーザー

#### メインターゲット

- **年齢**: 18～24歳のZ世代
- **属性**: 大学生、専門学校生
- **デジタルネイティブ**: SNSに慣れ親しんでいる世代

#### 価値観

- リアルな繋がりを重視
- 今この瞬間を楽しむ
- プライバシー意識が高い
- 新しいサービスへの抵抗が少ない

### 2.2 ユースケース

#### 大学生の日常

**例1: サークル・イベント**

> 「今日のサークルの花見、誰か来てる?」
> → 同じ場所にいる人と即座に繋がれる

**例2: 空きコマ・休憩時間**

> 「今から1時間空きコマ。誰かカフェ行ける人いない?」
> → 近くの暇な人を見つけられる

**例3: 新歓・交流**

> 「新入生なんだけど、この辺のおすすめランチ教えて!」
> → 近くの先輩が反応してくれる

**例4: 趣味友探し**

> 「#カメラ好き 今日の夕焼け綺麗じゃない?」
> → 同じ趣味の人と出会える

#### 専門学校生・若手社会人

**例5: 放課後・アフター5**

> 「今から飲みに行ける人募集!」
> → その場で集まれる

**例6: 地域イベント**

> 「今夏祭りにいるんだけど、一緒に回る人いない?」
> → 同じイベント参加者と繋がる

### 2.3 ペルソナ設定

#### ペルソナ1: 山田太郎(やまだ たろう)

- **年齢**: 20歳
- **属性**: 大学2年生
- **居住地**: 都内の大学に通う
- **性格**: 友達は多いが、もっと新しい出会いが欲しい
- **SNS利用**: TwitterやInstagramを日常的に使用
- **趣味**: 休日はカフェ巡りや友達とのドライブ
- **ニーズ**: 「今すぐ遊べる人」を探したい

#### ペルソナ2: 佐藤花子(さとう はなこ)

- **年齢**: 19歳
- **属性**: 大学1年生
- **居住地**: 地方から上京して一人暮らし
- **性格**: 大学以外の友達を作りたい
- **SNS利用**: InstagramやTikTokをよく見る
- **趣味**: カフェ巡りやショッピングが好き
- **ニーズ**: 「同じ趣味の友達」を探したい

-----

## 3. 機能要件

### 3.1 MVP(最小機能製品)に含む機能

#### 3.1.1 認証・ユーザー管理

**電話番号SMS認証**

- 電話番号入力
- SMS認証コード送信・確認
- JWT発行

**プロフィール設定**

- ニックネーム(必須、50文字以内)
- アイコン画像(任意)
- 自己紹介(任意、100文字以内)
- 生まれ年(年齢確認用、必須)
- 興味タグ(最大5個選択)
  - 例: カフェ、音楽、アニメ、スポーツ、カメラ、旅行、ゲーム、ファッション等

**年齢制限**

- 18歳未満は利用不可

#### 3.1.2 位置情報管理

**GPS位置情報取得**

- アプリ起動時・投稿時に自動取得
- ユーザーによるON/OFF切り替え可能

**市区町村判定**

- 緯度経度から市区町村コードを取得
- 首都圏・主要都市判定(1km or 5km範囲決定)

**対象エリア判定ロジック**

- **1km範囲**: 東京都全域、大阪府全域、政令指定都市13市
  - 横浜市、川崎市、名古屋市、福岡市、札幌市、仙台市、静岡市、浜松市、京都市、神戸市、岡山市、広島市、熊本市
- **5km範囲**: その他の地域

#### 3.1.3 投稿機能

**投稿作成**

- テキスト入力(1〜300文字)
- 画像添付(最大4枚、各5MB以内)
- 位置情報自動付与
- 投稿時刻から24時間後に自動削除
- 絵文字対応

**投稿削除**

- 自分の投稿のみ削除可能

#### 3.1.4 タイムラインビュー

**投稿一覧表示**

- 自分の範囲内(1km or 5km)で投稿された投稿を時系列表示
- 投稿者が現在その場所にいなくても、投稿位置が範囲内なら表示
- 無限スクロール(ページネーション)
- 1ページ20件表示

**表示情報**

- 投稿者ニックネーム・アイコン
- 投稿内容
- 画像(ある場合)
- 曖昧化された距離(「500m以内」「1km以内」「2km以内」「5km以内」)
- いいね数・コメント数
- 投稿時刻(相対時刻: "3分前"など)

**広告表示**

- 10投稿ごとにAdMobバナー広告を挿入

#### 3.1.5 マップビュー(Yahoo天気風)

**地図上にピン表示**

- Google Maps上に投稿位置をピンで表示
- ピンは範囲内の投稿のみ(最大200件)
- ピンクラスタリング(密集時に自動グループ化)

**ピンタップ**

- 投稿プレビュー表示(テキスト30文字 + 画像サムネイル)
- タップで投稿詳細へ遷移

**現在地ボタン**

- ユーザーの現在地に地図を移動

#### 3.1.6 投稿詳細・リアクション

**投稿詳細表示**

- 投稿内容全文
- 全画像表示
- いいね・コメント一覧

**いいね機能**

- 投稿へのいいね追加・取り消し
- 重複いいね不可

**コメント機能**

- コメント投稿(1〜200文字)
- コメント一覧表示
- 自分のコメント削除

#### 3.1.7 セーフティ機能

**ブロック**

- 特定ユーザーをブロック
- ブロックしたユーザーの投稿・コメントは非表示

**通報**

- 不適切な投稿・コメント・ユーザーを通報
- 通報理由の選択・詳細入力

### 3.2 MVP後に追加予定の機能(Phase 2以降)

#### Phase 2 (リリース後1-2ヶ月)

**プッシュ通知**

- 近くに新規投稿があった時
- 自分の投稿にいいね・コメントがついた時

**ハッシュタグ機能**

- 投稿にハッシュタグ付与
- ハッシュタグ検索

**投稿検索**

- キーワード検索

**ユーザープロフィール詳細**

- 過去の投稿一覧表示

#### Phase 3 (3-6ヶ月後)

**DM機能**

- ユーザー間の1対1メッセージ

**イベント投稿タイプ**

- 特別な投稿形式(開催日時、参加人数など)

**プレミアムプラン**

- 広告非表示
- 投稿優先表示
- 拡張検索フィルター
- 画像6枚まで投稿可能

**アプリ内通貨・ポイントシステム**

- 投稿やいいねでポイント獲得
- ポイントで特別機能アンロック

-----

## 4. 非機能要件

### 4.1 パフォーマンス

- タイムライン読み込み: 2秒以内
- マップピン表示: 3秒以内
- 投稿送信: 1秒以内
- 画像アップロード: 5秒以内(5MB/枚)

### 4.2 セキュリティ

- HTTPS通信のみ
- JWT認証
- Row Level Security(RLS)によるデータアクセス制御
- **Rate Limiting**:
  - 投稿: 5件/時間
  - コメント: 30件/時間
  - いいね: 100件/時間

### 4.3 スケーラビリティ

- 初期目標: 1,000 MAU
- 最大同時接続: 500ユーザー
- データベース容量: 500MB(Supabase無料枠)

### 4.4 可用性

- 稼働率: 99%以上

### 4.5 プライバシー

#### 位置情報の扱い

- 投稿位置は保存するが、表示時は曖昧化
- 距離は「500m以内」「1km以内」「2km以内」「5km以内」のいずれかで表示
- ユーザーの現在位置は投稿時のみ取得

#### 個人情報保護

- 電話番号は暗号化保存
- 他ユーザーには非公開
- プロフィール情報は最小限

-----

## 5. 技術スタック

### 5.1 フロントエンド

- **フレームワーク**: Flutter 3.19+
- **言語**: Dart 3.0+
- **状態管理**: Riverpod

#### 主要パッケージ

```yaml
dependencies:
  # Supabase
  supabase_flutter: ^2.3.0

  # 地図・位置情報
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0
  geocoding: ^3.0.0

  # 状態管理
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0

  # UI
  cached_network_image: ^3.3.0
  image_picker: ^1.0.0
  flutter_cache_manager: ^3.3.0

  # 広告
  google_mobile_ads: ^4.0.0

  # その他
  intl: ^0.18.0
  timeago: ^3.6.0
```

### 5.2 バックエンド

- **BaaS**: Supabase
  - PostgreSQL 14 + PostGIS拡張
  - Supabase Auth(電話番号認証)
  - Supabase Storage(画像保存)
  - Supabase Realtime(リアルタイム更新)
  - Row Level Security(RLS)

### 5.3 インフラ

- **ホスティング**: Supabase(マネージド)
- **画像CDN**: Supabase Storage(自動CDN配信)
- **地図API**: Google Maps Platform
- **広告**: Google AdMob

### 5.4 開発ツール

- Git/GitHub: バージョン管理
- VSCode: IDE
- Figma: デザイン(必要に応じて)
- Postman: API テスト(必要に応じて)

-----

## 6. データベース設計

### 6.1 テーブル一覧

#### profiles (ユーザープロフィール)

```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nickname VARCHAR(50) NOT NULL,
    avatar_url TEXT,
    bio VARCHAR(100),
    birth_year INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### user_locations (ユーザー位置情報)

```sql
CREATE TABLE user_locations (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    city_code VARCHAR(10) NOT NULL,
    radius_km INT NOT NULL CHECK (radius_km IN (1, 5)),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_locations_geography ON user_locations USING GIST(location);
```

#### posts (投稿)

```sql
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) <= 300 AND char_length(content) > 0),
    location GEOGRAPHY(Point, 4326) NOT NULL,
    city_code VARCHAR(10) NOT NULL,
    like_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX idx_posts_geography ON posts USING GIST(location);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_expires_at ON posts(expires_at);
```

#### post_images (投稿画像)

```sql
CREATE TABLE post_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    display_order INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, display_order)
);
```

#### likes (いいね)

```sql
CREATE TABLE likes (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);
```

#### comments (コメント)

```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) <= 200 AND char_length(content) > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### blocks (ブロック)

```sql
CREATE TABLE blocks (
    blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);
```

#### reports (通報)

```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    comment_id UUID REFERENCES comments(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 6.2 主要な関数・ロジック

#### 市区町村判定関数

```sql
CREATE OR REPLACE FUNCTION get_radius_for_city(city_code VARCHAR)
RETURNS INT AS $$
BEGIN
    -- 東京都全域
    IF city_code LIKE '13%' THEN
        RETURN 1;
    END IF;

    -- 大阪府全域
    IF city_code LIKE '27%' THEN
        RETURN 1;
    END IF;

    -- 政令指定都市
    IF city_code IN (
        '14100', '14130', '23100', '40130', '01100',
        '04100', '22100', '22130', '26100', '28100',
        '33100', '34100', '43100'
    ) THEN
        RETURN 1;
    END IF;

    RETURN 5;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

#### 距離曖昧化ロジック

- 0〜500m: 「500m以内」
- 500m〜1km: 「1km以内」
- 1km〜2km: 「2km以内」
- 2km〜5km: 「5km以内」

#### タイムライン取得関数

```sql
CREATE OR REPLACE FUNCTION get_nearby_posts(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    user_radius_km INT,
    page_limit INT DEFAULT 20,
    page_offset INT DEFAULT 0
)
RETURNS TABLE (
    post_id UUID,
    user_id UUID,
    nickname VARCHAR,
    avatar_url TEXT,
    content TEXT,
    images JSONB,
    distance_range TEXT,
    like_count INT,
    comment_count INT,
    is_liked BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_location GEOGRAPHY;
    radius_meters INT;
BEGIN
    user_location := ST_MakePoint(user_lng, user_lat)::geography;
    radius_meters := user_radius_km * 1000;

    RETURN QUERY
    SELECT
        p.id,
        p.user_id,
        prof.nickname,
        prof.avatar_url,
        p.content,
        (
            SELECT jsonb_agg(jsonb_build_object('url', image_url, 'order', display_order) ORDER BY display_order)
            FROM post_images
            WHERE post_id = p.id
        ) as images,
        CASE
            WHEN ST_Distance(p.location, user_location) < 500 THEN '500m以内'
            WHEN ST_Distance(p.location, user_location) < 1000 THEN '1km以内'
            WHEN ST_Distance(p.location, user_location) < 2000 THEN '2km以内'
            ELSE '5km以内'
        END as distance_range,
        p.like_count,
        p.comment_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = auth.uid()) as is_liked,
        p.created_at
    FROM posts p
    JOIN profiles prof ON p.user_id = prof.id
    WHERE
        p.expires_at > NOW()
        AND ST_DWithin(p.location, user_location, radius_meters)
        AND NOT EXISTS (
            SELECT 1 FROM blocks
            WHERE blocker_id = auth.uid() AND blocked_id = p.user_id
        )
    ORDER BY p.created_at DESC
    LIMIT page_limit
    OFFSET page_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### マップ用投稿取得関数

```sql
CREATE OR REPLACE FUNCTION get_map_posts(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    user_radius_km INT
)
RETURNS TABLE (
    post_id UUID,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    preview TEXT,
    has_image BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_location GEOGRAPHY;
    radius_meters INT;
BEGIN
    user_location := ST_MakePoint(user_lng, user_lat)::geography;
    radius_meters := user_radius_km * 1000;

    RETURN QUERY
    SELECT
        p.id,
        ST_Y(p.location::geometry) as lat,
        ST_X(p.location::geometry) as lng,
        LEFT(p.content, 30) || CASE WHEN LENGTH(p.content) > 30 THEN '...' ELSE '' END as preview,
        EXISTS(SELECT 1 FROM post_images WHERE post_id = p.id) as has_image,
        p.created_at
    FROM posts p
    WHERE
        p.expires_at > NOW()
        AND ST_DWithin(p.location, user_location, radius_meters)
        AND NOT EXISTS (
            SELECT 1 FROM blocks
            WHERE blocker_id = auth.uid() AND blocked_id = p.user_id
        )
    ORDER BY p.created_at DESC
    LIMIT 200;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 期限切れ投稿の自動削除

```sql
CREATE OR REPLACE FUNCTION delete_expired_posts()
RETURNS void AS $$
BEGIN
    DELETE FROM posts WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;
```

### 6.3 Row Level Security (RLS) 設定

```sql
-- RLSを有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- プロフィール
CREATE POLICY "Users can view all profiles"
ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE USING (auth.uid() = id);

-- 投稿
CREATE POLICY "Anyone can view posts"
ON posts FOR SELECT USING (expires_at > NOW());

CREATE POLICY "Users can create posts"
ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE USING (auth.uid() = user_id);

-- いいね
CREATE POLICY "Users can manage own likes"
ON likes FOR ALL USING (auth.uid() = user_id);

-- コメント
CREATE POLICY "Anyone can view comments"
ON comments FOR SELECT USING (true);

CREATE POLICY "Users can create comments"
ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE USING (auth.uid() = user_id);
```

-----

## 7. UI/UX設計

### 7.1 デザインガイドライン

#### フォント

- **見出し**: 太字、18-24px
- **本文**: 14-16px
- **行間**: 1.5-1.8(読みやすさ重視)
- **日本語フォント**: Noto Sans JP または Hiragino Sans

#### カラー使用

- **ブルー(#1B8FCE)**: ボタン、リンク、アクション
- **ホワイト(#FFFFFF)**: 背景
- **ライトグレー(#F5F5F5)**: カードの背景
- **ダークグレー(#1A1A1A)**: テキスト

#### アニメーション

- マイクロインタラクション(いいねボタンなど)
- スムーズなトランジション(200-300ms)
- ページ遷移アニメーション

#### アイコン

- Material Icons または SF Symbols
- シンプルで認識しやすい

### 7.2 画面遷移図

```
[スプラッシュ]
    ↓
[オンボーディング(3画面)]
    ↓
[電話番号入力] → [SMS認証] → [プロフィール設定]
    ↓
[メインタブ]
├─ [タイムライン] → [投稿詳細] → [コメント一覧]
├─ [マップ]       → [投稿詳細]
├─ [投稿作成](モーダル)
└─ [マイページ]   → [設定] → [プロフィール編集]
```

### 7.3 主要画面レイアウト

#### タイムライン画面

```
┌─────────────────────────┐
│ [Nirzロゴ] 📍渋谷区(1km) │ ← ヘッダー
├─────────────────────────┤
│ [タイムライン][マップ]  │ ← タブ切り替え
├─────────────────────────┤
│                         │
│ ┌─投稿カード─────────┐ │
│ │ 👤 たろう  500m以内 │ │
│ │    3分前            │ │
│ │                     │ │
│ │ 今から渋谷でカフェ  │ │
│ │ 巡りしませんか?☕️  │ │
│ │ #カフェ好き         │ │
│ │                     │ │
│ │ [画像1][画像2]      │ │
│ │                     │ │
│ │ ❤️ 12  💬 3        │ │
│ └─────────────────────┘ │
│                         │
│ ┌─投稿カード─────────┐ │
│ │ 👤 はなこ  1km以内  │ │
│ │ ...                 │ │
│ └─────────────────────┘ │
│                         │
│ [広告バナー]            │
│                         │
└─────────────────────────┘
        [➕投稿] ← FAB
```

#### マップ画面

```
┌─────────────────────────┐
│ [タイムライン][マップ]  │
├─────────────────────────┤
│                         │
│    🗺️ Google Maps      │
│     📍  📍             │
│   📍      📍    📍     │
│       📍               │
│                         │
│  [🎯現在地ボタン]       │
│                         │
├─────────────────────────┤
│ ┌─投稿プレビュー─────┐ │
│ │ テキストプレビュー  │ │← ピンタップ時
│ │ 👤 ニックネーム     │ │
│ │ [距離]              │ │
│ │ [詳細を見る →]      │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

#### 投稿作成画面

```
┌─────────────────────────┐
│ [×]  新しい投稿  [投稿] │
├─────────────────────────┤
│                         │
│ ┌─────────────────────┐ │
│ │ 今何してる? 😊      │ │
│ │                     │ │
│ │                     │ │
│ │                     │ │
│ │                     │ │
│ └─────────────────────┘ │
│ 0/300                   │
│                         │
│ [画像] [画像] [画像] [+]│
│                         │
│ 📍渋谷区               │
│ ⏱️ 24時間後に自動削除  │
│                         │
│ [😊 絵文字] [#タグ]    │
└─────────────────────────┘
```

-----

## 8. セキュリティ・プライバシー

### 8.1 認証・認可

- **Supabase Auth**: 電話番号SMS認証
- **JWT**: アクセストークン・リフレッシュトークン
- **Row Level Security**: テーブルレベルでのアクセス制御

### 8.2 位置情報保護

- **距離の曖昧化**: 正確な距離は表示せず、範囲で表示
- **位置情報の保存**: 投稿時の位置のみ保存、履歴は保持しない
- **ON/OFF制御**: ユーザーが位置情報共有を制御可能
- **位置情報のランダム化**: 表示時に10-50m程度のブレを加える(オプション)

### 8.3 コンテンツモデレーション

- **通報機能**: 不適切コンテンツを通報
- **ブロック機能**: 特定ユーザーをブロック
- **自動削除**: 24時間経過で投稿自動削除
- **Rate Limiting**: スパム防止

### 8.4 データ保護

- **暗号化通信**: HTTPS/TLS
- **個人情報最小化**: 必要最小限の情報のみ収集
- **データ削除**: ユーザーアカウント削除時に全データ削除

-----

## 9. 広告実装

### 9.1 広告種類

#### バナー広告(メイン)

- タイムライン内に10投稿ごとに表示
- Google AdMob

#### 将来的な広告(Phase 3以降)

- インタースティシャル広告
- リワード広告

### 9.2 AdMob統合

1. Google AdMobアカウント作成
1. 広告ユニット作成
1. Flutter SDKインテグレーション(`google_mobile_ads`)
1. テスト広告で動作確認
1. 本番広告ユニットに切り替え

### 9.3 収益想定

- **1,000 MAU**: 月間約¥30,000
- **10,000 MAU**: 月間約¥300,000
- **50,000 MAU**: 月間約¥1,500,000

**計算根拠**:

- 1ユーザーあたり1日10セッション
- eCPM(広告1000表示あたりの収益): ¥100

-----

## 10. 開発スケジュール

### 目標リリース日

**8週間後(約2ヶ月)**

### Week 1-2: セットアップ・認証

- [ ] Supabaseプロジェクト作成
- [ ] データベーススキーマ実装
- [ ] Row Level Security設定
- [ ] Flutterプロジェクト作成
- [ ] デザインシステム実装(Nirzカラー)
- [ ] SMS認証実装
- [ ] プロフィール設定画面

### Week 3-4: コア機能

- [ ] 位置情報取得機能
- [ ] 市区町村判定ロジック
- [ ] 投稿作成機能
- [ ] 画像アップロード
- [ ] タイムライン表示
- [ ] いいね・コメント機能

### Week 5-6: マップ・仕上げ

- [ ] Google Maps統合
- [ ] マップビュー実装
- [ ] ピン表示・クラスタリング
- [ ] 投稿詳細画面
- [ ] ブロック・通報機能
- [ ] AdMob統合
- [ ] 最終デザイン調整

### Week 7: テスト・リリース準備

- [ ] 総合テスト
- [ ] パフォーマンス最適化
- [ ] バグ修正
- [ ] ストアアセット準備
  - [ ] スクリーンショット
  - [ ] プロモーション動画
  - [ ] アプリ説明文
- [ ] プライバシーポリシー作成
- [ ] 利用規約作成
- [ ] App Store / Play Store申請

### Week 8: ローンチ準備

- [ ] SNSアカウント準備
- [ ] マーケティング素材作成
- [ ] ベータテスト実施
- [ ] 最終調整

-----

## 11. コスト試算

### 11.1 初期費用

|項目                     |金額         |
|-----------------------|-----------|
|ドメイン取得                 |¥1,000     |
|Apple Developer Program|¥15,000    |
|Google Play Console    |¥3,750     |
|SNS広告(初期)              |¥50,000    |
|**合計**                 |**¥69,750**|

### 11.2 月間運用コスト

#### 開発初期(〜1,000 MAU)

|項目             |金額           |
|---------------|-------------|
|Supabase       |¥0 (無料枠)     |
|Google Maps API|¥0 (無料枠)     |
|広告費            |¥20,000      |
|**合計**         |**¥20,000/月**|

#### 成長期(3,000〜10,000 MAU)

|項目             |金額           |
|---------------|-------------|
|Supabase Pro   |¥3,750       |
|Google Maps API|¥3,000       |
|広告費            |¥50,000      |
|その他            |¥1,000       |
|**合計**         |**¥57,750/月**|

### 11.3 収益想定(AdMob)

|MAU   |月間収益      |
|------|----------|
|1,000 |¥30,000   |
|10,000|¥300,000  |
|50,000|¥1,500,000|

**→ 1,000 MAU達成時点で黒字化可能**

-----

## 12. リスクと対策

### 12.1 技術的リスク

|リスク              |影響度|対策                       |
|-----------------|---|-------------------------|
|位置情報取得の精度問題      |中  |複数の位置情報ソースを使用、エラーハンドリング強化|
|Supabase無料枠超過    |高  |早期にProプラン移行、データ圧縮・最適化    |
|画像アップロード遅延       |中  |画像圧縮・リサイズ実装、プログレスバー表示    |
|Google Maps API制限|中  |キャッシュ活用、API呼び出し最適化       |

### 12.2 ビジネスリスク

|リスク       |影響度|対策                     |
|----------|---|----------------------|
|ユーザー獲得難航  |高  |SNSマーケティング強化、インフルエンサー活用|
|不適切コンテンツ問題|高  |通報機能強化、モデレーション体制構築     |
|競合サービス出現  |中  |独自機能・UX差別化、コミュニティ形成    |
|収益化の遅れ    |中  |早期のプレミアムプラン導入検討        |

### 12.3 法的リスク

|リスク      |影響度|対策                  |
|---------|---|---------------------|
|個人情報保護法違反|高  |プライバシーポリシー整備、専門家レビュー|
|位置情報不正利用 |高  |位置情報取扱いの透明化、ユーザー同意取得|
|出会い系規制該当 |中  |利用規約で明確化、年齢確認徹底     |
|著作権侵害    |中  |通報機能、著作権ガイドライン提示    |

-----

## 13. マーケティング戦略

### 13.1 ローンチ前プロモーション(1ヶ月前)

#### SNSアカウント開設

**Twitter**

- フォロワー獲得キャンペーン
- カウントダウン投稿
- 使い方Tips

**Instagram**

- ビジュアルでアプリの使い方紹介
- ストーリーズで舞台裏
- リール動画

**TikTok**

- 15秒でわかるNirz
- 使い方ショート動画
- Z世代向けコンテンツ

#### その他

- 大学内ポスター掲示(許可が取れれば)
- 大学生コミュニティへのアプローチ

### 13.2 ローンチ時プロモーション

- [ ] プレスリリース配信
- [ ] SNS広告(Instagram、TikTok)
- [ ] インフルエンサーマーケティング
  - 大学生系YouTuber/TikToker
  - フォロワー1-10万規模
- [ ] ローンチキャンペーン
  - 「#Nirzで繋がろう」ハッシュタグ
  - 初期ユーザー特典(限定バッジなど)

### 13.3 グロース戦略

- 大学別コミュニティ形成
- イベント連携(学祭、サークルイベント)
- 口コミ促進(招待コード制度)
- ユーザー投稿事例紹介

### 13.4 目標KPI

|期間  |MAU目標 |対象エリア |
|----|------|------|
|1ヶ月目|500   |都内主要大学|
|3ヶ月目|3,000 |都内全大学 |
|6ヶ月目|10,000|関東圏   |
|1年目 |50,000|全国主要都市|

-----

## 14. 今後の検討事項

### 14.1 未決定事項

- [ ] 詳細なマーケティング予算配分
- [ ] インフルエンサー選定
- [ ] カスタマーサポート体制
- [ ] コミュニティガイドライン策定

### 14.2 Phase 2以降の機能詳細

- [ ] プッシュ通知の最適化
- [ ] ハッシュタグアルゴリズム
- [ ] DM機能の仕様詳細
- [ ] プレミアムプランの価格設定

### 14.3 スケール時の技術検討

- [ ] Cloud Functions(Edge Functions)活用
- [ ] CDN最適化
- [ ] データベースパーティショニング
- [ ] キャッシュ戦略の高度化
- [ ] マイクロサービス化検討

-----

## まとめ

本要件定義書に基づき、**8週間(約2ヶ月)でMVPリリース**を目指します。

### 主要なポイント

✅ **コスト削減**: Supabase活用により開発・運用コストを大幅削減
✅ **クロスプラットフォーム**: Flutter採用によりiOS/Android同時開発
✅ **ストレージ最適化**: 24時間限定投稿でストレージコスト抑制
✅ **早期黒字化**: AdMob広告で1,000 MAU達成時点で黒字化可能
✅ **スピード重視**: シンプルな機能でスピード重視の開発
✅ **Z世代最適化**: ターゲットに合わせたUI/UX・マーケティン
