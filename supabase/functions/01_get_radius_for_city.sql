-- 市区町村判定関数
-- 都市コードから表示範囲（1km or 5km）を決定
CREATE OR REPLACE FUNCTION get_radius_for_city(city_code VARCHAR)
RETURNS INT AS $$
BEGIN
    -- 東京都全域（13xxx）
    IF city_code LIKE '13%' THEN
        RETURN 1;
    END IF;

    -- 大阪府全域（27xxx）
    IF city_code LIKE '27%' THEN
        RETURN 1;
    END IF;

    -- 政令指定都市
    -- 横浜市、川崎市、名古屋市、福岡市、札幌市、仙台市、静岡市、浜松市
    -- 京都市、神戸市、岡山市、広島市、熊本市
    IF city_code IN (
        '14100', '14130', '23100', '40130', '01100',
        '04100', '22100', '22130', '26100', '28100',
        '33100', '34100', '43100'
    ) THEN
        RETURN 1;
    END IF;

    -- その他の地域
    RETURN 5;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
