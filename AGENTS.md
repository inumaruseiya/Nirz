# エージェント向け規約（AI / 自動化ツール）

このリポジトリで作業するエージェント（Cursor Agent 等）は、次の規約に従ってください。

## 実装の正本

- タスクの優先順位と粒度は **[`docs/implementation-plan.md`](docs/implementation-plan.md)** を正とする。
- 仕様の詳細は必要に応じて [`docs/requirements-local-sns-flutter-supabase.md`](docs/requirements-local-sns-flutter-supabase.md)、[`docs/system-design-local-sns-flutter-supabase.md`](docs/system-design-local-sns-flutter-supabase.md)、[`docs/detailed-design-local-sns-flutter-supabase.md`](docs/detailed-design-local-sns-flutter-supabase.md) を参照する。

## アーキテクチャとコード配置

- Flutter アプリは **クリーンアーキテクチャ**の層分けに従う: `lib/domain/`、`lib/application/`、`lib/infrastructure/`、`lib/presentation/`（[`docs/system-design-local-sns-flutter-supabase.md`](docs/system-design-local-sns-flutter-supabase.md) と実装計画 Phase 0-2）。
- 依頼されたタスクに必要なファイルだけを変更する。無関係なリファクタやドキュメントの追加はしない（ユーザーが明示した場合を除く）。

## Supabase

- **クライアント（Flutter）**: 接続情報は **`--dart-define=SUPABASE_URL=...`** と **`--dart-define=SUPABASE_ANON_KEY=...`** で渡す。定数は [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart) を経由する。実シークレットをリポジトリにコミットしない。ルートの [`.env.example`](.env.example) を参照。
- **バックエンド（スキーマ・RLS・RPC・Storage 等）**: **Supabase CLI の利用を推奨**する。マイグレーションやローカル検証が必要な場合は CLI で進めてよい（`supabase init`、`supabase start`、`migration` 管理など）。

## Git / PR

- 指示された作業ブランチで開発し、**別ブランチへの push はユーザーが明示した場合のみ**行う。
- 変更は意味のある単位でコミットし、リモートへ push する。コミットメッセージは英語でも日本語でもよいが、**何をしたかが一文で分かる**こと。
- PR のタイトル・本文をユーザーが GitHub 上で編集した場合、更新時は**人間の編集を尊重**する（明らかに古い・誤りの場合のみ調整）。

## 品質

- 変更後は可能な範囲で **`flutter analyze`** を実行し、問題を残さない。
- テストが存在する場合は **`flutter test`** を実行する。
- この環境で Flutter がパスに無い場合は、プロジェクト方針に合う SDK（例: Dart 3.10.x 系）で解析・テストを行う。

## 言語

- ユーザー向けの説明・コメント・ドキュメントは、**ユーザーが日本語を希望する場合は日本語**で書く（このファイルも日本語）。

## 不明点

- 仕様や優先度が曖昧なときは、実装計画書の該当 Phase に立ち返り、**推測で仕様を広げない**。必要ならユーザーに確認する。
