import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lyrics_model.dart';
import '../models/song_model.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../services/lyrics_service.dart';

/// A widget that displays synced lyrics with auto-scrolling
class SyncedLyricsWidget extends StatefulWidget {
  final SongModel song;

  const SyncedLyricsWidget({
    super.key,
    required this.song,
  });

  @override
  State<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends State<SyncedLyricsWidget> {
  final LyricsService _lyricsService = LyricsService();
  final ScrollController _scrollController = ScrollController();
  
  LyricsModel? _lyrics;
  bool _isLoading = true;
  String? _error;
  int _currentLineIndex = -1;
  bool _userScrolling = false;
  Timer? _userScrollTimer;

  // Keys for each lyric line to scroll to
  final Map<int, GlobalKey> _lineKeys = {};

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(SyncedLyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _loadLyrics();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _lyrics = null;
      _currentLineIndex = -1;
      _lineKeys.clear();
    });

    try {
      final lyrics = await _lyricsService.getLyrics(
        songId: widget.song.id,
        title: widget.song.title,
        artist: widget.song.artist,
        duration: widget.song.duration,
      );

      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _isLoading = false;
          
          // Generate keys for each line
          if (lyrics != null) {
            for (int i = 0; i < lyrics.lines.length; i++) {
              _lineKeys[i] = GlobalKey();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load lyrics';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToLine(int index) {
    if (_userScrolling || !_scrollController.hasClients) return;
    if (index < 0 || _lineKeys[index] == null) return;

    final key = _lineKeys[index];
    final context = key?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.4, // Position the current line at 40% from top
      );
    }
  }

  void _onUserScroll() {
    _userScrolling = true;
    _userScrollTimer?.cancel();
    _userScrollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _userScrolling = false;
        });
        // Resume auto-scroll
        if (_currentLineIndex >= 0) {
          _scrollToLine(_currentLineIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return _buildLoadingState(themeProvider);
    }

    if (_error != null || _lyrics == null || !_lyrics!.hasLyrics) {
      return _buildNoLyricsState(themeProvider);
    }

    return _buildLyricsView(themeProvider);
  }

  Widget _buildLoadingState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: themeProvider.primaryColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading lyrics...',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLyricsState(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lyrics_outlined,
                size: 64,
                color: themeProvider.secondaryTextColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lyrics Not Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find lyrics for this song.\nTry another song or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadLyrics,
              icon: Icon(Icons.refresh, color: themeProvider.primaryColor),
              label: Text(
                'Retry',
                style: TextStyle(color: themeProvider.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsView(ThemeProvider themeProvider) {
    final player = Provider.of<MusicPlayerProvider>(context, listen: false);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          if (notification.dragDetails != null) {
            _onUserScroll();
          }
        }
        return false;
      },
      child: ValueListenableBuilder<Duration>(
        valueListenable: player.positionNotifier,
        builder: (context, position, child) {
          // Update current line index
          final newIndex = _lyrics!.getCurrentLineIndex(position);
          if (newIndex != _currentLineIndex) {
            _currentLineIndex = newIndex;
            // Auto-scroll to current line
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToLine(newIndex);
            });
          }

          return Column(
            children: [
              // Sync indicator
              if (_lyrics!.isSynced)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sync,
                        size: 14,
                        color: themeProvider.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Lyrics list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  itemCount: _lyrics!.lines.length,
                  itemBuilder: (context, index) {
                    final line = _lyrics!.lines[index];
                    final isCurrentLine = index == _currentLineIndex;
                    final isPastLine = index < _currentLineIndex;

                    return GestureDetector(
                      onTap: _lyrics!.isSynced
                          ? () {
                              // Seek to this line's timestamp
                              player.seek(line.timestamp);
                            }
                          : null,
                      child: Container(
                        key: _lineKeys[index],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isCurrentLine ? 22 : 18,
                            fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentLine
                                ? themeProvider.primaryColor
                                : isPastLine
                                    ? themeProvider.secondaryTextColor.withOpacity(0.5)
                                    : themeProvider.textColor.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          child: Text(line.text),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A full-screen lyrics view that can be shown as a modal
class LyricsBottomSheet extends StatelessWidget {
  final SongModel song;

  const LyricsBottomSheet({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lyrics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${song.title} • ${song.artist}',
                        style: TextStyle(
                          fontSize: 13,
                          color: themeProvider.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: themeProvider.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: themeProvider.secondaryTextColor.withOpacity(0.1),
            height: 1,
          ),
          // Lyrics content
          Expanded(
            child: SyncedLyricsWidget(song: song),
          ),
        ],
      ),
    );
  }

  /// Show the lyrics bottom sheet
  static void show(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => LyricsBottomSheet(song: song),
      ),
    );
  }
}
