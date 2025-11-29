import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/music_player_provider.dart';

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
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
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

  Widget _buildPlayerContent(BuildContext context, MusicPlayerProvider player, dynamic song) {
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
                onPressed: () {},
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
                  color: const Color(0xFF1DB954).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
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
                    icon: const Icon(Icons.favorite_border_rounded, size: 28),
                    color: Colors.white,
                    onPressed: () {},
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
                bufferedBarColor: const Color(0xFF1DB954).withOpacity(0.3),
                baseBarColor: Colors.grey[800]!,
                thumbColor: Colors.white,
                thumbGlowColor: const Color(0xFF1DB954).withOpacity(0.3),
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
                    icon: const Icon(Icons.devices_rounded, size: 20),
                    color: Colors.grey[400],
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    color: Colors.grey[400],
                    onPressed: () {},
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
}
