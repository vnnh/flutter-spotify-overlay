class CurrentlyPlayingTrack {
  ///data["context"]
  PlaybackContext? context;

  ///data["progress_ms"]
  int progressMs;

  ///data["currently_playing_type"]
  TrackType trackType;

  ///data["item"]
  PlaybackItem? item;

  ///data["actions"]["disallows"]
  ///interrupting_playback
  ///pausing
  ///resuming
  ///seeking
  ///skipping_next
  ///skipping_prev
  ///toggling_repeat_context
  ///toggling_shuffle
  ///toggling_repeat_track
  ///transferring_playback
  Map<String, bool> disallows;

  ///data["is_playing"]
  bool isPlaying;

  CurrentlyPlayingTrack({required Map<String, dynamic> data})
      : context = data["context"] != null
            ? PlaybackContext(
                spotifyUrl: data["context"]["external_urls"]["spotify"],
                href: data["context"]["href"],
                contextType:
                    ContextTypeExtension.fromName(data["context"]["type"]))
            : null,
        progressMs = data["progress_ms"],
        trackType = TrackTypeExtension.fromName(data["currently_playing_type"]),
        disallows = Map<String, bool>.from(data["actions"]["disallows"]),
        isPlaying = data["is_playing"] {
    if (trackType != TrackType.ad && trackType != TrackType.unknown) {
      item = PlaybackItem(item: data["item"]);
    }
  }
}

class PlaybackItem {
  ///item["name"]
  String name;

  ///item["album"]
  Album? album;

  ///item["artists"]
  late List<Artist> artists;

  ///item["disc_number"]
  int discNumber;

  ///item["duration_ms"]
  int durationMs;

  ///item["explicit"]
  bool explicit;

  ///item["external_urls"]["spotify"]
  String? spotifyUrl;

  ///item["href"]
  String? href;

  ///item["is_local"]
  bool isLocal;

  ///item["popularity"]
  int popularity;

  ///item["preview_url"]
  String? previewUrl;

  ///item["type"]
  ItemType type;

  PlaybackItem({required Map<String, dynamic> item})
      : name = item["name"],
        album = item["album"]["album_type"] != null
            ? Album(album: item["album"])
            : null,
        discNumber = item["disc_number"],
        durationMs = item["duration_ms"],
        explicit = item["explicit"],
        spotifyUrl = item["external_urls"]["spotify"],
        href = item["href"],
        isLocal = item["is_local"],
        popularity = item["popularity"],
        previewUrl = item["preview_url"],
        type = ItemType.track {
    artists = List<Map<String, dynamic>>.from(item["artists"])
        .map((e) => Artist(
            name: e["name"],
            spotifyUrl: e["external_urls"]["spotify"],
            href: e["href"],
            type: ArtistType.artist))
        .toList();
  }
}

class ItemImage {
  final int width;
  final int height;
  final String url;

  const ItemImage(
      {required this.url, required this.width, required this.height});
}

class Album {
  ///album["name"]
  String name;

  ///album["artists"]
  late List<Artist> artists;

  ///album["images"][0]
  ItemImage image;

  ///album["album_type"]
  AlbumType type;

  ///album["total_tracks"]
  int totalTracks;

  ///album["external_urls"]["spotify"]
  String spotifyUrl;

  ///album["href"]
  String href;

  ///album["release_date"]
  String releaseDate;

  ///album["release_date_precision"]
  ReleaseDatePrecision releaseDatePrecision;

  Album({required Map<String, dynamic> album})
      : name = album["name"],
        image = ItemImage(
            url: album["images"][0]["url"],
            width: album["images"][0]["width"],
            height: album["images"][0]["height"]),
        type = AlbumTypeExtension.fromName(album["album_type"]),
        totalTracks = album["total_tracks"],
        spotifyUrl = album["external_urls"]["spotify"],
        href = album["href"],
        releaseDate = album["release_date"],
        releaseDatePrecision = ReleaseDatePrecisionExtension.fromName(
            album["release_date_precision"]) {
    artists = List<Map<String, dynamic>>.from(album["artists"])
        .map((e) => Artist(
            name: e["name"],
            spotifyUrl: e["external_urls"]["spotify"],
            href: e["href"],
            type: ArtistType.artist))
        .toList();
  }
}

