class ArtistModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? imageUrlHigh;
  final int? followerCount;
  final String? type;
  final bool? isVerified;

  ArtistModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.imageUrlHigh,
    this.followerCount,
    this.type,
    this.isVerified,
  });

  // Factory constructor for JioSaavn API response
  factory ArtistModel.fromJioSaavnJson(Map<String, dynamic> json) {
    // Get artist image - handle both array and string formats
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

    return ArtistModel(
      id: json['id']?.toString() ?? '',
      name: _cleanText(json['name'] ?? json['title'] ?? 'Unknown Artist'),
      imageUrl: imageUrl,
      imageUrlHigh: imageUrlHigh,
      followerCount: json['followerCount'] ?? json['follower_count'],
      type: json['type'],
      isVerified: json['isVerified'] ?? json['is_verified'],
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
