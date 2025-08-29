import { NextResponse } from 'next/server';

export async function GET() {
  const clientId = process.env.SPOTIFY_CLIENT_ID;
  const redirectUri = process.env.SPOTIFY_REDIRECT_URI;

  if (!clientId || !redirectUri) {
    return NextResponse.json(
      { error: 'Missing Spotify configuration' },
      { status: 500 }
    );
  }

  const spotifyAuthUrl = new URL('https://accounts.spotify.com/authorize');
  spotifyAuthUrl.searchParams.set('response_type', 'code');
  spotifyAuthUrl.searchParams.set('scope', 'playlist-modify-public');
  spotifyAuthUrl.searchParams.set('client_id', clientId);
  spotifyAuthUrl.searchParams.set('redirect_uri', redirectUri);

  return NextResponse.redirect(spotifyAuthUrl.toString());
} 