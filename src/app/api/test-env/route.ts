import { NextResponse } from 'next/server';

export async function GET() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  
  // Get Spotify client ID and mask it for security
  const spotifyClientId = process.env.SPOTIFY_CLIENT_ID;
  const maskedSpotifyId = spotifyClientId 
    ? `${spotifyClientId.substring(0, 5)}***`
    : undefined;

  return NextResponse.json({
    NEXT_PUBLIC_SUPABASE_URL: supabaseUrl,
    SPOTIFY_CLIENT_ID: maskedSpotifyId
  });
} 