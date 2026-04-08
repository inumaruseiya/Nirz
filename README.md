# nirz（Nirz）

Flutter と [Supabase](https://supabase.com/)（PostgreSQL / PostGIS・Auth・Storage）を使った**ローカルSNS**のクライアントです。現在地を基準に半径 5km 以内の投稿を閲覧・投稿し、位置はクライアント側でぼかしてから保存します（マッチング機能はありません）。

詳細な要件・設計は [`docs/requirements-local-sns-flutter-supabase.md`](docs/requirements-local-sns-flutter-supabase.md) などのドキュメントを参照してください。

## 前提

- [Flutter](https://docs.flutter.dev/get-started/install)（本リポジトリは SDK `^3.10.8` 想定）
- バックエンドをローカルで動かす場合: [Supabase CLI](https://supabase.com/docs/guides/cli)

## ローカルでの立ち上げ方（アプリ）

リポジトリ直下で依存関係を取得し、`--dart-define` で Supabase の URL と anon キーを渡して実行します（**実キーはリポジトリにコミットしない**こと）。

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

キー名のテンプレートは [`.env.example`](.env.example) を参照してください。IDE の実行構成では「Additional run args」等に同じ `--dart-define=...` を設定します。

未設定の場合、アプリは Supabase 初期化をスキップして起動します（ログインなどバックエンド連携は動きません）。

## dev 環境の立ち上げ方

「開発用」の Supabase プロジェクト（チームのステージングや個人用の dev プロジェクトなど）を用意し、その **Project URL** と **anon public key** を上記の `--dart-define` に渡して `flutter run` または `flutter build` します。

- Supabase ダッシュボードでの Auth 設定（メール / OAuth など）は [`docs/supabase-auth-dashboard.md`](docs/supabase-auth-dashboard.md) を参照してください。

### バックエンドもローカルで動かす場合（Supabase CLI）

```bash
supabase start
supabase db reset   # マイグレーション適用（初回・スキーマ更新時）
```

`supabase status` で表示される **API URL**（例: `http://127.0.0.1:54321`）と **anon key** を `SUPABASE_URL` / `SUPABASE_ANON_KEY` に指定して Flutter を起動します。

## Prod 環境の立ち上げ方（リリースビルド）

本番用 Supabase プロジェクトの URL / anon キーを使い、**リリース**向けビルドを作成します（キーは CI のシークレットやローカルの安全な環境変数から渡し、リポジトリに含めない）。

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://YOUR_PROD_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PROD_ANON_KEY
```

iOS の場合は `flutter build ipa`、Web は `flutter build web` など、配布ターゲットに合わせてコマンドを選んでください。本番プロジェクト側の Auth リダイレクト URL・プロバイダ設定も、[`docs/supabase-auth-dashboard.md`](docs/supabase-auth-dashboard.md) に沿って本番用に整えてください。

## CI

`main` 向けの Pull Request では、GitHub Actions で `flutter analyze` / `flutter test` と、ローカル Supabase スタックを使ったマイグレーション検証が走ります（[`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)）。
