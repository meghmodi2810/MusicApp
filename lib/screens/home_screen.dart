import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicApiService _apiService = MusicApiService();
  List<SongModel> _trendingSongs = [];
  List<SongModel> _newReleases = [];
  List<SongModel> _chillVibes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load data in parallel for faster loading
      final results = await Future.wait([
        _apiService.searchSongs('trending songs 2024').timeout(
          const Duration(seconds: 8),
          onTimeout: () => <SongModel>[],
        ),
        _apiService.searchSongs('new hindi songs').timeout(
          const Duration(seconds: 8),
          onTimeout: () => <SongModel>[],
        ),
        _apiService.searchSongs('chill lofi').timeout(
          const Duration(seconds: 8),
          onTimeout: () => <SongModel>[],
        ),
      ]);
      
      if (mounted) {
        setState(() {
          _trendingSongs = results[0];
          _newReleases = results[1];
          _chillVibes = results[2];
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.primaryColor;
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: accentColor,
          child: CustomScrollView(
            slivers: [
              // App Header with decorative elements
              SliverToBoxAdapter(
                child: _buildHeader(themeProvider, textColor, accentColor),
              ),

              // Welcome Section - like the first screen in the image
              SliverToBoxAdapter(
                child: _buildWelcomeSection(themeProvider, textColor, accentColor),
              ),

              // Featured Song Card
              if (_trendingSongs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFeaturedCard(themeProvider, _trendingSongs.first),
                ),

              // Trending Section
              _buildSectionHeader('Trending Now', textColor, accentColor),
              _isLoading
                  ? _buildShimmerCards(themeProvider)
                  : _buildHorizontalSongList(_trendingSongs, themeProvider),

              // New Releases
              _buildSectionHeader('New Releases', textColor, accentColor),
              _isLoading
                  ? _buildShimmerCards(themeProvider)
                  : _buildHorizontalSongList(_newReleases, themeProvider),

              // Chill Vibes
              _buildSectionHeader('Chill Vibes', textColor, accentColor),
              _isLoading
                  ? _buildShimmerCards(themeProvider)
                  : _buildHorizontalSongList(_chillVibes, themeProvider),

              // Top Songs List - like the third screen in the image
              if (_trendingSongs.isNotEmpty) ...[
                _buildSectionHeader('Top Charts', textColor, accentColor),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _trendingSongs.length || index >= 5) return null;
                      return _buildSongListTile(_trendingSongs[index], index + 1, themeProvider);
                    },
                    childCount: _trendingSongs.length.clamp(0, 5),
                  ),
                ),
              ],

              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decorative elements
          Row(
            children: [
              Icon(Icons.star, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Icon(Icons.play_arrow, color: accentColor.withOpacity(0.6), size: 12),
            ],
          ),
          // Settings button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

  Widget _buildWelcomeSection(ThemeProvider themeProvider, Color textColor, Color accentColor) {
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
          // Decorative music icon with headphones - like the image
          Container(
            width: 120,
            height: 120,
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
                Icon(Icons.album, size: 60, color: Colors.white.withOpacity(0.9)),
                Positioned(
                  top: 10,
                  child: Icon(Icons.headphones, size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Listen to your\nfavorite music!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
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
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(ThemeProvider themeProvider, SongModel song) {
    final player = Provider.of<MusicPlayerProvider>(context, listen: false);
    
    return GestureDetector(
      onTap: () => player.playSong(song, playlist: _trendingSongs),
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
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: themeProvider.primaryColor.withOpacity(0.2),
                        child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: themeProvider.primaryColor.withOpacity(0.2),
                        child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      child: Icon(Icons.music_note, color: themeProvider.primaryColor, size: 40),
                    ),
            ),
            const SizedBox(width: 16),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                    maxLines: 2,
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
                  const SizedBox(height: 4),
                  Text(
                    song.album,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play button
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

  Widget _buildSongListTile(SongModel song, int index, ThemeProvider themeProvider) {
    final player = Provider.of<MusicPlayerProvider>(context, listen: false);
    
    return GestureDetector(
      onTap: () => player.playSong(song, playlist: _trendingSongs),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Index number
            SizedBox(
              width: 30,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
            ),
            // Song title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
            // Play indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: themeProvider.primaryColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, Color textColor, Color accentColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See all',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
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
