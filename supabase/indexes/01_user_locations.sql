-- user_locations 地理空間インデックス
CREATE INDEX idx_user_locations_geography ON user_locations USING GIST(location);
