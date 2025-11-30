import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/player_screen.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;

  const SongCard({
    super.key,
    required this.song,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.cardColor;
    final accentColor = themeProvider.primaryColor;
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;
    
    return GestureDetector(
      onTap: () {
        context.read<MusicPlayerProvider>().playSong(song, playlist: playlist);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
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
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: song.albumArt != null
                        ? CachedNetworkImage(
                            imageUrl: song.albumArt!,
                            fit: BoxFit.cover,
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
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
}
