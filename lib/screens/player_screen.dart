import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/music_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
import '../models/song_model.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, player, child) {
        final song = player.currentSong;
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Background with blur effect
              if (song?.albumArt != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: song!.highQualityArt,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF0d0d0d),
                    ),
                  ),
                ),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Blur effect
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Content
              SafeArea(
                child: song == null
                    ? _buildNoSongPlaying(context)
                    : _buildPlayerContent(context, player, song),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoSongPlaying(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text('No song playing', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent(BuildContext context, MusicPlayerProvider player, SongModel song) {
    final authProvider = Provider.of<AuthProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final isLiked = authProvider.isLoggedIn ? playlistProvider.isSongLikedSync(song.id) : false;

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                children: [
                  Text(
                    'PLAYING FROM',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.album,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                color: Colors.white,
                onPressed: () => _showSongOptions(context, song),
              ),
            ],
          ),
        ),

        const Spacer(flex: 1),

        // Album Art
        Hero(
          tag: 'album_art',
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.highQualityArt,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1a1a1a),
                        child: const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1a1a1a),
                        child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1DB954), Color(0xFF1a1a1a)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.music_note, size: 80, color: Colors.white54),
                    ),
            ),
          ),
        ),

        const Spacer(flex: 1),

        // Song Info & Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Song Title & Like Button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 28,
                    ),
                    color: isLiked ? Colors.red : Colors.white,
                    onPressed: () {
                      if (!authProvider.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in to like songs')),
                        );
                        return;
                      }
                      playlistProvider.toggleLikeSong(song);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress Bar
              ProgressBar(
                progress: player.position,
                total: player.duration,
                buffered: player.duration,
                onSeek: player.seek,
                barHeight: 4,
                thumbRadius: 6,
                thumbGlowRadius: 15,
                progressBarColor: const Color(0xFF1DB954),
                bufferedBarColor: const Color(0xFF1DB954).withValues(alpha: 0.3),
                baseBarColor: Colors.grey[800]!,
                thumbColor: Colors.white,
                thumbGlowColor: const Color(0xFF1DB954).withValues(alpha: 0.3),
                timeLabelTextStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),

              const SizedBox(height: 20),

              // Main Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: player.isShuffleOn ? const Color(0xFF1DB954) : Colors.white,
                    ),
                    iconSize: 24,
                    onPressed: player.toggleShuffle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: Colors.white,
                    iconSize: 40,
                    onPressed: player.playPrevious,
                  ),
                  // Play/Pause Button
                  GestureDetector(
                    onTap: player.togglePlayPause,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: player.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                              ),
                            )
                          : Icon(
                              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.black,
                            ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    color: Colors.white,
                    iconSize: 40,
                    onPressed: player.playNext,
                  ),
                  IconButton(
                    icon: Icon(
                      player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                      color: player.loopMode != LoopMode.off ? const Color(0xFF1DB954) : Colors.white,
                    ),
                    iconSize: 24,
                    onPressed: player.toggleLoopMode,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded, size: 24),
                    color: Colors.grey[400],
                    onPressed: () => _showAddToPlaylist(context, song),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    color: Colors.grey[400],
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share: ${song.title} by ${song.artist}')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded, size: 20),
                    color: Colors.grey[400],
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  void _showSongOptions(BuildContext context, SongModel song) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final isLiked = authProvider.isLoggedIn ? playlistProvider.isSongLikedSync(song.id) : false;

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
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
              title: Text(
                isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
                style: const TextStyle(color: Colors.white),
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylist(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share: ${song.title} by ${song.artist}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, SongModel song) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to playlists')),
      );
      return;
    }

    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final playlists = playlistProvider.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
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
            const Text(
              'Add to Playlist',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Color(0xFF1DB954)),
              ),
              title: const Text('Create New Playlist', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, song, playlistProvider);
              },
            ),
            const Divider(color: Colors.grey),
            if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No playlists yet. Create one!', style: TextStyle(color: Colors.grey)),
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
                          color: const Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: playlist.coverUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(imageUrl: playlist.coverUrl!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.queue_music, color: Colors.white54),
                      ),
                      title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: Text('${playlist.songCount} songs', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () async {
                        Navigator.pop(context);
                        await playlistProvider.addSongToPlaylist(playlist.id, song);
                        ScaffoldMessenger.of(context).showSnackBar(
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

  void _showCreatePlaylistDialog(BuildContext context, SongModel song, PlaylistProvider playlistProvider) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Create Playlist', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF2a2a2a),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newPlaylist = await playlistProvider.createPlaylist(name);
                      if (newPlaylist != null) {
                        await playlistProvider.addSongToPlaylist(newPlaylist.id, song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to "$name"')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Create & Add Song', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
