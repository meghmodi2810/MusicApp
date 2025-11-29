import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = themeProvider.primaryColor;
    
    return Consumer<MusicPlayerProvider>(
      builder: (context, player, child) {
        final isPlaying = player.currentSong?.id == song.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isPlaying ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
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
                        color: isPlaying ? primaryColor : (isDark ? Colors.grey[500] : Colors.grey[600]),
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
                                  color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[200],
                                  child: Icon(Icons.music_note, color: isDark ? Colors.white24 : Colors.grey[400]),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[200],
                                  child: Icon(Icons.music_note, color: isDark ? Colors.white24 : Colors.grey[400]),
                                ),
                              )
                            : Container(
                                color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[200],
                                child: Icon(Icons.music_note, color: isDark ? Colors.white24 : Colors.grey[400]),
                              ),
                      ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          player.isPlaying ? Icons.equalizer : Icons.pause,
                          color: primaryColor,
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
                color: isPlaying ? primaryColor : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (song.duration != null)
                  Text(
                    _formatDuration(song.duration!),
                    style: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () => _showOptions(context, isDark, primaryColor),
                ),
              ],
            ),
            onTap: () {
              player.playSong(song, playlist: playlist);
              
              // Track recently played if logged in
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isLoggedIn) {
                final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
                playlistProvider.addToRecentlyPlayed(song);
              }
              
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

  void _showOptions(BuildContext context, bool isDark, Color primaryColor) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final isLiked = authProvider.isLoggedIn ? playlistProvider.isSongLikedSync(song.id) : false;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Song info header
            Row(
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
                          )
                        : Container(
                            color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[200],
                            child: const Icon(Icons.music_note),
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
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Like option
            ListTile(
              leading: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : (isDark ? Colors.white : Colors.black87),
              ),
              title: Text(
                isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!authProvider.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to like songs')),
                  );
                  return;
                }
                playlistProvider.toggleLikeSong(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isLiked ? 'Removed from Liked Songs' : 'Added to Liked Songs'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            // Add to playlist option
            ListTile(
              leading: Icon(Icons.playlist_add, color: isDark ? Colors.white : Colors.black87),
              title: Text('Add to Playlist', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                if (!authProvider.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to add to playlists')),
                  );
                  return;
                }
                _showPlaylistPicker(context, isDark, primaryColor, playlistProvider);
              },
            ),
            // Play next option
            ListTile(
              leading: Icon(Icons.queue_play_next, color: isDark ? Colors.white : Colors.black87),
              title: Text('Play Next', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement play next
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to queue')),
                );
              },
            ),
            // Share option
            ListTile(
              leading: Icon(Icons.share, color: isDark ? Colors.white : Colors.black87),
              title: Text('Share', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share: ${song.title} by ${song.artist}')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    final playlists = playlistProvider.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to Playlist',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Create new playlist option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, color: primaryColor),
              ),
              title: Text(
                'Create New Playlist',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, isDark, primaryColor, playlistProvider);
              },
            ),
            const Divider(),
            // Existing playlists
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No playlists yet. Create one!',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: playlist.coverUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: playlist.coverUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.queue_music,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.songCount} songs',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        await playlistProvider.addSongToPlaylist(playlist.id, song);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Added to "${playlist.name}"')),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Playlist',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final newPlaylist = await playlistProvider.createPlaylist(name);
                      if (newPlaylist != null) {
                        await playlistProvider.addSongToPlaylist(newPlaylist.id, song);
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Added to "$name"')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Create & Add Song',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}
