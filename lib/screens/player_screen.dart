import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;
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

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Consumer<MusicPlayerProvider>(
      builder: (context, player, child) {
        final song = player.currentSong;
        
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SafeArea(
            child: song == null
                ? _buildNoSongPlaying(context, themeProvider)
                : _buildPlayerContent(context, player, song, themeProvider),
          ),
        );
      },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                    color: themeProvider.textColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 28),
                    color: themeProvider.textColor,
                    onPressed: () => _showSongOptions(context, song, themeProvider),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              // Album Art Card with theme colors
              Container(
                width: screenWidth * 0.75,
                height: screenWidth * 0.75,
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArt != null
                      ? CachedNetworkImage(
                          imageUrl: song.highQualityArt,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: themeProvider.cardColor,
                            child: Center(child: CircularProgressIndicator(color: themeProvider.primaryColor)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: themeProvider.cardColor,
                            child: Icon(Icons.music_note, size: 60, color: themeProvider.secondaryTextColor),
                          ),
                        )
                      : Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.music_note, size: 60, color: themeProvider.secondaryTextColor),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // Song Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  song.title,
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8),

              // Artist & Album
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  song.artist,
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 28),

              // Wavy Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    WavySlider(
                      value: player.position.inSeconds.toDouble(),
                      max: player.duration.inSeconds > 0 ? player.duration.inSeconds.toDouble() : 1.0,
                      onChanged: (value) {
                        player.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: themeProvider.primaryColor,
                      inactiveColor: themeProvider.secondaryTextColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(player.position),
                            style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatDuration(player.duration),
                            style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Main Controls with larger icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle, size: 28),
                    color: player.isShuffleOn ? themeProvider.primaryColor : themeProvider.textColor,
                    onPressed: player.toggleShuffle,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      color: themeProvider.cardColor,
                      onPressed: player.playPrevious,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Play/Pause Button - larger
                  GestureDetector(
                    onTap: player.togglePlayPause,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: player.isLoading
                          ? Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(color: themeProvider.cardColor, strokeWidth: 3),
                              ),
                            )
                          : Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 42,
                              color: themeProvider.cardColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      color: themeProvider.cardColor,
                      onPressed: player.playNext,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      player.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                      size: 28,
                    ),
                    color: player.loopMode != LoopMode.off ? themeProvider.primaryColor : themeProvider.textColor,
                    onPressed: player.toggleLoopMode,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Bottom actions - heart and queue
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 28,
                    ),
                    color: isLiked ? Colors.red : themeProvider.textColor,
                    onPressed: () {
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
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.queue_music, size: 28),
                    color: themeProvider.textColor,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.share, size: 26),
                    color: themeProvider.textColor,
                    onPressed: () {
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
              leading: Icon(Icons.queue_music, color: themeProvider.textColor),
              title: Text('View Queue', style: TextStyle(color: themeProvider.textColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));
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
}

// Custom Wavy Slider Widget
class WavySlider extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  const WavySlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = details.localPosition.dx;
        final width = box.size.width;
        final newValue = (localPosition / width * max).clamp(0.0, max);
        onChanged(newValue);
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = details.localPosition.dx;
        final width = box.size.width;
        final newValue = (localPosition / width * max).clamp(0.0, max);
        onChanged(newValue);
      },
      child: CustomPaint(
        size: const Size(double.infinity, 50),
        painter: WavySliderPainter(
          value: value,
          max: max,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
        ),
      ),
    );
  }
}

class WavySliderPainter extends CustomPainter {
  final double value;
  final double max;
  final Color activeColor;
  final Color inactiveColor;

  WavySliderPainter({
    required this.value,
    required this.max,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final progress = max > 0 ? value / max : 0.0;
    final activeWidth = size.width * progress;

    // Draw inactive wave
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final inactivePath = Path();
    final waveHeight = 8.0;
    final waveLength = 20.0;
    
    for (double i = 0; i <= size.width; i += 1) {
      final y = size.height / 2 + math.sin((i / waveLength) * 2 * math.pi) * waveHeight;
      if (i == 0) {
        inactivePath.moveTo(i, y);
      } else {
        inactivePath.lineTo(i, y);
      }
    }
    canvas.drawPath(inactivePath, inactivePaint);

    // Draw active wave
    if (activeWidth > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      final activePath = Path();
      for (double i = 0; i <= activeWidth; i += 1) {
        final y = size.height / 2 + math.sin((i / waveLength) * 2 * math.pi) * waveHeight;
        if (i == 0) {
          activePath.moveTo(i, y);
        } else {
          activePath.lineTo(i, y);
        }
      }
      canvas.drawPath(activePath, activePaint);

      // Draw thumb
      final thumbY = size.height / 2 + math.sin((activeWidth / waveLength) * 2 * math.pi) * waveHeight;
      canvas.drawCircle(
        Offset(activeWidth, thumbY),
        8,
        Paint()..color = activeColor,
      );
    }
  }

  @override
  bool shouldRepaint(WavySliderPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.max != max;
  }
}
