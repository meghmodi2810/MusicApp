import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album_model.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../services/download_service.dart';
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                              colors: [
                                accentColor,
                                accentColor.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.album,
                            size: 120,
                            color: Colors.white54,
                          ),
                        ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          themeProvider.backgroundColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Album Info and Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.name,
                    style: TextStyle(
                      color: textColor,
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
                      color: themeProvider.secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.album.year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${widget.album.year} • ${widget.album.songCount ?? _songs.length} songs',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Action Buttons Row
                  Row(
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
                          icon: Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            'Play',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _songs.isNotEmpty
                              ? () {
                                  final shuffledSongs = List<SongModel>.from(
                                    _songs,
                                  )..shuffle();
                                  context.read<MusicPlayerProvider>().playSong(
                                    shuffledSongs.first,
                                    playlist: shuffledSongs,
                                  );
                                }
                              : null,
                          icon: Icon(Icons.shuffle, size: 24),
                          label: Text(
                            'Shuffle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor, width: 2),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Download Album Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _songs.isNotEmpty
                          ? () async {
                              final downloadService = context
                                  .read<DownloadService>();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Downloading ${_songs.length} songs...',
                                  ),
                                  backgroundColor: accentColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              for (final song in _songs) {
                                await downloadService.downloadSong(song);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Album downloaded successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: Icon(Icons.download_outlined, size: 24),
                      label: Text(
                        'Download Album',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: themeProvider.secondaryTextColor.withOpacity(
                            0.3,
                          ),
                          width: 2,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: accentColor))
            : _songs.isEmpty
            ? Center(
                child: Text(
                  'No songs available',
                  style: TextStyle(color: themeProvider.secondaryTextColor),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  return SongTile(
                    song: _songs[index],
                    playlist: _songs,
                    showTrackNumber: true,
                    trackNumber: index + 1,
                  );
                },
              ),
      ),
    );
  }
}
