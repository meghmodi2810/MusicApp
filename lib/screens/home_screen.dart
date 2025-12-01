import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/auth_provider.dart';
import 'settings_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final MusicApiService _apiService = MusicApiService();
  List<SongModel> _recommendedSongs = [];
  List<AlbumModel> _recommendedAlbums = [];
  List<ArtistModel> _recommendedArtists = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load all data in parallel for faster loading
      final results = await Future.wait([
        _apiService.getTrendingSongs(),
        _apiService.getTrendingAlbums(),
        _apiService.getTrendingArtists(),
      ]);
      
      if (mounted) {
        setState(() {
          _recommendedSongs = results[0] as List<SongModel>;
          _recommendedAlbums = results[1] as List<AlbumModel>;
          _recommendedArtists = results[2] as List<ArtistModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final authProvider = Provider.of<AuthProvider>(context);
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.primaryColor;
    
    String userName = 'Music Lover';
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      userName = authProvider.currentUser!['display_name'] ?? 'Music Lover';
    }
    
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: accentColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Simple Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: themeProvider.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.settings_outlined, color: textColor, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recommended Songs Section
              _buildSectionHeader('Recommended Songs', textColor),
              _isLoading
                  ? _buildLoadingIndicator()
                  : _buildSongsList(_recommendedSongs, themeProvider),

              // Recommended Albums Section
              if (_recommendedAlbums.isNotEmpty) ...[
                _buildSectionHeader('Recommended Albums', textColor),
                _buildAlbumsList(_recommendedAlbums, themeProvider),
              ],

              // Recommended Artists Section
              if (_recommendedArtists.isNotEmpty) ...[
                _buildSectionHeader('Recommended Artists', textColor),
                _buildArtistsList(_recommendedArtists, themeProvider),
              ],

              // Bottom Padding for mini player
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: Provider.of<ThemeProvider>(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSongsList(List<SongModel> songs, ThemeProvider themeProvider) {
    if (songs.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No songs available',
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
              child: _buildSongCard(songs[index], songs, themeProvider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSongCard(SongModel song, List<SongModel> playlist, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        context.read<MusicPlayerProvider>().playSong(song, playlist: playlist);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: themeProvider.cardColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: song.albumArt != null
                    ? CachedNetworkImage(
                        imageUrl: song.albumArt!,
                        fit: BoxFit.cover,
                        memCacheWidth: 280,
                        placeholder: (_, __) => Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                        ),
                      )
                    : Container(
                        color: themeProvider.cardColor,
                        child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: TextStyle(
                color: themeProvider.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsList(List<AlbumModel> albums, ThemeProvider themeProvider) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildAlbumCard(albums[index], themeProvider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlbumCard(AlbumModel album, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () async {
        // Load and play album songs
        final songs = await _apiService.getAlbumSongs(album.id);
        if (songs.isNotEmpty && mounted) {
          context.read<MusicPlayerProvider>().playSong(songs.first, playlist: songs);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        }
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: themeProvider.cardColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: album.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: album.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 280,
                        placeholder: (_, __) => Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.album, color: themeProvider.secondaryTextColor),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.album, color: themeProvider.secondaryTextColor),
                        ),
                      )
                    : Container(
                        color: themeProvider.cardColor,
                        child: Icon(Icons.album, color: themeProvider.secondaryTextColor),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: TextStyle(
                color: themeProvider.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              album.artist,
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistsList(List<ArtistModel> artists, ThemeProvider themeProvider) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildArtistCard(artists[index], themeProvider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () async {
        // Load and play artist's top songs
        final songs = await _apiService.getArtistSongs(artist.id);
        if (songs.isNotEmpty && mounted) {
          context.read<MusicPlayerProvider>().playSong(songs.first, playlist: songs);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        }
      },
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.cardColor,
              ),
              child: ClipOval(
                child: artist.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 240,
                        placeholder: (_, __) => Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.person, color: themeProvider.secondaryTextColor, size: 48),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: themeProvider.cardColor,
                          child: Icon(Icons.person, color: themeProvider.secondaryTextColor, size: 48),
                        ),
                      )
                    : Container(
                        color: themeProvider.cardColor,
                        child: Icon(Icons.person, color: themeProvider.secondaryTextColor, size: 48),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: TextStyle(
                color: themeProvider.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
