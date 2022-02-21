import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pkce/pkce.dart';

import 'package:url_launcher/url_launcher.dart';

const clientId = "1b78f428d727449ebfd41a50f32861be";
const scope =
    "user-read-private user-read-playback-state user-modify-playback-state user-read-currently-playing";

class SpotifyToken {
  final String accessToken;
  final int expiresIn;
  final String refreshToken;

  final int initialTime;

  SpotifyToken(
      {required this.accessToken,
      required this.expiresIn,
      required this.initialTime,
      required this.refreshToken});
}

Future<SpotifyToken> getInitialSpotifyToken(
    PkcePair pair, String code, String redirect_uri) async {
  final response = await http
      .post(Uri.parse("https://accounts.spotify.com/api/token"), body: {
    "code": code,
    "redirect_uri": redirect_uri,
    "grant_type": "authorization_code",
    "client_id": clientId,
    "code_verifier": pair.codeVerifier
  });

  final parsed = jsonDecode(response.body);

  return SpotifyToken(
      accessToken: parsed["access_token"],
      expiresIn: parsed["expires_in"],
      initialTime: DateTime.now().millisecondsSinceEpoch,
      refreshToken: parsed["refresh_token"]);
}

/// An error from this function should indicate that the refresh token has been invalidated
Future<SpotifyToken?> exchangeRefreshToken(String refresh_token) async {
  try {
    final response = await http
        .post(Uri.parse("https://accounts.spotify.com/api/token"), body: {
      "grant_type": "refresh_token",
      "refresh_token": refresh_token,
      "client_id": clientId,
    });

    final parsed = jsonDecode(response.body);

    return SpotifyToken(
        accessToken: parsed["access_token"],
        expiresIn: parsed["expires_in"],
        initialTime: DateTime.now().millisecondsSinceEpoch,
        refreshToken: refresh_token);
  } catch (e) {
    return null;
  }
}

String getSpotifyAuthUrl(PkcePair pair, String state, String redirect_uri) {
  return Uri.parse(
          "https://accounts.spotify.com/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirect_uri&state=$state&scope=$scope&code_challenge=${pair.codeChallenge}&code_challenge_method=S256")
      .toString();
}

Future<void> launchUrl(String url) async {
  if (!await launch(url)) throw "Could not launch $url";
}
