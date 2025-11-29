import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_player_provider.dart';
import '../models/song_model.dart';
import '../screens/login_screen.dart';
import '../screens/player_screen.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Playlists';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = themeProvider.primaryColor;

    if (!authProvider.isLoggedIn) {
      return _buildLoginPrompt(isDark, primaryColor);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              (authProvider.currentUser?['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'M',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Your Library',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => _showCreatePlaylistDialog(context, isDark, primaryColor, playlistProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['Playlists', 'Liked', 'Recent'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        backgroundColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[200],
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.w500,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Content based on filter
            if (_selectedFilter == 'Playlists')
              _buildPlaylistsSection(isDark, primaryColor, playlistProvider)
            else if (_selectedFilter == 'Liked')
              _buildLikedSongsSection(isDark, primaryColor, playlistProvider)
            else
              _buildRecentlyPlayedSection(isDark, primaryColor, playlistProvider),

            // Bottom Padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(bool isDark, Color primaryColor) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_rounded,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Your Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Log in to create playlists, save songs, and access your music library.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsSection(bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    final playlists = playlistProvider.playlists;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Liked Songs Card
            return _buildLikedSongsCard(isDark, primaryColor, playlistProvider);
          }
          
          if (index == 1) {
            // Create Playlist Card
            return _buildCreatePlaylistCard(isDark, primaryColor, playlistProvider);
          }

          final playlist = playlists[index - 2];
          return _buildPlaylistTile(playlist, isDark, primaryColor, playlistProvider);
        },
        childCount: playlists.length + 2,
      ),
    );
  }

  Widget _buildLikedSongsCard(bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 28),
      ),
      title: Text(
        'Liked Songs',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        'Playlist • ${playlistProvider.likedSongsCount} songs',
        style: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.push_pin, color: primaryColor, size: 16),
      onTap: () => _openLikedSongs(context, isDark, primaryColor, playlistProvider),
    );
  }

  Widget _buildCreatePlaylistCard(bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _showCreatePlaylistDialog(context, isDark, primaryColor, playlistProvider),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create playlist',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build a playlist with your favorite songs',
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(PlaylistModel playlist, bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    return Dismissible(
      key: Key('playlist_${playlist.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
            title: Text('Delete Playlist', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        playlistProvider.deletePlaylist(playlist.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${playlist.name}"')),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: playlist.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: playlist.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.music_note,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.music_note,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                  ),
                )
              : Icon(
                  Icons.queue_music,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  size: 28,
                ),
        ),
        title: Text(
          playlist.name,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Playlist • ${playlist.songCount} songs',
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        onTap: () => _openPlaylist(context, playlist, isDark, primaryColor, playlistProvider),
      ),
    );
  }

  Widget _buildLikedSongsSection(bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    final likedSongs = playlistProvider.likedSongs;

    if (likedSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No liked songs yet',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on any song to add it here',
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SongTile(
            song: likedSongs[index],
            playlist: likedSongs,
            index: index + 1,
          );
        },
        childCount: likedSongs.length,
      ),
    );
  }

  Widget _buildRecentlyPlayedSection(bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    final recentlyPlayed = playlistProvider.recentlyPlayed;

    if (recentlyPlayed.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No recently played songs',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start playing music to see your history',
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SongTile(
            song: recentlyPlayed[index],
            playlist: recentlyPlayed,
          );
        },
        childCount: recentlyPlayed.length,
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Playlist',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                      await playlistProvider.createPlaylist(name);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Created playlist "$name"')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Create',
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

  void _openLikedSongs(BuildContext context, bool isDark, Color primaryColor, PlaylistProvider playlistProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PlaylistDetailScreen(
          title: 'Liked Songs',
          songs: playlistProvider.likedSongs,
          coverGradient: [primaryColor, Colors.purple],
          icon: Icons.favorite,
          isDark: isDark,
          primaryColor: primaryColor,
        ),
      ),
    );
  }

  void _openPlaylist(BuildContext context, PlaylistModel playlist, bool isDark, Color primaryColor, PlaylistProvider playlistProvider) async {
    final songs = await playlistProvider.getPlaylistSongs(playlist.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PlaylistDetailScreen(
          title: playlist.name,
          songs: songs,
          coverUrl: playlist.coverUrl,
          playlistId: playlist.id,
          isDark: isDark,
          primaryColor: primaryColor,
        ),
      ),
    );
  }
}

class _PlaylistDetailScreen extends StatelessWidget {
  final String title;
  final List<SongModel> songs;
  final String? coverUrl;
  final List<Color>? coverGradient;
  final IconData? icon;
  final int? playlistId;
  final bool isDark;
  final Color primaryColor;

  const _PlaylistDetailScreen({
    required this.title,
    required this.songs,
    this.coverUrl,
    this.coverGradient,
    this.icon,
    this.playlistId,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: coverGradient != null
                      ? LinearGradient(
                          colors: coverGradient!,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: coverGradient == null ? (isDark ? const Color(0xFF2a2a2a) : Colors.grey[200]) : null,
                ),
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl!,
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withValues(alpha: 0.3),
                      )
                    : Center(
                        child: Icon(
                          icon ?? Icons.queue_music,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${songs.length} songs',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (songs.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                        player.playSong(songs.first, playlist: songs);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PlayerScreen()),
                        );
                      },
                      icon: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: isDark ? Colors.black : Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (songs.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No songs yet',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add songs to this playlist from search',
                        style: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongTile(
                    song: songs[index],
                    playlist: songs,
                    index: index + 1,
                  );
                },
                childCount: songs.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
