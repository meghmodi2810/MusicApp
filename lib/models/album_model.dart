class AlbumModel {
  final String id;
  final String name;
  final String artist;
  final String? imageUrl;
  final String? imageUrlHigh;
  final int? year;
  final int? songCount;
  final String? language;

  AlbumModel({
    required this.id,
    required this.name,
    required this.artist,
    this.imageUrl,
    this.imageUrlHigh,
    this.year,
    this.songCount,
    this.language,
  });

  // Factory constructor for JioSaavn API response
  factory AlbumModel.fromJioSaavnJson(Map<String, dynamic> json) {
    // Get album art - handle both array and string formats
    String? imageUrl;
    String? imageUrlHigh;
    final images = json['image'];
    
    if (images != null) {
      if (images is List && images.isNotEmpty) {
        try {
          final firstImg = images.firstWhere(
            (img) => img is Map && img['quality'] == '150x150',
            orElse: () => images.first,
          );
          imageUrl = firstImg is Map ? (firstImg['url'] ?? firstImg['link']) : firstImg.toString();
          
          final lastImg = images.lastWhere(
            (img) => img is Map && img['quality'] == '500x500',
            orElse: () => images.last,
          );
          imageUrlHigh = lastImg is Map ? (lastImg['url'] ?? lastImg['link']) : lastImg.toString();
        } catch (e) {
          if (images.first is String) {
            imageUrl = images.first;
            imageUrlHigh = images.last;
          }
        }
      } else if (images is String) {
        imageUrl = images;
        imageUrlHigh = images.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');
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
      artistName = json['primaryArtists'] ?? json['artist'] ?? 'Unknown Artist';
    }

    // Get year - handle both String and int
    int? year;
    final yearData = json['year'];
    if (yearData != null) {
      if (yearData is int) {
        year = yearData;
      } else if (yearData is String) {
        year = int.tryParse(yearData);
      }
    }

    // Get song count - FIX: handle both String and int
    int? songCount;
    final songCountData = json['songCount'] ?? json['song_count'];
    if (songCountData != null) {
      if (songCountData is int) {
        songCount = songCountData;
      } else if (songCountData is String) {
        songCount = int.tryParse(songCountData);
      }
    }

    return AlbumModel(
      id: json['id']?.toString() ?? '',
      name: _cleanText(json['name'] ?? json['title'] ?? 'Unknown Album'),
      artist: _cleanText(artistName),
      imageUrl: imageUrl,
      imageUrlHigh: imageUrlHigh,
      year: year,
      songCount: songCount,
      language: json['language'],
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

  String get highQualityImage => imageUrlHigh ?? imageUrl ?? '';
}
