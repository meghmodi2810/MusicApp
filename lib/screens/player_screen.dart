import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/music_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/song_model.dart';
import 'queue_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final animDuration = themeProvider.getAnimationDuration(const Duration(milliseconds: 300));
    
    _controller = AnimationController(
      duration: animDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final reduceBlur = themeProvider.reduceAnimations; // Check if animations are reduced
    
    return WillPopScope(
      onWillPop: () async {
        if (!themeProvider.reduceAnimations) {
          await _controller.reverse();
        }
        return true;
      },
      child: Consumer<MusicPlayerProvider>(
        builder: (context, player, child) {
          final song = player.currentSong;
          
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: themeProvider.backgroundColor,
            body: Stack(
              children: [
                // Background image - only show blur if animations enabled
                if (song?.albumArt != null && !reduceBlur)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: song!.albumArt!,
                      fit: BoxFit.cover,
                      memCacheHeight: 300,
                      errorWidget: (context, url, error) => Container(
                        color: themeProvider.backgroundColor,
                      ),
                    ),
                  ),
                
                // Minimal blur when animations enabled, none when disabled
                if (!reduceBlur)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Reduced from 15
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              themeProvider.backgroundColor.withOpacity(0.6),
                              themeProvider.backgroundColor.withOpacity(0.85),
                              themeProvider.backgroundColor.withOpacity(0.95),
                              themeProvider.backgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Content with conditional fade animation
                reduceBlur
                    ? SafeArea(
                        child: song == null
                            ? _buildNoSongPlaying(context, themeProvider)
                            : _buildPlayerContent(context, player, song, themeProvider),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SafeArea(
                          child: song == null
                              ? _buildNoSongPlaying(context, themeProvider)
                              : _buildPlayerContent(context, player, song, themeProvider),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoSongPlaying(BuildContext context, ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, size: 80, color: themeProvider.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            'No song playing',
            style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 18),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
            label: Text('Go Back', style: TextStyle(color: themeProvider.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent(BuildContext context, MusicPlayerProvider player, SongModel song, ThemeProvider themeProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final isLiked = authProvider.isLoggedIn ? playlistProvider.isSongLikedSync(song.id) : false;
    final accentColor = themeProvider.primaryColor;
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;

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
                color: textColor,
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                children: [
                  Text(
                    'PLAYING FROM',
                    style: TextStyle(color: secondaryText, fontSize: 10, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.album,
                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                color: textColor,
                onPressed: () => _showSongOptions(context, song, themeProvider),
              ),
            ],
          ),
        ),

        const Spacer(flex: 1),

        // Album Art
        Hero(
          tag: 'album_art_${song.id}',
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.highQualityArt,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: themeProvider.cardColor,
                        child: Center(child: CircularProgressIndicator(color: accentColor)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: themeProvider.cardColor,
                        child: Icon(Icons.music_note, size: 80, color: secondaryText),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.5)],
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
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: TextStyle(color: secondaryText, fontSize: 16),
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
                    color: isLiked ? Colors.red : textColor,
                    onPressed: () {
                      if (!authProvider.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please log in to like songs'),
                            backgroundColor: accentColor,
                          ),
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
                progressBarColor: accentColor,
                bufferedBarColor: accentColor.withOpacity(0.3),
                baseBarColor: secondaryText.withOpacity(0.3),
                thumbColor: accentColor,
                thumbGlowColor: accentColor.withOpacity(0.3),
                timeLabelTextStyle: TextStyle(color: secondaryText, fontSize: 12),
              ),

              const SizedBox(height: 20),

              // Main Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: player.isShuffleOn ? accentColor : textColor,
                    ),
                    iconSize: 24,
                    onPressed: player.toggleShuffle,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous_rounded, color: textColor),
                    iconSize: 40,
                    onPressed: player.playPrevious,
                  ),
                  // Play/Pause Button
                  GestureDetector(
                    onTap: player.togglePlayPause,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: player.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              ),
                            )
                          : Icon(
                              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next_rounded, color: textColor),
                    iconSize: 40,
                    onPressed: player.playNext,
                  ),
                  IconButton(
                    icon: Icon(
                      player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                      color: player.loopMode != LoopMode.off ? accentColor : textColor,
                    ),
                    iconSize: 24,
                    onPressed: player.toggleLoopMode,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bottom Actions - with Queue button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.playlist_add_rounded, size: 24, color: secondaryText),
                    onPressed: () => _showAddToPlaylist(context, song, themeProvider),
                  ),
                  IconButton(
                    icon: Icon(Icons.share_rounded, size: 20, color: secondaryText),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Share: ${song.title} by ${song.artist}'),
                          backgroundColor: accentColor,
                        ),
                      );
                    },
                  ),
                  // Queue button with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.queue_music_rounded, size: 24, color: secondaryText),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QueueScreen()),
                          );
                        },
                      ),
                      if (player.hasQueue)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${player.queueLength}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
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

  void _showSongOptions(BuildContext context, SongModel song, ThemeProvider themeProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final player = Provider.of<MusicPlayerProvider>(context, listen: false);
    final isLiked = authProvider.isLoggedIn ? playlistProvider.isSongLikedSync(song.id) : false;

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
            const SizedBox(height: 20),
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
              leading: Icon(Icons.queue_play_next, color: themeProvider.textColor),
              title: Text('Play Next', style: TextStyle(color: themeProvider.textColor)),
              onTap: () {
                Navigator.pop(context);
                player.addToQueueNext(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${song.title}" will play next'),
                    backgroundColor: themeProvider.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_to_queue, color: themeProvider.textColor),
              title: Text('Add to Queue', style: TextStyle(color: themeProvider.textColor)),
              onTap: () {
                Navigator.pop(context);
                player.addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Added to queue'),
                    backgroundColor: themeProvider.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add, color: themeProvider.textColor),
              title: Text('Add to Playlist', style: TextStyle(color: themeProvider.textColor)),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylist(context, song, themeProvider);
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: themeProvider.textColor),
              title: Text('Share', style: TextStyle(color: themeProvider.textColor)),
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
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, SongModel song, ThemeProvider themeProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to add to playlists'),
          backgroundColor: themeProvider.primaryColor,
        ),
      );
      return;
    }

    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
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
                _showCreatePlaylistDialog(context, song, playlistProvider, themeProvider);
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
                            : Icon(Icons.queue_music, color: themeProvider.primaryColor),
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
                        await playlistProvider.addSongToPlaylist(playlist.id, song);
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

  void _showCreatePlaylistDialog(BuildContext context, SongModel song, PlaylistProvider playlistProvider, ThemeProvider themeProvider) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      final newPlaylist = await playlistProvider.createPlaylist(name);
                      if (newPlaylist != null) {
                        await playlistProvider.addSongToPlaylist(newPlaylist.id, song);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
