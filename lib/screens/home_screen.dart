import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../widgets/song_card.dart';
import '../widgets/song_tile.dart';

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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF1DB954),
        child: CustomScrollView(
          slivers: [
            // Gradient App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a3a2a),
                      Color(0xFF0d0d0d),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1DB954), Color(0xFF1ed760)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Melodify',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
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
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                    return _buildQuickPickCard(pick);
                  },
                ),
              ),
            ),

            // Trending Section
            _buildSectionHeader('🔥 Trending Now', () {}),
            _isLoading
                ? _buildShimmerCards()
                : _buildHorizontalSongList(_trendingSongs),

            // New Releases
            _buildSectionHeader('✨ New Releases', () {}),
            _isLoading
                ? _buildShimmerCards()
                : _buildHorizontalSongList(_newReleases),

            // Chill Vibes
            _buildSectionHeader('🎧 Chill Vibes', () {}),
            _isLoading
                ? _buildShimmerCards()
                : _buildHorizontalSongList(_chillVibes),

            // Top Songs List
            if (_trendingSongs.isNotEmpty) ...[
              _buildSectionHeader('📈 Top Charts', () {}),
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

  Widget _buildQuickPickCard(Map<String, dynamic> pick) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(
                    color: Colors.white,
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

  SliverToBoxAdapter _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFF1DB954),
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

  SliverToBoxAdapter _buildShimmerCards() {
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
                baseColor: const Color(0xFF1a1a1a),
                highlightColor: const Color(0xFF2a2a2a),
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
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
