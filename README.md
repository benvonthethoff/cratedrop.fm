# Daily Crate

A daily music discovery app that drops exactly 10 songs from small artists every day at midnight.

## Project Overview

**TYPE:** 1-page mobile-first web app  
**STACK:** Next.js (App Router) + TypeScript + Tailwind + shadcn/ui + Supabase (Postgres + Edge Functions + Cron) + Spotify Web API

## Goal (MVP)

- Every day at 00:00 local, publish a "crate drop" of EXACTLY 10 songs by SMALL artists
- "Small artist" = followers < 50,000 AND popularity < 60 (Spotify metrics)
- Selection is RANDOM from our stored pool; zero personalisation
- The page shows a simple list (artwork, Artist — Track), numbered 1..10
- A Spotify playlist is created/updated daily with those 10 tracks
- The page embeds that playlist at the bottom so playback "feels native"

## What Users See

- **Header:** "Daily Crate" + date (YYYY-MM-DD) + a single "Play today's list" button (links to playlist URL)
- **List:** 10 rows, each with: small square artwork (48px), bold artist, track title underneath, tap opens track on Spotify
- **Footer:** Spotify playlist embed (iframe)
- No menus, no likes, no history (for MVP)

## Data Flow (Simple)

- **Weekly job `build_pool`:** hit Spotify → collect small artists from seed playlists → store into Supabase:
  - `artist_pool(artist_id, name, followers, popularity, genres, last_release)`
  - `track_pool(track_id, artist_id, name, isrc, popularity, album_art_url, spotify_url, market)`
- **Daily job `daily_drop`:** sample 10 unique artists → take top track #1 → write `daily_crate(crate_date, position, track_id, artist_id, playlist_id)` → update Spotify playlist
- **Frontend** reads today via a single endpoint and renders

## Supabase Tables (MVP)

```sql
spotify_host(id:boolean PK default true, user_id text, refresh_token text)
seed_playlists(id text PK, label text)
artist_pool(artist_id text PK, name text, followers int, popularity int, genres text[], last_release date, added_at timestamptz)
track_pool(track_id text PK, artist_id text FK, name text, isrc text, popularity int, album_art_url text, spotify_url text, market text default 'AU')
daily_crate(crate_date date, position smallint, track_id text FK, artist_id text FK, playlist_id text, PRIMARY KEY(crate_date, position))
```

## Edge Functions (MVP)

- **`build_pool`:** weekly (refresh artist_pool + track_pool from seed playlists; apply filters; upserts)
- **`daily_drop`:** daily 00:00 (sample 10; write daily_crate; create/replace Spotify playlist)
- **`get_today`:** read API; returns `{ date, playlistId, playlistUrl, items:[{position, artist, track, trackId, albumArt, spotifyUrl}] }`

## Environment Variables

Both Supabase + Vercel need:

```bash
SPOTIFY_CLIENT_ID=xxxxx
SPOTIFY_CLIENT_SECRET=xxxxx
SPOTIFY_MARKET=AU  # or AR
SPOTIFY_REDIRECT_URI=https://<your-edge-fn>/callback  # used once to fetch refresh token
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...  # for Edge Functions if needed
```

## One-Time OAuth (Host Account)

- **Scopes:** playlist-modify-public (or private)
- Do Authorization Code flow once; store refresh_token + user_id into spotify_host table

## Scheduling

- **Supabase Scheduled Jobs:**
  - `build_pool` → weekly Sun 02:00 local
  - `daily_drop` → daily 00:00 local
- `get_today` is on-demand (called by the site)

## Non-Goals (MVP)

- No user accounts or personalisation
- No rating/likes/history (archive can come later)
- No admin UI; seed playlists inserted manually in DB

## Quality Bounds

- If an artist has no top tracks in market → redraw
- Ensure 10 unique tracks (de-dupe by track_id / ISRC)
- Only choose from artists with releases within last 24 months (prevents dead acts)

## Accessibility & Performance

- Mobile-first; tap targets ≥ 44px; system font stack; lazy-load images; no blocking JS
- Embed is below the fold; list should be usable without the embed

## Branding

- Name TBD (e.g., "CrateDrop" / "Daily Crate")
- Minimalist aesthetic; no logo required for MVP 