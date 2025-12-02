import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_player_provider.dart';
import '../models/song_model.dart';
import '../services/download_service.dart';
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
    
    // Initialize download service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final downloadService = DownloadService();
      downloadService.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final accentColor = themeProvider.primaryColor;
    final textColor = themeProvider.textColor;
    final cardColor = themeProvider.cardColor;

    if (!authProvider.isLoggedIn) {
      return _buildLoginPrompt(themeProvider);
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
                              colors: [accentColor, accentColor.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              (authProvider.currentUser?['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'M',
                              style: const TextStyle(
                                color: Colors.white,
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
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, color: textColor),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: textColor),
                          onPressed: () => _showCreatePlaylistDialog(context, themeProvider, playlistProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips - UPDATED with Downloaded
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['Playlists', 'Liked', 'Downloaded', 'Recent'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        backgroundColor: cardColor,
                        selectedColor: accentColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Content based on filter
            if (_selectedFilter == 'Playlists')
              _buildPlaylistsSection(themeProvider, playlistProvider)
            else if (_selectedFilter == 'Liked')
              _buildLikedSongsSection(themeProvider, playlistProvider)
            else if (_selectedFilter == 'Downloaded')
              _buildDownloadedSection(themeProvider)
            else
              _buildRecentlyPlayedSection(themeProvider, playlistProvider),

            // Bottom Padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
          ],
        ),
      ),
    );
  }

  // NEW: Downloaded content section
  Widget _buildDownloadedSection(ThemeProvider themeProvider) {
    return Consumer<DownloadService>(
      builder: (context, downloadService, _) {
        final downloadedSongs = downloadService.downloadedSongs;

        if (downloadedSongs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.download_outlined, size: 64, color: themeProvider.secondaryTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'No downloaded content',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Download songs to listen offline',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
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
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${downloadedSongs.length} downloaded songs',
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.storage, size: 16, color: themeProvider.secondaryTextColor),
                          const SizedBox(width: 6),
                          Text(
                            downloadService.formattedTotalSize,
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showDeleteAllConfirmation(context, themeProvider, downloadService),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              final downloadedSong = downloadedSongs[index - 1];
              final song = downloadedSong.toSongModel();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: downloadedSong.albumArt != null
                          ? CachedNetworkImage(
                              imageUrl: downloadedSong.albumArt!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: themeProvider.primaryColor.withOpacity(0.1),
                                child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: themeProvider.primaryColor.withOpacity(0.1),
                                child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                              ),
                            )
                          : Container(
                              color: themeProvider.primaryColor.withOpacity(0.1),
                              child: Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                            ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          downloadedSong.title,
                          style: TextStyle(
                            color: themeProvider.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.download_done, color: themeProvider.primaryColor, size: 18),
                    ],
                  ),
                  subtitle: Text(
                    downloadedSong.artist,
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _showDeleteConfirmation(context, themeProvider, downloadService, downloadedSong),
                  ),
                  onTap: () {
                    final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                    final downloadedSongsList = downloadedSongs.map((d) => d.toSongModel()).toList();
                    player.playSong(song, playlist: downloadedSongsList);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  },
                ),
              );
            },
            childCount: downloadedSongs.length + 1,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ThemeProvider themeProvider, DownloadService downloadService, DownloadedSong song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Download', style: TextStyle(color: themeProvider.textColor)),
        content: Text(
          'Delete "${song.title}" from downloads?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              downloadService.deleteDownload(song.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Download deleted'),
                  backgroundColor: themeProvider.primaryColor,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context, ThemeProvider themeProvider, DownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All Downloads', style: TextStyle(color: themeProvider.textColor)),
        content: Text(
          'Delete all downloaded content? This will free up ${downloadService.formattedTotalSize}.',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              downloadService.deleteAllDownloads();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All downloads cleared'),
                  backgroundColor: themeProvider.primaryColor,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeProvider themeProvider) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeProvider.primaryColor, themeProvider.primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.library_music_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Log in to create playlists, save songs, and access your music library.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.secondaryTextColor,
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
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
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

  Widget _buildPlaylistsSection(ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    final playlists = playlistProvider.playlists;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return _buildLikedSongsCard(themeProvider, playlistProvider);
          }
          
          if (index == 1) {
            return _buildCreatePlaylistCard(themeProvider, playlistProvider);
          }

          final playlist = playlists[index - 2];
          return _buildPlaylistTile(playlist, themeProvider, playlistProvider);
        },
        childCount: playlists.length + 2,
      ),
    );
  }

  Widget _buildLikedSongsCard(ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeProvider.primaryColor, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 28),
        ),
        title: Text(
          'Liked Songs',
          style: TextStyle(
            color: themeProvider.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Playlist • ${playlistProvider.likedSongsCount} songs',
          style: TextStyle(
            color: themeProvider.secondaryTextColor,
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.push_pin, color: themeProvider.primaryColor, size: 16),
        onTap: () => _openLikedSongs(context, themeProvider, playlistProvider),
      ),
    );
  }

  Widget _buildCreatePlaylistCard(ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _showCreatePlaylistDialog(context, themeProvider, playlistProvider),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.secondaryTextColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add,
                  color: themeProvider.primaryColor,
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
                      color: themeProvider.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build a playlist with your favorite songs',
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor,
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

  Widget _buildPlaylistTile(PlaylistModel playlist, ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    return Dismissible(
      key: Key('playlist_${playlist.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: themeProvider.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Delete Playlist', style: TextStyle(color: themeProvider.textColor)),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
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
          SnackBar(
            content: Text('Deleted "${playlist.name}"'),
            backgroundColor: themeProvider.primaryColor,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: playlist.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: playlist.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                      errorWidget: (context, url, error) => Icon(Icons.music_note, color: themeProvider.secondaryTextColor),
                    ),
                  )
                : Icon(Icons.queue_music, color: themeProvider.primaryColor, size: 28),
          ),
          title: Text(
            playlist.name,
            style: TextStyle(
              color: themeProvider.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            'Playlist • ${playlist.songCount} songs',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 13,
            ),
          ),
          onTap: () => _openPlaylist(context, playlist, themeProvider, playlistProvider),
        ),
      ),
    );
  }

  Widget _buildLikedSongsSection(ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    final likedSongs = playlistProvider.likedSongs;

    if (likedSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 64, color: themeProvider.secondaryTextColor),
                const SizedBox(height: 16),
                Text(
                  'No liked songs yet',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on any song to add it here',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
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

  Widget _buildRecentlyPlayedSection(ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    final recentlyPlayed = playlistProvider.recentlyPlayed;

    if (recentlyPlayed.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 64, color: themeProvider.secondaryTextColor),
                const SizedBox(height: 16),
                Text(
                  'No recently played songs',
                  style: TextStyle(
                    color: themeProvider.textColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start playing music to see your history',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
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

  void _showCreatePlaylistDialog(BuildContext context, ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: themeProvider.secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Playlist',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: themeProvider.textColor),
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                  filled: true,
                  fillColor: themeProvider.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        SnackBar(
                          content: Text('Created playlist "$name"'),
                          backgroundColor: themeProvider.primaryColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _openLikedSongs(BuildContext context, ThemeProvider themeProvider, PlaylistProvider playlistProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PlaylistDetailScreen(
          title: 'Liked Songs',
          songs: playlistProvider.likedSongs,
          coverGradient: [themeProvider.primaryColor, Colors.purple],
          icon: Icons.favorite,
          themeProvider: themeProvider,
        ),
      ),
    );
  }

  void _openPlaylist(BuildContext context, PlaylistModel playlist, ThemeProvider themeProvider, PlaylistProvider playlistProvider) async {
    final songs = await playlistProvider.getPlaylistSongs(playlist.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PlaylistDetailScreen(
          title: playlist.name,
          songs: songs,
          coverUrl: playlist.coverUrl,
          playlistId: playlist.id,
          themeProvider: themeProvider,
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
  final ThemeProvider themeProvider;

  const _PlaylistDetailScreen({
    required this.title,
    required this.songs,
    this.coverUrl,
    this.coverGradient,
    this.icon,
    this.playlistId,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: themeProvider.backgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeProvider.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: TextStyle(
                  color: themeProvider.textColor,
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
                  color: coverGradient == null ? themeProvider.cardColor : null,
                ),
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl!,
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.3),
                      )
                    : Center(
                        child: Icon(
                          icon ?? Icons.queue_music,
                          size: 80,
                          color: Colors.white.withOpacity(0.8),
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
                      color: themeProvider.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (songs.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                        player.playSong(songs.first, playlist: songs);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PlayerScreen()),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
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
                      Icon(Icons.music_off, size: 64, color: themeProvider.secondaryTextColor),
                      const SizedBox(height: 16),
                      Text(
                        'No songs yet',
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add songs to this playlist from search',
                        style: TextStyle(
                          color: themeProvider.secondaryTextColor,
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
