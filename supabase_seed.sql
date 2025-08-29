-- cratedrop.fm Database Schema
-- This file creates all the necessary tables for the cratedrop.fm app

-- Enable UUID extension for better ID management
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Spotify host account table (for OAuth credentials)
CREATE TABLE IF NOT EXISTS spotify_host (
    id BOOLEAN PRIMARY KEY DEFAULT true,
    user_id TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed playlists table (source playlists for artist discovery)
CREATE TABLE IF NOT EXISTS seed_playlists (
    id TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Artist pool table (filtered artists meeting criteria)
CREATE TABLE IF NOT EXISTS artist_pool (
    artist_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    followers INTEGER NOT NULL,
    popularity INTEGER NOT NULL,
    genres TEXT[] NOT NULL,
    last_release DATE NOT NULL,
    added_at TIMESTAMPTZ DEFAULT NOW()
);

-- Track pool table (top tracks from filtered artists)
CREATE TABLE IF NOT EXISTS track_pool (
    track_id TEXT PRIMARY KEY,
    artist_id TEXT NOT NULL REFERENCES artist_pool(artist_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    isrc TEXT,
    popularity INTEGER NOT NULL,
    album_art_url TEXT,
    spotify_url TEXT NOT NULL,
    market TEXT DEFAULT 'AU',
    added_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily crate table (daily selections)
CREATE TABLE IF NOT EXISTS daily_crate (
    crate_date DATE NOT NULL,
    position SMALLINT NOT NULL,
    track_id TEXT NOT NULL REFERENCES track_pool(track_id) ON DELETE CASCADE,
    artist_id TEXT NOT NULL REFERENCES artist_pool(artist_id) ON DELETE CASCADE,
    playlist_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (crate_date, position)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_artist_pool_followers ON artist_pool(followers);
CREATE INDEX IF NOT EXISTS idx_artist_pool_popularity ON artist_pool(popularity);
CREATE INDEX IF NOT EXISTS idx_artist_pool_last_release ON artist_pool(last_release);
CREATE INDEX IF NOT EXISTS idx_track_pool_artist_id ON track_pool(artist_id);
CREATE INDEX IF NOT EXISTS idx_track_pool_market ON track_pool(market);
CREATE INDEX IF NOT EXISTS idx_daily_crate_date ON daily_crate(crate_date);
CREATE INDEX IF NOT EXISTS idx_daily_crate_track_id ON daily_crate(track_id);

-- Add constraints
ALTER TABLE artist_pool ADD CONSTRAINT check_followers CHECK (followers >= 0);
ALTER TABLE artist_pool ADD CONSTRAINT check_popularity CHECK (popularity >= 0 AND popularity <= 100);
ALTER TABLE track_pool ADD CONSTRAINT check_popularity CHECK (popularity >= 0 AND popularity <= 100);
ALTER TABLE daily_crate ADD CONSTRAINT check_position CHECK (position >= 1 AND position <= 10);

-- Insert sample seed playlist (Fresh Finds - you can modify this)
INSERT INTO seed_playlists (id, label) VALUES 
('37i9dQZF1DXcBWIGoYBM5M', 'Fresh Finds')
ON CONFLICT (id) DO NOTHING;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at trigger to spotify_host
CREATE TRIGGER update_spotify_host_updated_at 
    BEFORE UPDATE ON spotify_host 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 