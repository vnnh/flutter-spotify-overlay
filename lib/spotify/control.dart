import 'dart:convert';

import 'package:flutter_spotify_overlay/auth/auth.dart';
import 'package:flutter_spotify_overlay/spotify/currently_playing_track.dart';
import 'package:http/http.dart' as http;

Future<bool> checkIfPremium(SpotifyToken token) async {
  final response =
      await http.get(Uri.parse("https://api.spotify.com/v1/me"), headers: {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": "Bearer ${token.accessToken}"
  });

  if (response.body == "") {
    return false;
  }

  return jsonDecode(response.body)["product"] == "premium";
}

Future<CurrentlyPlayingTrack?> getPlaybackState(SpotifyToken token) async {
  final response = await http.get(
      Uri.parse("https://api.spotify.com/v1/me/player/currently-playing"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer ${token.accessToken}"
      });

  if (response.body == "") {
    return null;
  }

  return CurrentlyPlayingTrack(data: jsonDecode(response.body));
}

Future<void> skipToPrevious(SpotifyToken token) async {
  http.post(Uri.parse("https://api.spotify.com/v1/me/player/previous"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${token.accessToken}"
      });
}

Future<void> resumePlayback(SpotifyToken token) async {
  await http
      .put(Uri.parse("https://api.spotify.com/v1/me/player/play"), headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${token.accessToken}"
  });
}

Future<void> pausePlayback(SpotifyToken token) async {
  await http
      .put(Uri.parse("https://api.spotify.com/v1/me/player/pause"), headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${token.accessToken}"
  });
}

Future<void> skipToNext(SpotifyToken token) async {
  await http
      .post(Uri.parse("https://api.spotify.com/v1/me/player/next"), headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${token.accessToken}"
  });
}
