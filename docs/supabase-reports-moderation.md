# Supabase 通報の確認・対応（管理者）— Phase 10-2-4

| 項目 | 内容 |
|------|------|
| 対象 | 実装計画 [Phase 10-2-4](./implementation-plan.md#10-2-通報)（`reports` の一覧・`status` 管理） |
| 前提 | `reports` テーブルと RLS がマイグレーション適用済みであること（`10-2-3`） |
| 備考 | **サービスロールキー（`service_role`）を Flutter アプリや公開リポジトリに含めない**（[`AGENTS.md`](../AGENTS.md)） |

アプリからの通報保存の仕様（`target_type` / `target_id` / `reason` / `status`）は [`requirements-local-sns-flutter-supabase.md`](./requirements-local-sns-flutter-supabase.md) の FR-MOD-02 を参照する。

---

## `reports` テーブル（要点）

| 列 | 説明 |
|----|------|
| `id` | 通報行の UUID |
| `reporter_id` | 通報したユーザー（`auth.users.id`） |
| `target_type` | 例: `post`, `comment` |
| `target_id` | 対象の UUID（投稿 ID またはコメント ID） |
| `reason` | 通報理由（プリセット＋任意の補足が連結された文字列） |
| `status` | 初期値は `open`。運用で `reviewing` / `resolved` / `dismissed` などに更新してよい |
| `created_at` | 作成日時 |

一般ユーザー向け RLS では **自分が出した通報のみ** SELECT / INSERT 可能である。**全件の閲覧・更新はプロジェクト管理者が Dashboard または SQL で行う**（下記）。

---

## 方法 A: Table Editor（ダッシュボード UI）

1. [Supabase Dashboard](https://supabase.com/dashboard) で対象プロジェクトを開く。
2. **Table Editor** → **reports** を選択する。
3. 行をフィルタ・ソートして内容を確認する（例: `status` = `open`、`created_at` 降順）。
4. 対応が済んだ行の **`status`** を直接編集して保存する（運用で値の集合を決める。例: `open` → `resolved`）。

> Dashboard の Table Editor はプロジェクト権限により **RLS をバイパス**して全行を表示できる。チーム内で「誰が Table Editor を触れるか」を決めておく。

---

## 方法 B: SQL Editor（一覧・一括更新）

**SQL Editor** は管理者向け。ここで実行するクエリは **本番データを変更する**ため、実行前に内容を確認する。

### 未対応の通報を新しい順に一覧

```sql
SELECT
  id,
  reporter_id,
  target_type,
  target_id,
  reason,
  status,
  created_at
FROM public.reports
WHERE status = 'open'
ORDER BY created_at DESC;
```

### 1 件を対応済みにする（例）

```sql
UPDATE public.reports
SET status = 'resolved'
WHERE id = '00000000-0000-0000-0000-000000000000'::uuid;
```

`id` は一覧クエリで得た UUID に置き換える。

---

## 対応時の作業メモ（推奨）

- **対象コンテンツの確認**: `target_type` / `target_id` から、**Table Editor** で `posts` または `comments` を開き該当行を探す（UUID で検索）。
- **方針**: ガイドライン違反なら投稿・コメントの削除やユーザー停止など、別テーブル／Dashboard 操作と組み合わせる（本ドキュメントの範囲外）。
- **監査**: `status` と、社内ツールでメモを残す運用でもよい（DB に `moderator_note` 列を追加するのは任意の拡張）。

---

## 実装後の確認チェックリスト

- [ ] テストユーザーで通報を 1 件作成し、**SQL Editor** または **Table Editor** で行が見える。
- [ ] `status` を更新して保存できる。
- [ ] 一般ユーザーは **自分の通報以外** をアプリから読めない（RLS のままである）。

---

## 改訂履歴

| 版 | 日付 | 内容 |
|----|------|------|
| 1.0 | 2026-04-07 | 初版（Phase 10-2-4） |
