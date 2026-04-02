-- Phase 1-1: PostgreSQL extensions (implementation plan 1-1-1, 1-1-2)
-- PostGIS: geography / spatial queries for local feed (NFR-SCALE-01, FR-FEED-01)
-- uuid-ossp: UUID generation for primary keys where needed

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
