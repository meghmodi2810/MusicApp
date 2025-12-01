import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album_model.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_tile.dart';

class AlbumScreen extends StatefulWidget {
  final AlbumModel album;

  const AlbumScreen({super.key, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final MusicApiService _apiService = MusicApiService();
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
  }

  Future<void> _loadAlbumSongs() async {
    setState(() => _isLoading = true);
    try {
      final songs = await _apiService.getAlbumSongs(widget.album.id);
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
          // Album Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.album.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.album.highQualityImage,
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
                          child: Icon(Icons.album, size: 120, color: Colors.white54),
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
                  // Album info
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ALBUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.album.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.album.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        if (widget.album.year != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${widget.album.year} • ${widget.album.songCount ?? _songs.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
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
              child: ElevatedButton.icon(
                onPressed: _songs.isNotEmpty
                    ? () {
                        context.read<MusicPlayerProvider>().playSong(
                              _songs.first,
                              playlist: _songs,
                            );
                      }
                    : null,
                icon: Icon(Icons.play_arrow_rounded, size: 28),
                label: Text('Play Album', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
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
                    showTrackNumber: true,
                    trackNumber: index + 1,
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
}
