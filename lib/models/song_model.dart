class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArt;
  final String? albumArtHigh; // High quality image
  final String? streamUrl; // Full song URL
  final Duration? duration;
  final bool isLocal;
  final String? artistId;
  final String? albumId;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'Unknown Album',
    this.albumArt,
    this.albumArtHigh,
    this.streamUrl,
    this.duration,
    this.isLocal = false,
    this.artistId,
    this.albumId,
  });

  // Factory constructor for Deezer API response
  factory SongModel.fromDeezerJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'].toString(),
      title: json['title'] ?? 'Unknown',
      artist: json['artist']?['name'] ?? 'Unknown Artist',
      album: json['album']?['title'] ?? 'Unknown Album',
      albumArt: json['album']?['cover_medium'] ?? json['album']?['cover'],
      streamUrl: json['preview'],
      duration: Duration(seconds: json['duration'] ?? 0),
      isLocal: false,
    );
  }

  // Factory constructor for JioSaavn API response
  factory SongModel.fromJioSaavnJson(Map<String, dynamic> json) {
    // Get the best quality download URL
    String? streamUrl;
    final downloadUrls = json['downloadUrl'];
    if (downloadUrls != null && downloadUrls is List && downloadUrls.isNotEmpty) {
      // Get highest quality (320kbps)
      final highQuality = downloadUrls.lastWhere(
        (url) => url['quality'] == '320kbps',
        orElse: () => downloadUrls.last,
      );
      streamUrl = highQuality['url'] ?? highQuality['link'];
    }

    // Get album art
    String? albumArt;
    String? albumArtHigh;
    final images = json['image'];
    if (images != null && images is List && images.isNotEmpty) {
      albumArt = images.firstWhere(
        (img) => img['quality'] == '150x150',
        orElse: () => images.first,
      )['url'] ?? images.first['link'];
      
      albumArtHigh = images.lastWhere(
        (img) => img['quality'] == '500x500',
        orElse: () => images.last,
      )['url'] ?? images.last['link'];
    }

    // Get artist names
    String artistName = 'Unknown Artist';
    final artists = json['artists'];
    if (artists != null) {
      if (artists['primary'] != null && artists['primary'] is List) {
        artistName = (artists['primary'] as List)
            .map((a) => a['name'])
            .join(', ');
      } else if (artists is String) {
        artistName = artists;
      }
    }
    if (artistName.isEmpty || artistName == 'Unknown Artist') {
      artistName = json['primaryArtists'] ?? json['artist'] ?? 'Unknown Artist';
    }

    return SongModel(
      id: json['id']?.toString() ?? '',
      title: _cleanText(json['name'] ?? json['title'] ?? 'Unknown'),
      artist: _cleanText(artistName),
      album: _cleanText(json['album']?['name'] ?? json['album'] ?? 'Unknown Album'),
      albumArt: albumArt,
      albumArtHigh: albumArtHigh,
      streamUrl: streamUrl,
      duration: Duration(seconds: json['duration'] ?? 0),
      isLocal: false,
      artistId: json['artists']?['primary']?[0]?['id']?.toString(),
      albumId: json['album']?['id']?.toString(),
    );
  }

  // Factory constructor for iTunes API response
  factory SongModel.fromItunesJson(Map<String, dynamic> json) {
    // Get high quality artwork (replace 100x100 with 600x600)
    String? artworkUrl = json['artworkUrl100'];
    String? artworkUrlHigh = artworkUrl?.replaceAll('100x100', '600x600');
    
    return SongModel(
      id: json['trackId'].toString(),
      title: json['trackName'] ?? 'Unknown',
      artist: json['artistName'] ?? 'Unknown Artist',
      album: json['collectionName'] ?? 'Unknown Album',
      albumArt: artworkUrl,
      albumArtHigh: artworkUrlHigh,
      streamUrl: json['previewUrl'], // 30-second preview
      duration: Duration(milliseconds: json['trackTimeMillis'] ?? 0),
      isLocal: false,
      artistId: json['artistId']?.toString(),
      albumId: json['collectionId']?.toString(),
    );
  }

  // Clean HTML entities from text
  static String _cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'");
  }

  // Factory constructor for local audio files
  factory SongModel.fromLocalFile({
    required String id,
    required String title,
    required String artist,
    required String album,
    required String path,
    int? durationMs,
  }) {
    return SongModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      streamUrl: path,
      duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
      isLocal: true,
    );
  }

  String get playableUrl => streamUrl ?? '';
  String get highQualityArt => albumArtHigh ?? albumArt ?? '';
}