class Artist {
  ///artist["name"]
  final String name;

  ///artist["type"]
  final ArtistType type;

  ///artist["external_urls"]["spotify"]
  final String? spotifyUrl;

  ///artist["href"]
  final String? href;

  const Artist(
      {required this.name, this.spotifyUrl, this.href, required this.type});
}

class PlaybackContext {
  ///context["external_urls"]["spotify"]
  final String spotifyUrl;

  ///context["href"]
  final String href;

  ///context["type"]
  final ContextType contextType;

  const PlaybackContext(
      {required this.spotifyUrl,
      required this.href,
      required this.contextType});
}

enum AlbumType { album, single, compilation }

extension AlbumTypeExtension on AlbumType {
  static const names = {
    AlbumType.album: 'album',
    AlbumType.single: 'single',
    AlbumType.compilation: 'compilation',
  };

  String get name => names[this]!;

  static AlbumType fromName(String name) {
    for (var i = 0; i < names.values.length; i++) {
      if (names.values.elementAt(i) == name) {
        return names.keys.elementAt(i);
      }
    }

    return AlbumType.album;
  }
}

enum ReleaseDatePrecision { year, month, day }

extension ReleaseDatePrecisionExtension on ReleaseDatePrecision {
  static const names = {
    ReleaseDatePrecision.year: 'year',
    ReleaseDatePrecision.month: 'month',
    ReleaseDatePrecision.day: 'day',
  };

  String get name => names[this]!;

  static ReleaseDatePrecision fromName(String name) {
    for (var i = 0; i < names.values.length; i++) {
      if (names.values.elementAt(i) == name) {
        return names.keys.elementAt(i);
      }
    }

    return ReleaseDatePrecision.year;
  }
}

enum ContextType { artist, playlist, album, show }

extension ContextTypeExtension on ContextType {
  static const names = {
    ContextType.artist: 'artist',
    ContextType.playlist: 'playlist',
    ContextType.album: 'album',
    ContextType.show: 'show'
  };

  String get name => names[this]!;

  static ContextType fromName(String name) {
    for (var i = 0; i < names.values.length; i++) {
      if (names.values.elementAt(i) == name) {
        return names.keys.elementAt(i);
      }
    }

    return ContextType.artist;
  }
}

enum TrackType { track, episode, ad, unknown }

extension TrackTypeExtension on TrackType {
  static const names = {
    TrackType.track: 'track',
    TrackType.episode: 'episode',
    TrackType.ad: 'ad',
    TrackType.unknown: 'unknown'
  };

  String get name => names[this]!;

  static TrackType fromName(String name) {
    for (var i = 0; i < names.values.length; i++) {
      if (names.values.elementAt(i) == name) {
        return names.keys.elementAt(i);
      }
    }

    return TrackType.unknown;
  }
}

enum ItemType { track }

extension ItemTypeExtension on ItemType {
  static const names = {
    ItemType.track: 'track',
  };

  String get name => names[this]!;
}

enum ArtistType { artist }

extension ArtistTypeExtension on ArtistType {
  static const names = {
    ArtistType.artist: 'artist',
  };

  String get name => names[this]!;
}

enum Disallows {
  interrupting_playback,
  pausing,
  resuming,
  seeking,
  skipping_next,
  skipping_prev,
  toggling_repeat_context,
  toggling_shuffle,
  toggling_repeat_track,
  transferring_playback
}

extension DisallowsExtension on Disallows {
  static const names = {
    Disallows.interrupting_playback: 'interrupting_playback',
    Disallows.pausing: 'pausing',
    Disallows.resuming: 'resuming',
    Disallows.seeking: 'seeking',
    Disallows.skipping_next: 'skipping_next',
    Disallows.skipping_prev: 'skipping_prev',
    Disallows.toggling_repeat_context: 'toggling_repeat_context',
    Disallows.toggling_shuffle: 'toggling_shuffle',
    Disallows.toggling_repeat_track: 'toggling_repeat_track',
    Disallows.transferring_playback: 'transferring_playback',
  };

  String get name => names[this]!;
}
