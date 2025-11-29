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
    
    // Debug: print the downloadUrl structure
    print('JioSaavn downloadUrl type: ${downloadUrls.runtimeType}');
    print('JioSaavn downloadUrl: $downloadUrls');
    
    if (downloadUrls != null) {
      if (downloadUrls is List && downloadUrls.isNotEmpty) {
        // Handle array format: [{"quality": "320kbps", "url": "..."}]
        try {
          final highQuality = downloadUrls.lastWhere(
            (url) => url['quality'] == '320kbps',
            orElse: () => downloadUrls.last,
          );
          streamUrl = highQuality['url'] ?? highQuality['link'];
        } catch (e) {
          // If list items are strings, take the last one (highest quality)
          if (downloadUrls.first is String) {
            streamUrl = downloadUrls.last as String;
          }
        }
      } else if (downloadUrls is String) {
        // Handle string format directly
        streamUrl = downloadUrls;
      } else if (downloadUrls is Map) {
        // Handle map format: {"320kbps": "url"}
        streamUrl = downloadUrls['320kbps'] ?? 
                    downloadUrls['160kbps'] ?? 
                    downloadUrls['96kbps'] ??
                    downloadUrls.values.last;
      }
    }
    
    // Fallback: check for other URL fields
    if (streamUrl == null || streamUrl.isEmpty) {
      streamUrl = json['url'] ?? json['media_url'] ?? json['perma_url'];
    }

    print('Final streamUrl: $streamUrl');

    // Get album art - handle both array and string formats
    String? albumArt;
    String? albumArtHigh;
    final images = json['image'];
    
    if (images != null) {
      if (images is List && images.isNotEmpty) {
        try {
          final firstImg = images.firstWhere(
            (img) => img is Map && img['quality'] == '150x150',
            orElse: () => images.first,
          );
          albumArt = firstImg is Map ? (firstImg['url'] ?? firstImg['link']) : firstImg.toString();
          
          final lastImg = images.lastWhere(
            (img) => img is Map && img['quality'] == '500x500',
            orElse: () => images.last,
          );
          albumArtHigh = lastImg is Map ? (lastImg['url'] ?? lastImg['link']) : lastImg.toString();
        } catch (e) {
          if (images.first is String) {
            albumArt = images.first;
            albumArtHigh = images.last;
          }
        }
      } else if (images is String) {
        albumArt = images;
        albumArtHigh = images.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');
      }
    }

    // Get artist names
    String artistName = 'Unknown Artist';
    final artists = json['artists'];
    if (artists != null) {
      if (artists is Map && artists['primary'] != null && artists['primary'] is List) {
        artistName = (artists['primary'] as List)
            .map((a) => a is Map ? a['name'] : a.toString())
            .join(', ');
      } else if (artists is String) {
        artistName = artists;
      } else if (artists is List) {
        artistName = artists.map((a) => a is Map ? a['name'] : a.toString()).join(', ');
      }
    }
    if (artistName.isEmpty || artistName == 'Unknown Artist') {
      artistName = json['primaryArtists'] ?? json['artist'] ?? json['singers'] ?? 'Unknown Artist';
    }

    // Get album name
    String albumName = 'Unknown Album';
    final album = json['album'];
    if (album != null) {
      if (album is Map) {
        albumName = album['name'] ?? album['title'] ?? 'Unknown Album';
      } else if (album is String) {
        albumName = album;
      }
    }

    // Get duration - handle both int and string
    int durationSeconds = 0;
    final duration = json['duration'];
    if (duration != null) {
      if (duration is int) {
        durationSeconds = duration;
      } else if (duration is String) {
        durationSeconds = int.tryParse(duration) ?? 0;
      }
    }

    return SongModel(
      id: json['id']?.toString() ?? '',
      title: _cleanText(json['name'] ?? json['title'] ?? json['song'] ?? 'Unknown'),
      artist: _cleanText(artistName),
      album: _cleanText(albumName),
      albumArt: albumArt,
      albumArtHigh: albumArtHigh,
      streamUrl: streamUrl,
      duration: Duration(seconds: durationSeconds),
      isLocal: false,
      artistId: json['artists']?['primary']?[0]?['id']?.toString() ?? json['artistId']?.toString(),
      albumId: json['album']?['id']?.toString() ?? json['albumId']?.toString(),
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
