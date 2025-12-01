import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_tile.dart';

enum SearchFilter { songs, albums, artists }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MusicApiService _apiService = MusicApiService();
  final FocusNode _focusNode = FocusNode();
  
  List<SongModel> _songs = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  List<String> _recentSearches = [];
  
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;
  SearchFilter _currentFilter = SearchFilter.songs;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  // Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = searches;
    });
  }

  // Save search to recent searches
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    
    // Remove if already exists
    searches.remove(query);
    // Add to front
    searches.insert(0, query);
    // Keep only last 10
    if (searches.length > 10) {
      searches.removeRange(10, searches.length);
    }
    
    await prefs.setStringList('recent_searches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  // Clear recent searches
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  // Debounced search
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _songs = [];
        _albums = [];
        _artists = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // Fetch all three types simultaneously
      final results = await Future.wait([
        _apiService.searchSongs(query).timeout(const Duration(seconds: 10), onTimeout: () => <SongModel>[]),
        _apiService.searchAlbums(query).timeout(const Duration(seconds: 10), onTimeout: () => <AlbumModel>[]),
        _apiService.searchArtists(query).timeout(const Duration(seconds: 10), onTimeout: () => <ArtistModel>[]),
      ]);

      if (mounted && _searchController.text.trim() == query.trim()) {
        setState(() {
          _songs = results[0] as List<SongModel>;
          _albums = results[1] as List<AlbumModel>;
          _artists = results[2] as List<ArtistModel>;
          _isLoading = false;
        });
        
        // Save to recent searches
        _saveRecentSearch(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _songs = [];
          _albums = [];
          _artists = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectRecentSearch(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;
    final cardColor = themeProvider.cardColor;
    final accentColor = themeProvider.primaryColor;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: TextStyle(color: textColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Songs, albums, or artists',
                    hintStyle: TextStyle(color: secondaryText, fontSize: 16),
                    prefixIcon: Icon(Icons.search, color: accentColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: secondaryText),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),

            // Filter Tabs (only show when searching)
            if (_hasSearched)
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('Songs', SearchFilter.songs, _songs.length, themeProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('Albums', SearchFilter.albums, _albums.length, themeProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('Artists', SearchFilter.artists, _artists.length, themeProvider),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _hasSearched 
                  ? _buildSearchResults(themeProvider) 
                  : _buildRecentSearches(themeProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchFilter filter, int count, ThemeProvider themeProvider) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeProvider.primaryColor : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeProvider.primaryColor : themeProvider.secondaryTextColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : themeProvider.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : themeProvider.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : themeProvider.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(ThemeProvider themeProvider) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: themeProvider.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'Search for songs, albums, or artists',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text(
                  'Clear',
                  style: TextStyle(color: themeProvider.primaryColor),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: Icon(Icons.history, color: themeProvider.secondaryTextColor),
                title: Text(
                  search,
                  style: TextStyle(color: themeProvider.textColor),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: themeProvider.secondaryTextColor),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final searches = prefs.getStringList('recent_searches') ?? [];
                    searches.remove(search);
                    await prefs.setStringList('recent_searches', searches);
                    setState(() {
                      _recentSearches.remove(search);
                    });
                  },
                ),
                onTap: () => _selectRecentSearch(search),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(ThemeProvider themeProvider) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: themeProvider.cardColor,
            highlightColor: themeProvider.backgroundColor,
            child: Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      );
    }

    // Filter based on selected tab
    final hasResults = (_currentFilter == SearchFilter.songs && _songs.isNotEmpty) ||
                      (_currentFilter == SearchFilter.albums && _albums.isNotEmpty) ||
                      (_currentFilter == SearchFilter.artists && _artists.isNotEmpty);

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: themeProvider.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'No ${_currentFilter.name} found',
              style: TextStyle(color: themeProvider.textColor, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different filter or search term',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Show results based on filter
    switch (_currentFilter) {
      case SearchFilter.songs:
        return _buildSongsList(themeProvider);
      case SearchFilter.albums:
        return _buildAlbumsList(themeProvider);
      case SearchFilter.artists:
        return _buildArtistsList(themeProvider);
    }
  }

  Widget _buildSongsList(ThemeProvider themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _songs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(
              '${_songs.length} songs',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 14),
            ),
          );
        }
        return SongTile(song: _songs[index - 1], playlist: _songs);
      },
    );
  }

  Widget _buildAlbumsList(ThemeProvider themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_albums.length} albums',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 14),
            ),
          );
        }
        final album = _albums[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.imageUrl != null
                  ? Image.network(
                      album.highQualityImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: themeProvider.primaryColor.withOpacity(0.2),
                        child: Icon(Icons.album, color: themeProvider.primaryColor),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      child: Icon(Icons.album, color: themeProvider.primaryColor),
                    ),
            ),
            title: Text(
              album.name,
              style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${album.artist}${album.year != null ? ' • ${album.year}' : ''}',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right, color: themeProvider.secondaryTextColor),
            onTap: () async {
              // Fetch and play album songs
              final songs = await _apiService.getAlbumSongs(album.id);
              if (songs.isNotEmpty && mounted) {
                final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                player.playSong(songs[0], playlist: songs);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildArtistsList(ThemeProvider themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_artists.length} artists',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 14),
            ),
          );
        }
        final artist = _artists[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: artist.imageUrl != null ? NetworkImage(artist.imageUrl!) : null,
              backgroundColor: themeProvider.primaryColor.withOpacity(0.2),
              child: artist.imageUrl == null
                  ? Icon(Icons.person, color: themeProvider.primaryColor, size: 30)
                  : null,
            ),
            title: Text(
              artist.name,
              style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Artist',
              style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: themeProvider.secondaryTextColor),
            onTap: () async {
              // Fetch and play artist songs
              final songs = await _apiService.getArtistSongs(artist.id);
              if (songs.isNotEmpty && mounted) {
                final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                player.playSong(songs[0], playlist: songs);
              }
            },
          ),
        );
      },
    );
  }
}
