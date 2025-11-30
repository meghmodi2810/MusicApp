import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/playlist_provider.dart';

void showSongOptionsSheet(BuildContext context, SongModel song) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final player = Provider.of<MusicPlayerProvider>(context, listen: false);
  final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);

  showModalBottomSheet(
    context: context,
    backgroundColor: themeProvider.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SongOptionsSheet(
      song: song,
      themeProvider: themeProvider,
      player: player,
      playlistProvider: playlistProvider,
    ),
  );
}

class SongOptionsSheet extends StatelessWidget {
  final SongModel song;
  final ThemeProvider themeProvider;
  final MusicPlayerProvider player;
  final PlaylistProvider playlistProvider;

  const SongOptionsSheet({
    super.key,
    required this.song,
    required this.themeProvider,
    required this.player,
    required this.playlistProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isInQueue = player.isInQueue(song);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: song.albumArt != null
                        ? CachedNetworkImage(
                            imageUrl: song.albumArt!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: themeProvider.primaryColor.withOpacity(0.2),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: themeProvider.primaryColor.withOpacity(0.2),
                              child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                            ),
                          )
                        : Container(
                            color: themeProvider.primaryColor.withOpacity(0.2),
                            child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
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
          
          const SizedBox(height: 20),
          Divider(color: themeProvider.secondaryTextColor.withOpacity(0.1)),
          
          // Options
          _buildOption(
            context,
            icon: Icons.play_arrow_rounded,
            title: 'Play Now',
            onTap: () {
              Navigator.pop(context);
              player.playSong(song);
            },
          ),
          _buildOption(
            context,
            icon: Icons.queue_play_next,
            title: 'Play Next',
            subtitle: 'Add to the front of queue',
            onTap: () {
              Navigator.pop(context);
              player.addToQueueNext(song);
              _showSnackBar(context, '"${song.title}" will play next');
            },
          ),
          _buildOption(
            context,
            icon: isInQueue ? Icons.remove_from_queue : Icons.add_to_queue,
            title: isInQueue ? 'Remove from Queue' : 'Add to Queue',
            subtitle: isInQueue ? 'Remove from up next' : 'Add to the end of queue',
            iconColor: isInQueue ? Colors.red : null,
            onTap: () {
              Navigator.pop(context);
              if (isInQueue) {
                player.removeFromQueueBySong(song);
                _showSnackBar(context, 'Removed from queue');
              } else {
                player.addToQueue(song);
                _showSnackBar(context, 'Added to queue');
              }
            },
          ),
          _buildOption(
            context,
            icon: playlistProvider.isSongLikedSync(song.id) ? Icons.favorite : Icons.favorite_border,
            title: playlistProvider.isSongLikedSync(song.id) ? 'Remove from Liked' : 'Add to Liked',
            iconColor: playlistProvider.isSongLikedSync(song.id) ? Colors.red : null,
            onTap: () {
              Navigator.pop(context);
              playlistProvider.toggleLikeSong(song);
              _showSnackBar(
                context,
                playlistProvider.isSongLikedSync(song.id) ? 'Removed from Liked Songs' : 'Added to Liked Songs',
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.playlist_add,
            title: 'Add to Playlist',
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(context, song);
            },
          ),
          _buildOption(
            context,
            icon: Icons.share_outlined,
            title: 'Share',
            onTap: () {
              Navigator.pop(context);
              _showSnackBar(context, 'Share feature coming soon!');
            },
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? themeProvider.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? themeProvider.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: themeProvider.secondaryTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: themeProvider.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, SongModel song) {
    final playlists = playlistProvider.playlists;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.secondaryTextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add to Playlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 16),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 48,
                        color: themeProvider.secondaryTextColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No playlists yet',
                        style: TextStyle(color: themeProvider.secondaryTextColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreatePlaylistDialog(context, song);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Create Playlist'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...playlists.map((playlist) => ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.queue_music, color: themeProvider.primaryColor),
                ),
                title: Text(
                  playlist.name,
                  style: TextStyle(color: themeProvider.textColor),
                ),
                subtitle: Text(
                  '${playlist.songCount} songs',
                  style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12),
                ),
                onTap: () async {
                  await playlistProvider.addSongToPlaylist(playlist.id, song);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar(context, 'Added to ${playlist.name}');
                  }
                },
              )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, SongModel song) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create Playlist', style: TextStyle(color: themeProvider.textColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: themeProvider.textColor),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
            filled: true,
            fillColor: themeProvider.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final playlist = await playlistProvider.createPlaylist(name);
                if (playlist != null) {
                  await playlistProvider.addSongToPlaylist(playlist.id, song);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Created playlist and added song');
                }
              }
            },
            child: Text('Create', style: TextStyle(color: themeProvider.primaryColor)),
          ),
        ],
      ),
    );
  }
}
