import { NextRequest, NextResponse } from 'next/server';
import { supabase } from "@/lib/supabase";

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const code = searchParams.get('code');

  if (!code) {
    return NextResponse.json({ error: 'Missing authorization code' }, { status: 400 });
  }

  try {
    // Exchange authorization code for access token
    const tokenResponse = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(
          `${process.env.SPOTIFY_CLIENT_ID}:${process.env.SPOTIFY_CLIENT_SECRET}`
        ).toString('base64')}`
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: process.env.SPOTIFY_REDIRECT_URI!
      })
    });

    if (!tokenResponse.ok) {
      const errorData = await tokenResponse.text();
      console.error('Token exchange failed:', errorData);
      return NextResponse.json({ error: 'Failed to exchange authorization code' }, { status: 400 });
    }

    const tokenData = await tokenResponse.json();
    const { access_token, refresh_token } = tokenData;

    if (!access_token) {
      return NextResponse.json({ error: 'No access token received' }, { status: 400 });
    }

    // Get user profile from Spotify
    const meResponse = await fetch('https://api.spotify.com/v1/me', {
      headers: {
        'Authorization': `Bearer ${access_token}`
      }
    });

    if (!meResponse.ok) {
      return NextResponse.json({ error: 'Failed to fetch user profile' }, { status: 400 });
    }

    const meData = await meResponse.json();

    // Upsert user data into Supabase
    const { error: upsertError } = await supabase
      .from('spotify_host')
      .upsert({
        id: meData.id,
        user_id: meData.id,
        refresh_token: refresh_token
      }, {
        onConflict: 'id'
      });

    if (upsertError) {
      console.error('Supabase upsert error:', upsertError);
      return NextResponse.json({ error: 'Failed to save user data' }, { status: 500 });
    }

    // Redirect to success page
    return NextResponse.redirect(new URL('/?ok=spotify-connected', request.url));

  } catch (error) {
    console.error('Callback error:', error);
    return NextResponse.json({ 
      error: error instanceof Error ? error.message : 'Unknown error' 
    }, { status: 500 });
  }
} 