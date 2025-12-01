import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Consumer<MusicPlayerProvider>(
      builder: (context, player, child) {
        final song = player.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            // Use simple MaterialPageRoute instead of PageRouteBuilder
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // Album Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: song.albumArt != null
                              ? CachedNetworkImage(
                                  imageUrl: song.albumArt!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 96,
                                  placeholder: (context, url) => Container(
                                    color: themeProvider.primaryColor.withOpacity(0.1),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: themeProvider.primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                                  ),
                                )
                              : Container(
                                  color: themeProvider.primaryColor.withOpacity(0.1),
                                  child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Song Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title,
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded, size: 28, color: themeProvider.textColor),
                        onPressed: player.playPrevious,
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: player.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 28,
                                ),
                          color: Colors.white,
                          onPressed: player.togglePlayPause,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded, size: 28, color: themeProvider.textColor),
                        onPressed: player.playNext,
                      ),
                    ],
                  ),
                ),
                // Progress Bar
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    value: player.duration.inMilliseconds > 0
                        ? player.position.inMilliseconds / player.duration.inMilliseconds
                        : 0,
                    backgroundColor: themeProvider.secondaryTextColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
