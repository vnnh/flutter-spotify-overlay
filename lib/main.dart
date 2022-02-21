import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_spotify_overlay/auth/auth.dart';
import 'package:flutter_spotify_overlay/auth/random.dart';
import 'package:flutter_spotify_overlay/auth/server.dart';
import 'package:flutter_spotify_overlay/spotify/control.dart';
import 'package:flutter_spotify_overlay/spotify/currently_playing_track.dart';
import 'package:flutter_spotify_overlay/spotify/duration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pkce/pkce.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

const secureStorage = FlutterSecureStorage();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();

  runApp(const MyApp());

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(300, 100);
      appWindow
        ..minSize = initialSize
        ..size = initialSize
        ..alignment = Alignment.center
        ..title = "spotify-overlay"
        ..show();
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  HttpServer? server;
  String? currentState;
  bool authenticated = false;
  SpotifyToken? token;

  Future<void> closeServer() async {
    if (server != null) {
      await server!.close();
    }

    server = null;
  }

  Function(String) onPairAuthorization(PkcePair pair, String redirect_uri) {
    return (String code) async {
      final token = await getInitialSpotifyToken(pair, code, redirect_uri);
      this.token = token;

      await secureStorage.write(
          key: "refresh_token", value: token.refreshToken);

      setState(() {
        authenticated = true;
      });
    };
  }

  void launchAuthorization() async {
    final pair = PkcePair.generate();
    String redirect_uri = "";

    await closeServer();
    if (server == null) {
      server = await startReceiveServer();
      redirect_uri =
          "http://${server!.address.address}:${server!.port.toString()}";

      print(
          "Server running on IP ${server!.address.address}:${server!.port.toString()}");

      listenToServer(server!, onPairAuthorization(pair, redirect_uri),
          (state) => currentState == state, closeServer);
    }

    currentState = generateState();
    await launchUrl(getSpotifyAuthUrl(pair, currentState!, redirect_uri));
  }

  @override
  void initState() {
    super.initState();

    secureStorage.read(key: "refresh_token").then((value) async {
      if (value != null) {
        token = await exchangeRefreshToken(value);
        if (token == null) {
          await secureStorage.delete(key: "refresh_token");
          setState(() {
            authenticated = false;
          });
        } else {
          setState(() {
            authenticated = true;
          });
        }
      }
    });
  }

  @override
  void dispose() async {
    await closeServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Window.setEffect(
        effect: WindowEffect.aero,
        color: Color.fromARGB(0, 255, 255, 255),
        dark: true);

    WindowsTaskbar.setThumbnailToolbar(
      [
        ThumbnailToolbarButton(
            ThumbnailToolbarAssetIcon("assets/logout.ico"), 'Logout', () async {
          if (authenticated) {
            await secureStorage.delete(key: "refresh_token");
            setState(() {
              authenticated = false;
            });
          }
        }, mode: authenticated ? 0 : ThumbnailToolbarButtonMode.disabled),
      ],
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            backgroundColor: Colors.transparent,
            body: MoveWindow(
                child: authenticated
                    ? PlaybackWindow(token: token!)
                    : AuthenticateWindow(
                        launchAuthorization: launchAuthorization))));
  }
}

class _PlaybackWindowState extends State<PlaybackWindow>
    with TickerProviderStateMixin {
  Timer? timer;
  String? lastPlaybackImage;
  CrossFadeState currentCrossFade = CrossFadeState.showFirst;
  CurrentlyPlayingTrack? playbackState;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();

    checkIfPremium(widget.token).then((value) {
      setState(() {
        isPremium = value;
      });
    });

    var secondsElapsed = 4;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      secondsElapsed += 1;
      if (secondsElapsed >= 4) {
        secondsElapsed = 0;

        final playbackState = await getPlaybackState(widget.token);
        setState(() {
          if (playbackState?.item?.album?.image.url !=
              this.playbackState?.item?.album?.image.url) {
            currentCrossFade = currentCrossFade == CrossFadeState.showFirst
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst;

            lastPlaybackImage = this.playbackState?.item?.album?.image.url;
          }

          this.playbackState = playbackState;
        });
      } else {
        if (playbackState != null && playbackState!.isPlaying) {
          setState(() {
            playbackState!.progressMs += 1000;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (timer != null) {
      timer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstImage = currentCrossFade == CrossFadeState.showFirst
        ? playbackState?.item?.album?.image.url
        : lastPlaybackImage ?? playbackState?.item?.album?.image.url;

    final secondImage = currentCrossFade == CrossFadeState.showSecond
        ? playbackState?.item?.album?.image.url
        : lastPlaybackImage ?? playbackState?.item?.album?.image.url;

    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.topCenter,
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black, width: 0.0))),
        child: playbackState != null
            ? playbackState!.item != null
                ? Stack(children: [
                    Opacity(
                        opacity: 0.5,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                              begin: Colors.white,
                              end: playbackState!.isPlaying
                                  ? Color.fromARGB(255, 255, 255, 255)
                                  : Color.fromARGB(255, 94, 94, 94)),
                          duration: const Duration(milliseconds: 500),
                          builder: (_, color, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(colors: [
                                  color!,
                                  color,
                                ]).createShader(bounds);
                              },
                              child: child!,
                            );
                          },
                          child: AnimatedCrossFade(
                              firstChild: Image.network(
                                firstImage ??
                                    "https://pbs.twimg.com/media/FF12yU4akAAfOwC?format=jpg&name=medium",
                                alignment: Alignment.center,
                                fit: BoxFit.cover,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                              ),
                              secondChild: Image.network(
                                secondImage ??
                                    "https://pbs.twimg.com/media/FF12yU4akAAfOwC?format=jpg&name=medium",
                                alignment: Alignment.center,
                                fit: BoxFit.cover,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                              ),
                              crossFadeState: currentCrossFade,
                              duration: const Duration(milliseconds: 300)),
                        )),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (widget, children) {
                        late final AnimationController _controller =
                            AnimationController(
                          duration: const Duration(seconds: 2),
                          vsync: this,
                        );
                        return Align(
                            alignment: MediaQuery.of(context).size.height >= 120
                                ? Alignment.center
                                : Alignment.centerLeft,
                            child: widget!);
                      },
                      child: MediaQuery.of(context).size.height >= 120
                          ? TallPlaybackWindow(
                              key: const Key("PlaybackWindow"),
                              playbackState: playbackState!,
                              isPremium: isPremium,
                              token: widget.token,
                            )
                          : ShortPlaybackWindow(
                              key: const Key("PlaybackWindow"),
                              playbackState: playbackState!,
                            ),
                    )
                  ])
                : const AdPlaybackWindow()
            : const NullPlaybackWindow());
  }
}

