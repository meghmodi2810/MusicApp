import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/music_player_provider.dart';
import '../screens/player_screen.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final int? index;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.playlist,
    this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, player, child) {
        final isPlaying = player.currentSong?.id == song.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isPlaying ? const Color(0xFF1DB954).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index != null)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$index',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPlaying ? const Color(0xFF1DB954) : Colors.grey[500],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: song.albumArt != null
                            ? CachedNetworkImage(
                                imageUrl: song.albumArt!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF1a1a1a),
                                  child: const Icon(Icons.music_note, color: Colors.white24),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFF1a1a1a),
                                  child: const Icon(Icons.music_note, color: Colors.white24),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF1a1a1a),
                                child: const Icon(Icons.music_note, color: Colors.white24),
                              ),
                      ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          player.isPlaying ? Icons.equalizer : Icons.pause,
                          color: const Color(0xFF1DB954),
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: isPlaying ? const Color(0xFF1DB954) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (song.duration != null)
                  Text(
                    _formatDuration(song.duration!),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[500], size: 20),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
            onTap: () {
              player.playSong(song, playlist: playlist);
              if (onTap != null) {
                onTap!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlayerScreen()),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: Colors.white),
              title: const Text('Add to Liked Songs', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}
