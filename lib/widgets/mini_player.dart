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
    // CRITICAL FIX: Listen to theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);

    // PERFORMANCE: Use Selector to only rebuild when current song changes
    return Selector<MusicPlayerProvider, String?>(
      selector: (_, player) => player.currentSong?.id,
      builder: (context, songId, child) {
        if (songId == null) return const SizedBox.shrink();

        final player = Provider.of<MusicPlayerProvider>(context, listen: false);
        final song = player.currentSong!;

        return GestureDetector(
          onTap: () {
            // PERFORMANCE: Use Hero animation for smooth transition
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PlayerScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 250),
              ),
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
                      // Album Art with Hero
                      Hero(
                        tag: 'album_art_${song.id}',
                        child: ClipRRect(
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
                                      color: themeProvider.primaryColor
                                          .withOpacity(0.1),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: themeProvider.primaryColor
                                              .withOpacity(0.1),
                                          child: Icon(
                                            Icons.music_note,
                                            color: themeProvider
                                                .secondaryTextColor,
                                          ),
                                        ),
                                  )
                                : Container(
                                    color: themeProvider.primaryColor
                                        .withOpacity(0.1),
                                    child: Icon(
                                      Icons.music_note,
                                      color: themeProvider.secondaryTextColor,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Song Info - static, no rebuild
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
                              style: TextStyle(
                                color: themeProvider.secondaryTextColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Controls - use Selector for minimal rebuilds
                      _MiniPlayerControls(themeProvider: themeProvider),
                    ],
                  ),
                ),
                // Progress Bar - use ValueListenableBuilder
                _MiniPlayerProgressBar(
                  player: player,
                  themeProvider: themeProvider,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// PERFORMANCE: Separate widget for controls to prevent unnecessary rebuilds
class _MiniPlayerControls extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _MiniPlayerControls({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<MusicPlayerProvider>(context, listen: false);

    return Selector<MusicPlayerProvider, Map<String, dynamic>>(
      selector: (_, p) => {'isPlaying': p.isPlaying, 'isLoading': p.isLoading},
      builder: (context, state, child) {
        final isPlaying = state['isPlaying'] as bool;
        final isLoading = state['isLoading'] as bool;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.skip_previous_rounded,
                size: 28,
                color: themeProvider.textColor,
              ),
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
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 28,
                      ),
                color: Colors.white,
                onPressed: player.togglePlayPause,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.skip_next_rounded,
                size: 28,
                color: themeProvider.textColor,
              ),
              onPressed: player.playNext,
            ),
          ],
        );
      },
    );
  }
}

// PERFORMANCE: Separate widget for progress bar with ValueListenableBuilder
class _MiniPlayerProgressBar extends StatelessWidget {
  final MusicPlayerProvider player;
  final ThemeProvider themeProvider;

  const _MiniPlayerProgressBar({
    required this.player,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: player.positionNotifier,
      builder: (context, position, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: player.durationNotifier,
          builder: (context, duration, _) {
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                value: duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0,
                backgroundColor: themeProvider.secondaryTextColor.withOpacity(
                  0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  themeProvider.primaryColor,
                ),
                minHeight: 3,
              ),
            );
          },
        );
      },
    );
  }
}
