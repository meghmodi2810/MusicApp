import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/song_card.dart';
import 'settings_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final MusicApiService _apiService = MusicApiService();
  List<SongModel> _trendingSongs = [];
  bool _isLoading = true;

  // Cache for faster reloads
  static List<SongModel>? _cachedTrending;
  static List<SongModel>? _cachedNewReleases;
  static DateTime? _lastFetch;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    // Use cache if available and recent (less than 5 minutes old)
    if (_cachedTrending != null && 
        _cachedNewReleases != null && 
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      setState(() {
        _trendingSongs = _cachedTrending!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load data in parallel for faster loading
      final results = await Future.wait([
        _apiService.searchSongs('trending bollywood 2024').timeout(
          const Duration(seconds: 6),
          onTimeout: () => <SongModel>[],
        ),
        _apiService.searchSongs('new hindi songs 2024').timeout(
          const Duration(seconds: 6),
          onTimeout: () => <SongModel>[],
        ),
      ]);
      
      if (mounted) {
        _cachedTrending = results[0];
        _cachedNewReleases = results[1];
        _lastFetch = DateTime.now();
        
        setState(() {
          _trendingSongs = results[0];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.primaryColor;
    
    String userName = 'User';
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      userName = authProvider.currentUser!['display_name'] ?? 'User';
    }
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: accentColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Header - matching the template
              SliverToBoxAdapter(
                child: _buildHeader(themeProvider, textColor, accentColor, userName),
              ),

              // Get Started Section - only show for first time users
              if (settingsProvider.showGetStarted && !authProvider.isLoggedIn)
                SliverToBoxAdapter(
                  child: _buildGetStartedSection(themeProvider, accentColor, settingsProvider),
                ),

              // Daily Mix Card - like the template
              if (_trendingSongs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildDailyMixCard(themeProvider),
                ),

              // Jump Back In Section
              if (_trendingSongs.isNotEmpty) ...[
                _buildSectionHeader('Jump back in', textColor, accentColor),
                SliverToBoxAdapter(
                  child: _buildJumpBackInGrid(themeProvider),
                ),
              ],

              // Jump Bacters / Trending Section
              _buildSectionHeader('Jump Bacters', textColor, accentColor, showSeeAll: true),
              _isLoading
                  ? _buildShimmerCards(themeProvider)
                  : _buildHorizontalSongList(_trendingSongs, themeProvider),

              // Genres Section - like the template
              SliverToBoxAdapter(
                child: _buildGenresSection(themeProvider),
              ),

              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider, Color textColor, Color accentColor, String userName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu icon and greeting
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu, color: textColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, $userName!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Settings button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsScreen(),
                  transitionDuration: const Duration(milliseconds: 200),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings_outlined, color: textColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedSection(ThemeProvider themeProvider, Color accentColor, SettingsProvider settingsProvider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Music icon with headphones
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.album, size: 50, color: Colors.white.withOpacity(0.9)),
                const Positioned(
                  top: 8,
                  child: Icon(Icons.headphones, size: 32, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Listen to your\nfavorite music!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Discover new songs and artists',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              settingsProvider.setShowGetStarted(false);
              if (_trendingSongs.isNotEmpty) {
                final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                player.playSong(_trendingSongs.first, playlist: _trendingSongs);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMixCard(ThemeProvider themeProvider) {
    final song = _trendingSongs.isNotEmpty ? _trendingSongs.first : null;
    if (song == null) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () {
        final player = Provider.of<MusicPlayerProvider>(context, listen: false);
        player.playSong(song, playlist: _trendingSongs);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PlayerScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArt!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      memCacheWidth: 160,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 80,
                        color: themeProvider.primaryColor.withOpacity(0.2),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: themeProvider.primaryColor.withOpacity(0.2),
                        child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      child: Icon(Icons.music_note, color: themeProvider.primaryColor, size: 32),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Your Daily Mix*',
                      style: TextStyle(
                        fontSize: 10,
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpBackInGrid(ThemeProvider themeProvider) {
    final songs = _trendingSongs.take(4).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildJumpBackInItem(song, themeProvider);
        },
      ),
    );
  }

  Widget _buildJumpBackInItem(SongModel song, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        final player = Provider.of<MusicPlayerProvider>(context, listen: false);
        player.playSong(song, playlist: _trendingSongs);
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArt!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      memCacheWidth: 100,
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      child: Icon(Icons.music_note, color: themeProvider.primaryColor, size: 20),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                song.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildGenresSection(ThemeProvider themeProvider) {
    final genres = [
      {'name': 'Pop', 'color': const Color(0xFFE85D04), 'icon': Icons.music_note},
      {'name': 'Rock', 'color': const Color(0xFFBF3100), 'icon': Icons.electric_bolt},
      {'name': 'Jazz', 'color': const Color(0xFF8B4513), 'icon': Icons.piano},
      {'name': 'Tiles', 'color': const Color(0xFF5C1A00), 'icon': Icons.grid_view},
      {'name': 'Other', 'color': const Color(0xFF4A1C00), 'icon': Icons.library_music},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: genres.map((genre) => _buildGenreChip(genre, themeProvider)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(Map<String, dynamic> genre, ThemeProvider themeProvider) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: genre['color'] as Color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            genre['icon'] as IconData,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          genre['name'] as String,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, Color textColor, Color accentColor, {bool showSeeAll = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (showSeeAll)
              Text(
                'See All >',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHorizontalSongList(List<SongModel> songs, ThemeProvider themeProvider) {
    if (songs.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No songs found',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
          ),
        ),
      );
    }
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SongCard(
                song: songs[index],
                playlist: songs,
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildShimmerCards(ThemeProvider themeProvider) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Shimmer.fromColors(
                baseColor: themeProvider.cardColor,
                highlightColor: themeProvider.backgroundColor,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
