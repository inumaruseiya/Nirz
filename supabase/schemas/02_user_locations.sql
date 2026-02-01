-- user_locations（ユーザー位置情報）
CREATE TABLE user_locations (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    city_code VARCHAR(10) NOT NULL,
    radius_km INT NOT NULL CHECK (radius_km IN (1, 5)),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
