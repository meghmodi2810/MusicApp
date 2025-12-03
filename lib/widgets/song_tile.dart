import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
import '../services/recommendation_service.dart';
import '../screens/player_screen.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final List<SongModel> playlist;
  final int? index;
  final VoidCallback? onTap;
  final bool showTrackNumber;
  final int? trackNumber;
  final bool isFromSearch; // NEW: Flag to indicate if this is a search result

  const SongTile({
    super.key,
    required this.song,
    required this.playlist,
    this.index,
    this.onTap,
    this.showTrackNumber = false,
    this.trackNumber,
    this.isFromSearch = false, // NEW: Default to false
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = themeProvider.cardColor;
    final accentColor = themeProvider.primaryColor;
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;

    return Consumer<MusicPlayerProvider>(
      builder: (context, player, child) {
        final isPlaying = player.currentSong?.id == song.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: const BoxConstraints(maxHeight: 80), // OVERFLOW FIX
          decoration: BoxDecoration(
            color: isPlaying ? accentColor.withOpacity(0.15) : cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showTrackNumber && trackNumber != null)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$trackNumber',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPlaying ? accentColor : secondaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                else if (index != null)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$index',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isPlaying ? accentColor : secondaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (showTrackNumber || index != null) const SizedBox(width: 8),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: song.albumArt != null
                            ? CachedNetworkImage(
                                imageUrl: song.albumArt!,
                                fit: BoxFit.cover,
                                memCacheWidth: 100,
                                placeholder: (context, url) => Container(
                                  color: accentColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.music_note,
                                    color: secondaryText,
                                    size: 20,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: accentColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.music_note,
                                    color: secondaryText,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Container(
                                color: accentColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.music_note,
                                  color: secondaryText,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          player.isPlaying ? Icons.equalizer : Icons.pause,
                          color: accentColor,
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
                color: isPlaying ? accentColor : textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14, // REDUCED font size for better fit
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                color: secondaryText,
                fontSize: 12, // REDUCED font size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: SizedBox(
              width: 80, // FIXED width for trailing section
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (song.duration != null)
                    Text(
                      _formatDuration(song.duration!),
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.more_vert,
                        color: secondaryText,
                        size: 20,
                      ),
                      onPressed: () =>
                          _showOptions(context, themeProvider, player),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              // Track song play for recommendations
              final recommendationService = RecommendationService();
              recommendationService.trackSongPlay(song);

              // FIX: Use context-aware playback for search results
              if (isFromSearch) {
                // From search: Play this song only, autoplay will load similar songs
                player.playSongWithContext(song, context: 'search');
                debugPrint(
                  '🔍 Playing from search: ${song.title} - Next will be similar songs',
                );
              } else {
                // From playlist/album: Use the provided playlist
                player.playSong(song, playlist: playlist);
                debugPrint('📀 Playing from playlist: ${song.title}');
              }

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              if (authProvider.isLoggedIn) {
                final playlistProvider = Provider.of<PlaylistProvider>(
                  context,
                  listen: false,
                );
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

  void _showOptions(
    BuildContext context,
    ThemeProvider themeProvider,
    MusicPlayerProvider player,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playlistProvider = Provider.of<PlaylistProvider>(
      context,
      listen: false,
    );
    final isLiked = authProvider.isLoggedIn
        ? playlistProvider.isSongLikedSync(song.id)
        : false;
    final isInQueue = player.isInQueue(song);

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: themeProvider.secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: song.albumArt != null
                        ? CachedNetworkImage(
                            imageUrl: song.albumArt!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: themeProvider.primaryColor.withOpacity(0.1),
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
                          color: themeProvider.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
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
            Divider(color: themeProvider.secondaryTextColor.withOpacity(0.2)),

            // Queue options
            ListTile(
              leading: Icon(
                Icons.queue_play_next,
                color: themeProvider.textColor,
              ),
              title: Text(
                'Play Next',
                style: TextStyle(color: themeProvider.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                player.addToQueueNext(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${song.title}" will play next'),
                    backgroundColor: themeProvider.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                isInQueue ? Icons.remove_from_queue : Icons.add_to_queue,
                color: isInQueue ? Colors.red : themeProvider.textColor,
              ),
              title: Text(
                isInQueue ? 'Remove from Queue' : 'Add to Queue',
                style: TextStyle(color: themeProvider.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isInQueue) {
                  player.removeFromQueueBySong(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Removed from queue'),
                      backgroundColor: themeProvider.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  player.addToQueue(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Added to queue'),
                      backgroundColor: themeProvider.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : themeProvider.textColor,
              ),
              title: Text(
                isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
                style: TextStyle(color: themeProvider.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!authProvider.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please log in to like songs'),
                      backgroundColor: themeProvider.primaryColor,
                    ),
                  );
                  return;
                }
                playlistProvider.toggleLikeSong(song);
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add, color: themeProvider.textColor),
              title: Text(
                'Add to Playlist',
                style: TextStyle(color: themeProvider.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!authProvider.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please log in to add to playlists'),
                      backgroundColor: themeProvider.primaryColor,
                    ),
                  );
                  return;
                }
                _showPlaylistPicker(context, themeProvider, playlistProvider);
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: themeProvider.textColor),
              title: Text(
                'Share',
                style: TextStyle(color: themeProvider.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Share: ${song.title} by ${song.artist}'),
                    backgroundColor: themeProvider.primaryColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlaylistPicker(
    BuildContext context,
    ThemeProvider themeProvider,
    PlaylistProvider playlistProvider,
  ) {
    final playlists = playlistProvider.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: themeProvider.secondaryTextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to Playlist',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add, color: themeProvider.primaryColor),
              ),
              title: Text(
                'Create New Playlist',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(
                  context,
                  themeProvider,
                  playlistProvider,
                );
              },
            ),
            Divider(color: themeProvider.secondaryTextColor.withOpacity(0.2)),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No playlists yet. Create one!',
                  style: TextStyle(color: themeProvider.secondaryTextColor),
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
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: playlist.coverUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: playlist.coverUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.queue_music,
                                color: themeProvider.primaryColor,
                              ),
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.songCount} songs',
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await playlistProvider.addSongToPlaylist(
                          playlist.id,
                          song,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to "${playlist.name}"'),
                            backgroundColor: themeProvider.primaryColor,
                          ),
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

  void _showCreatePlaylistDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    PlaylistProvider playlistProvider,
  ) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: themeProvider.secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Playlist',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newPlaylist = await playlistProvider.createPlaylist(
                        name,
                      );
                      if (newPlaylist != null) {
                        await playlistProvider.addSongToPlaylist(
                          newPlaylist.id,
                          song,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to "$name"'),
                            backgroundColor: themeProvider.primaryColor,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
