# Supabase Auth（ダッシュボード）設定 — Phase 1-6

| 項目 | 内容 |
|------|------|
| 対象 | 実装計画 [Phase 1-6](./implementation-plan.md#1-6-supabase-auth-設定)（`1-6-1`〜`1-6-3`） |
| 前提 | Supabase プロジェクトが作成済みであること |
| 備考 | 本手順は **SQL マイグレーションでは代替できない**（Dashboard / Management API で実施） |

Flutter クライアント側の接続方法は [`AGENTS.md`](../AGENTS.md) およびルートの [`.env.example`](../.env.example)（`--dart-define=SUPABASE_URL` / `SUPABASE_ANON_KEY`）に従う。

---

## 1-6-1. メール認証の有効化（FR-AUTH-01）

1. [Supabase Dashboard](https://supabase.com/dashboard) で対象プロジェクトを開く。
2. **Authentication** → **Providers**（または **Sign In / Providers**）を開く。
3. **Email** を有効にする（**Enable Email provider** を ON）。
4. 必要に応じて **Confirm email**（メール確認を必須にする）をプロダクト方針に合わせて ON/OFF する。  
   - ON の場合: サインアップ後に確認メール経由でアクティブ化（`1-6-3` とセットで設定）。
5. 変更を保存する。

公式: [Email Auth](https://supabase.com/docs/guides/auth/auth-email)

---

## 1-6-2. OAuth プロバイダ（任意・FR-AUTH-01）

Google / Apple 等を使う場合のみ実施する。

1. **Authentication** → **Providers** で該当プロバイダ（例: **Google**, **Apple**）を開く。
2. プロバイダの開発者コンソールで取得した **Client ID** / **Client Secret**（該当する場合）を Dashboard に入力する。
3. リダイレクト URI は Dashboard に表示される **Callback URL** をプロバイダ側の許可リストに登録する。
4. 有効化して保存する。

公式: [Social Login](https://supabase.com/docs/guides/auth/social-login)

本リポジトリでは、モバイル向けの既定コールバック URI を [`lib/config/auth_deep_link_config.dart`](../lib/config/auth_deep_link_config.dart) に定義し、Android / iOS / macOS の URL スキーム登録と一致させている（現在の値: `io.nirz.app://auth-callback/`）。**Authentication → URL Configuration → Redirect URLs** に同じ文字列（末尾の `/` を含む）を追加すること。`supabase_flutter` が PKCE フローを扱うため、OAuth 開始時はコード側で `redirectTo` をこの URI に合わせる（実装は [`SupabaseAuthRepository`](../lib/infrastructure/supabase/supabase_auth_repository.dart)）。

---

## 1-6-3. メール確認フロー（FR-AUTH-01）

メール確認を必須にしている場合に必須となる設定。

1. **Authentication** → **Email Templates**（またはテンプレート設定）で **Confirm signup** 等の文面を確認・編集する。
2. **Authentication** → **URL Configuration** で次を設定する。
   - **Site URL**: 本番・開発のベース URL（例: カスタムスキームの Flutter アプリなら `io.supabase.yourapp://login-callback` など、プロジェクトで決めた値）。
   - **Redirect URLs**: 確認メールのリンクから許可するリダイレクト先を **ワイルドカード含め** 必要な分だけ列挙する（開発用 `localhost`、本番ドメイン、アプリのコールバック URL 等）。

確認リンクはこの許可リストに含まれない URL へ飛ぶと拒否されるため、**開発・ステージング・本番** それぞれで漏れがないか確認する。

公式: [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)

---

## 実装後の確認チェックリスト

- [ ] Email サインアップ / ログインが想定どおり動く（確認メール ON の場合はメール受信〜リンク確認まで）。
- [ ] 有効にした OAuth がログイン〜セッション確立まで通る（Redirect URLs に `io.nirz.app://auth-callback/` が登録されていること）。
- [ ] `.env.example` と同様に、クライアントは **anon key のみ** を使い、サービスロールキーをアプリに埋め込まない。

---

## 改訂履歴

| 版 | 日付 | 内容 |
|----|------|------|
| 1.0 | 2026-04-01 | 初版（Phase 1-6 ドキュメント化） |
