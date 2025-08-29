# Cursor Build Rules — Daily Crate MVP

**DO NOT DEVIATE FROM THESE RULES - MVP SCOPE ONLY**

## 1. Project Structure (Next.js App Router)

```
/app/today/page.tsx              # main (and only) page
/app/api/health/route.ts         # simple ok probe
/lib/supabaseClient.ts           # browser supabase client (anon)
/lib/supabaseServer.ts           # server client for SSR if needed
/components/TrackItem.tsx        # single list row (artwork, artist, track)
/components/PlaylistEmbed.tsx    # spotify iframe wrapper
/styles/globals.css              # Tailwind
/supabase/functions/build_pool   # Edge Function (TypeScript)
/supabase/functions/daily_drop   # Edge Function (TypeScript)
/supabase/functions/get_today    # Edge Function (TypeScript)
/README_APP_OVERVIEW.txt
/README_CURSOR_BUILD_RULES.txt
```

## 2. UI & Design (shadcn/ui + Tailwind)

- Install shadcn/ui and only use minimal primitives: **Button**, **Card**, **Separator**
- **Layout rules:**
  - Single column, `max-w-md`, centred, `padding-x 16px`, `spacing-4/6`
  - **Header:** "Daily Crate", small subdued date line under it, and one primary Button: "Play today's list"
  - **List:** 10 items, each is a compact row (48px album art, bold artist, smaller track title). Rows are tappable links to the Spotify track URL
  - Number rows 1..10 visually (prefix number, monospace small)
  - **Footer:** PlaylistEmbed (iframe) with the playlistId from API
- **Typography:** system font; avoid custom fonts
- **Colours:** use default shadcn tokens; no custom palettes for MVP
- **Icons:** none (unless absolutely necessary)

## 3. API Contract (get_today)

- GET call from frontend to Supabase Edge Function: `/functions/v1/get_today`
- **Response shape (STRICT):**
```json
{
  "date": "YYYY-MM-DD",
  "playlistId": "spotify:playlist:xxxx",
  "playlistUrl": "https://open.spotify.com/playlist/xxxx",
  "items": [
    { "position": 1, "artist": "Name", "track": "Title", "trackId": "id", "albumArt": "https://...", "spotifyUrl": "https://..." },
    ... (10 total)
  ]
}
```
- Frontend must render exactly 10 items in order

## 4. Edge Function Behaviour

### build_pool (WEEKLY)
- Read `seed_playlists` table → fetch playlist tracks → collect artist IDs
- For each artist: fetch artist → keep if `followers < 50000` AND `popularity < 60` AND has release in last 24 months
- Upsert into `artist_pool`
- For each kept artist: fetch `top-tracks?market=SPOTIFY_MARKET` → take top 1–3; upsert into `track_pool`
- Deduplicate by `artist_id` and `track_id`; store album art + spotify URLs

### daily_drop (DAILY 00:00)
- Sample 10 distinct artists from `artist_pool`
- Select their top track #1 from `track_pool` (market-specific)
- Ensure uniqueness by `track_id` / ISRC. Redraw if duped
- Write `daily_crate` rows (`crate_date=TODAY`, position 1..10)
- Using `spotify_host.refresh_token` + `user_id`:
  - Create or find "Daily Crate – YYYY-MM-DD"
  - Replace playlist items with the 10 tracks (in order)
  - Save `playlist_id` back into `daily_crate` rows

### get_today (READ)
- Query `daily_crate` for TODAY, join `track_pool` + `artist_pool`, return strict contract above
- If empty (race), return HTTP 503 with `{ message: "Daily crate not ready" }`

## 5. Spotify Usage

- Use **Client Credentials** for read-only Spotify calls (server-side ONLY)
- Use stored `refresh_token` from `spotify_host` for playlist modify calls
- Market must come from env `SPOTIFY_MARKET` (default 'AU')

## 6. Seed Playlists (Manual Insert OK)

- `seed_playlists` table should include 2–5 trusted discovery lists (e.g., Fresh Finds)
- **Cursor MUST NOT hardcode third-party playlist IDs in code; read from DB**

## 7. Coding Standards

- **TypeScript everywhere. Strict types. No `any`**
- **Server-only secrets. Never expose client secret in the browser**
- Functions must return typed results; throw typed errors with messages
- **No extraneous dependencies beyond:**
  - `next`, `react`, `typescript`, `tailwindcss`, `@tanstack/react-query` (optional), `shadcn/ui`, `zod` (optional), `supabase-js`
- Disable revalidation cache for today's fetch or set small revalidate (≤ 60s)

## 8. Acceptance Tests (Manual)

**With tables prefilled and daily_crate written:**
- `/today` loads within 1s TTI on mobile
- Displays exactly 10 rows, numbered, with artwork and correct links
- "Play today's list" opens the playlist URL
- Embed renders and plays

**With no daily_crate (before midnight job):** shows a friendly "Today's crate is loading, check back soon" state (no errors)

## 9. Out of Scope (DO NOT BUILD)

- User auth, settings, likes, comments, history pages
- Admin dashboards or pool editors
- Personalised recommendations
- Full-text search, infinite scroll, multiple routes

## 10. Commands (Reference)

### shadcn setup:
```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card separator
```

### Tailwind:
```bash
npx tailwindcss init -p
```

### Supabase:
```bash
supabase login
supabase start
supabase functions deploy build_pool
supabase functions deploy daily_drop
supabase functions deploy get_today
```

### Vercel (optional):
```bash
vercel link
vercel env pull
vercel deploy
``` 