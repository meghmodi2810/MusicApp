import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_tile.dart';

class ArtistScreen extends StatefulWidget {
  final ArtistModel artist;

  const ArtistScreen({super.key, required this.artist});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final MusicApiService _apiService = MusicApiService();
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  Future<void> _loadArtistSongs() async {
    setState(() => _isLoading = true);
    try {
      final songs = await _apiService.getArtistSongs(widget.artist.id);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Artist Header with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.artist.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.artist.highQualityImage,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor, accentColor.withOpacity(0.5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(Icons.person, size: 120, color: Colors.white54),
                        ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          themeProvider.backgroundColor.withOpacity(0.5),
                          themeProvider.backgroundColor,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Artist name
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.artist.isVerified == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified Artist',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          widget.artist.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.artist.followerCount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_formatFollowers(widget.artist.followerCount!)} followers',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play All Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isNotEmpty
                          ? () {
                              context.read<MusicPlayerProvider>().playSong(
                                    _songs.first,
                                    playlist: _songs,
                                  );
                            }
                          : null,
                      icon: Icon(Icons.play_arrow_rounded),
                      label: Text('Play All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _songs.isNotEmpty
                          ? () {
                              final player = context.read<MusicPlayerProvider>();
                              player.playSong(_songs.first, playlist: _songs);
                              player.toggleShuffle();
                            }
                          : null,
                      icon: Icon(Icons.shuffle),
                      label: Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: textColor.withOpacity(0.3)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Top Songs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),

          // Songs List
          if (_isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: accentColor),
                ),
              ),
            )
          else if (_songs.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No songs available',
                    style: TextStyle(color: themeProvider.secondaryTextColor),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongTile(
                    song: _songs[index],
                    playlist: _songs,
                  );
                },
                childCount: _songs.length,
              ),
            ),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
