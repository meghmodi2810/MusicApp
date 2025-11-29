import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/song_tile.dart';
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

  final List<Map<String, dynamic>> _quickPicks = [
    {'title': 'Liked Songs', 'icon': Icons.favorite, 'color': const Color(0xFF7C4DFF)},
    {'title': 'Recently Played', 'icon': Icons.history, 'color': const Color(0xFF1DB954)},
    {'title': 'Top Hits', 'icon': Icons.trending_up, 'color': const Color(0xFFFF6B6B)},
    {'title': 'Discover', 'icon': Icons.explore, 'color': const Color(0xFF4ECDC4)},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _apiService.searchSongs('trending songs 2024'),
        _apiService.searchSongs('new hindi songs'),
        _apiService.searchSongs('chill lofi'),
      ]);
      
      setState(() {
        _trendingSongs = results[0];
        _newReleases = results[1];
        _chillVibes = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = themeProvider.primaryColor;
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            // Gradient App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            primaryColor.withValues(alpha: 0.3),
                            themeProvider.backgroundColor,
                          ]
                        : [
                            primaryColor.withValues(alpha: 0.1),
                            themeProvider.backgroundColor,
                          ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: isDark ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Melodify',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),

            // Quick Picks Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _quickPicks.length,
                  itemBuilder: (context, index) {
                    final pick = _quickPicks[index];
                    return _buildQuickPickCard(pick, isDark);
                  },
                ),
              ),
            ),

            // Trending Section
            _buildSectionHeader('🔥 Trending Now', () {}, isDark),
            _isLoading
                ? _buildShimmerCards(isDark)
                : _buildHorizontalSongList(_trendingSongs),

            // New Releases
            _buildSectionHeader('✨ New Releases', () {}, isDark),
            _isLoading
                ? _buildShimmerCards(isDark)
                : _buildHorizontalSongList(_newReleases),

            // Chill Vibes
            _buildSectionHeader('🎧 Chill Vibes', () {}, isDark),
            _isLoading
                ? _buildShimmerCards(isDark)
                : _buildHorizontalSongList(_chillVibes),

            // Top Songs List
            if (_trendingSongs.isNotEmpty) ...[
              _buildSectionHeader('📈 Top Charts', () {}, isDark),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _trendingSongs.length || index >= 5) return null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SongTile(
                        song: _trendingSongs[index],
                        playlist: _trendingSongs,
                        index: index + 1,
                      ),
                    );
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
    );
  }

  Widget _buildQuickPickCard(Map<String, dynamic> pick, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: pick['color'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Icon(pick['icon'], color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pick['title'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, VoidCallback onSeeAll, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all',
                style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHorizontalSongList(List<SongModel> songs) {
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

  SliverToBoxAdapter _buildShimmerCards(bool isDark) {
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
                baseColor: isDark ? const Color(0xFF1a1a1a) : Colors.grey[300]!,
                highlightColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]!,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
