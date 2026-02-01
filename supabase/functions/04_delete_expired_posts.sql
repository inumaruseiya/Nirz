-- 期限切れ投稿削除関数
-- 24時間経過した投稿を一括削除
CREATE OR REPLACE FUNCTION delete_expired_posts()
RETURNS void AS $$
BEGIN
    DELETE FROM posts WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- 定期実行設定（pg_cron）
-- pg_cron拡張を有効化後に実行してください
-- 毎時0分に期限切れ投稿を自動削除
--
-- SELECT cron.schedule(
--     'delete-expired-posts',
--     '0 * * * *',
--     $$SELECT delete_expired_posts()$$
-- );
