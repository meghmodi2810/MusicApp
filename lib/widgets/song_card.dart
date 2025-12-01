import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../services/download_service.dart';
import '../screens/player_screen.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final bool showDownloadButton;

  const SongCard({
    super.key,
    required this.song,
    required this.playlist,
    this.showDownloadButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final downloadService = Provider.of<DownloadService>(context);
    final cardColor = themeProvider.cardColor;
    final accentColor = themeProvider.primaryColor;
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;
    
    final isDownloaded = downloadService.isDownloaded(song.id);
    final isDownloading = downloadService.isDownloading(song.id);
    final downloadProgress = downloadService.getProgress(song.id);
    
    return GestureDetector(
      onTap: () {
        context.read<MusicPlayerProvider>().playSong(song, playlist: playlist);
        // Use simple MaterialPageRoute instead of custom transitions
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      onLongPress: () => _showSongOptions(context, themeProvider, downloadService),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art with Play Button Overlay
            Stack(
              children: [
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.albumArt != null
                        ? CachedNetworkImage(
                            imageUrl: song.albumArt!,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                            placeholder: (context, url) => Container(
                              color: cardColor,
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: secondaryText,
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: cardColor,
                              child: Icon(
                                Icons.music_note,
                                color: secondaryText,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: cardColor,
                            child: Icon(
                              Icons.music_note,
                              color: secondaryText,
                              size: 40,
                            ),
                          ),
                  ),
                ),
                // Download indicator
                if (isDownloaded)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.download_done,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                // Download progress
                if (isDownloading)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                        strokeWidth: 2,
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                // Play button overlay
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Song Title
            Text(
              song.title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist Name
            Text(
              song.artist,
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, ThemeProvider themeProvider, DownloadService downloadService) {
    final isDownloaded = downloadService.isDownloaded(song.id);
    final isDownloading = downloadService.isDownloading(song.id);
    final playerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeProvider.secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Song info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: song.albumArt != null
                      ? CachedNetworkImage(
                          imageUrl: song.albumArt!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: themeProvider.primaryColor.withOpacity(0.2),
                          child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Options
          ListTile(
            leading: Icon(Icons.play_circle_outline, color: themeProvider.primaryColor),
            title: Text('Play Now', style: TextStyle(color: themeProvider.textColor)),
            onTap: () {
              Navigator.pop(context);
              playerProvider.playSong(song, playlist: playlist);
            },
          ),
          ListTile(
            leading: Icon(Icons.playlist_add, color: themeProvider.primaryColor),
            title: Text('Add to Queue', style: TextStyle(color: themeProvider.textColor)),
            onTap: () {
              Navigator.pop(context);
              playerProvider.addToQueue(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Added to queue'),
                  backgroundColor: themeProvider.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.queue_play_next, color: themeProvider.primaryColor),
            title: Text('Play Next', style: TextStyle(color: themeProvider.textColor)),
            onTap: () {
              Navigator.pop(context);
              playerProvider.addToQueueNext(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Will play next'),
                  backgroundColor: themeProvider.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // Download option
          if (!isDownloaded && !isDownloading)
            ListTile(
              leading: Icon(Icons.download_outlined, color: themeProvider.primaryColor),
              title: Text('Download', style: TextStyle(color: themeProvider.textColor)),
              onTap: () async {
                Navigator.pop(context);
                final success = await downloadService.downloadSong(song);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Download started' : 'Download failed'),
                      backgroundColor: success ? themeProvider.primaryColor : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          if (isDownloading)
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: Text('Cancel Download', style: TextStyle(color: themeProvider.textColor)),
              onTap: () {
                Navigator.pop(context);
                downloadService.cancelDownload(song.id);
              },
            ),
          if (isDownloaded)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Remove Download', style: TextStyle(color: themeProvider.textColor)),
              onTap: () {
                Navigator.pop(context);
                downloadService.deleteDownload(song.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Download removed'),
                    backgroundColor: themeProvider.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
