import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_tile.dart';
import 'album_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final ArtistModel artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicApiService _apiService = MusicApiService();
  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _relatedArtists = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtistData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    setState(() => _isLoading = true);

    try {
      // Load all artist data in parallel
      final results = await Future.wait([
        _apiService.getArtistSongs(widget.artist.id),
        _apiService.getArtistAlbums(widget.artist.id),
        _apiService.getRelatedArtists(widget.artist.name),
      ]);

      if (mounted) {
        setState(() {
          _songs = results[0] as List<SongModel>;
          _albums = results[1] as List<AlbumModel>;
          _relatedArtists = results[2] as List<ArtistModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading artist data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final player = Provider.of<MusicPlayerProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Artist Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.artist.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.artist.highQualityImage,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.primaryColor,
                            themeProvider.primaryColor.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white54,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          themeProvider.backgroundColor.withOpacity(0.7),
                          themeProvider.backgroundColor,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.artist.isVerified == true)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Verified Artist',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          widget.artist.name,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        if (widget.artist.followerCount != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${_formatFollowers(widget.artist.followerCount!)} followers',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isEmpty
                          ? null
                          : () => player.playSong(_songs[0], playlist: _songs),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text(
                        'Play All',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _songs.isEmpty
                          ? null
                          : () {
                              player.toggleShuffle();
                              player.playSong(_songs[0], playlist: _songs);
                            },
                      icon: const Icon(Icons.shuffle, size: 24),
                      label: const Text(
                        'Shuffle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeProvider.primaryColor,
                        side: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: themeProvider.primaryColor,
                unselectedLabelColor: themeProvider.secondaryTextColor,
                indicatorColor: themeProvider.primaryColor,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Related'),
                ],
              ),
              themeProvider.backgroundColor,
            ),
          ),

          // Tab Content
          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: themeProvider.primaryColor,
                    ),
                  ),
                )
              : SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Songs Tab
                      _buildSongsTab(),
                      // Albums Tab (Discography)
                      _buildAlbumsTab(themeProvider),
                      // Related Artists Tab
                      _buildRelatedArtistsTab(themeProvider),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return Center(
        child: Text(
          'No songs available',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).secondaryTextColor,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        return SongTile(song: _songs[index], playlist: _songs);
      },
    );
  }

  Widget _buildAlbumsTab(ThemeProvider themeProvider) {
    if (_albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No albums available',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AlbumScreen(album: album)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: themeProvider.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: album.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: album.highQualityImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: themeProvider.cardColor,
                              child: Icon(
                                Icons.album,
                                color: themeProvider.secondaryTextColor,
                                size: 48,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: themeProvider.cardColor,
                              child: Icon(
                                Icons.album,
                                color: themeProvider.secondaryTextColor,
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: themeProvider.cardColor,
                            child: Icon(
                              Icons.album,
                              color: themeProvider.secondaryTextColor,
                              size: 48,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.name,
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (album.year != null)
                Text(
                  '${album.year}',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedArtistsTab(ThemeProvider themeProvider) {
    if (_relatedArtists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No related artists found',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: _relatedArtists.length,
      itemBuilder: (context, index) {
        final artist = _relatedArtists[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistDetailScreen(artist: artist),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeProvider.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: artist.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: artist.highQualityImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: themeProvider.cardColor,
                            child: Icon(
                              Icons.person,
                              color: themeProvider.secondaryTextColor,
                              size: 56,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: themeProvider.cardColor,
                            child: Icon(
                              Icons.person,
                              color: themeProvider.secondaryTextColor,
                              size: 56,
                            ),
                          ),
                        )
                      : Container(
                          color: themeProvider.cardColor,
                          child: Icon(
                            Icons.person,
                            color: themeProvider.secondaryTextColor,
                            size: 56,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artist.name,
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (artist.followerCount != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_formatFollowers(artist.followerCount!)} followers',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _StickyTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