class PlaybackWindow extends StatefulWidget {
  final SpotifyToken token;

  const PlaybackWindow({Key? key, required this.token}) : super(key: key);

  @override
  State<PlaybackWindow> createState() => _PlaybackWindowState();
}

class TallPlaybackWindow extends StatelessWidget {
  final CurrentlyPlayingTrack playbackState;
  final SpotifyToken token;
  final bool isPremium;

  const TallPlaybackWindow(
      {Key? key,
      required this.playbackState,
      required this.isPremium,
      required this.token})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TitleLabel(title: playbackState.item!.name),
          Text(
            playbackState.item!.artists.map((e) => e.name).join(", "),
            overflow: TextOverflow.fade,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getStringTime(
                        Duration(milliseconds: playbackState.progressMs)),
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: LinearProgressIndicator(
                        value: playbackState.progressMs /
                            playbackState.item!.durationMs,
                        backgroundColor: Color.fromARGB(100, 255, 255, 255),
                        color: Color.fromARGB(255, 255, 255, 255),
                        minHeight: 5,
                      )),
                  const SizedBox(width: 10),
                  Text(
                    getStringTime(
                        Duration(milliseconds: playbackState.item!.durationMs)),
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ],
              )),
          isPremium
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                        padding: EdgeInsets.zero,
                        splashRadius: 18,
                        onPressed: () async {
                          await skipToPrevious(token);
                        },
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Color.fromARGB(255, 255, 255, 255),
                          size: 24,
                        )),
                    IconButton(
                        padding: EdgeInsets.zero,
                        splashRadius: 24,
                        onPressed: () {
                          if (playbackState.isPlaying) {
                            pausePlayback(token);
                          } else {
                            resumePlayback(token);
                          }
                        },
                        icon: playbackState.isPlaying
                            ? const Icon(
                                Icons.pause_outlined,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 32,
                              )
                            : const Icon(
                                Icons.play_arrow,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 32,
                              )),
                    IconButton(
                        padding: EdgeInsets.zero,
                        splashRadius: 18,
                        onPressed: () {
                          skipToNext(token);
                        },
                        icon: const Icon(
                          Icons.skip_next,
                          color: Color.fromARGB(255, 255, 255, 255),
                          size: 24,
                        )),
                  ],
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }
}

class ShortPlaybackWindow extends StatelessWidget {
  final CurrentlyPlayingTrack playbackState;

  const ShortPlaybackWindow({Key? key, required this.playbackState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleLabel(title: playbackState.item!.name),
          Text(
            playbackState.item!.artists.map((e) => e.name).join(", "),
            overflow: TextOverflow.fade,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          )
        ],
      ),
    );
  }
}

class TitleLabel extends StatelessWidget {
  final String title;

  const TitleLabel({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: title));

        const snackBar = SnackBar(
          content: Text("Copied to clipboard"),
          duration: Duration(milliseconds: 300),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      child: Text(
        title,
        overflow: TextOverflow.fade,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          minimumSize: MaterialStateProperty.all(const Size(0, 0))),
    );
  }
}

class AdPlaybackWindow extends StatelessWidget {
  const AdPlaybackWindow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Ad",
      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
    );
  }
}

class NullPlaybackWindow extends StatelessWidget {
  const NullPlaybackWindow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Track unavailable",
      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
    );
  }
}

class AuthenticateWindow extends StatelessWidget {
  static var backgroundStartColor = Color.fromARGB(74, 75, 75, 75);
  static var backgroundEndColor = Color.fromARGB(74, 45, 45, 45);

  final Function launchAuthorization;

  const AuthenticateWindow({Key? key, required this.launchAuthorization})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundStartColor, backgroundEndColor],
              stops: [0.0, 1.0])),
      child: Center(
        child: OutlinedButton(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 300),
            shape: MaterialStateProperty.all(const ContinuousRectangleBorder()),
            backgroundColor: MaterialStateProperty.all(Colors.green.shade600),
            overlayColor: MaterialStateProperty.all(
                const Color.fromARGB(125, 46, 125, 50)),
          ),
          onPressed: () async {
            await launchAuthorization();
          },
          child: RichText(
              text: const TextSpan(
                  style: TextStyle(color: Colors.white),
                  children: [
                TextSpan(text: "Sign in with "),
                TextSpan(
                    text: "Spotify",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ])),
        ),
      ),
    );
  }
}
