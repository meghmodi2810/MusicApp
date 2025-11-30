import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../models/song_model.dart';
import '../services/music_api_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MusicApiService _apiService = MusicApiService();
  final FocusNode _focusNode = FocusNode();
  
  List<SongModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _genres = [
    {'name': 'Pop', 'color': const Color(0xFFE85D04), 'icon': Icons.music_note},
    {'name': 'Rock', 'color': const Color(0xFFBF3100), 'icon': Icons.electric_bolt},
    {'name': 'Jazz', 'color': const Color(0xFF8B2500), 'icon': Icons.piano},
    {'name': 'Other', 'color': const Color(0xFF5C1A00), 'icon': Icons.library_music},
    {'name': 'Hip-Hop', 'color': const Color(0xFFE85D04), 'icon': Icons.headphones},
    {'name': 'EDM', 'color': const Color(0xFFBF3100), 'icon': Icons.speaker},
    {'name': 'Classical', 'color': const Color(0xFF8B2500), 'icon': Icons.queue_music},
    {'name': 'Bollywood', 'color': const Color(0xFF5C1A00), 'icon': Icons.movie},
    {'name': 'Punjabi', 'color': const Color(0xFFE85D04), 'icon': Icons.celebration},
    {'name': 'Lofi', 'color': const Color(0xFFBF3100), 'icon': Icons.nights_stay},
    {'name': 'Romantic', 'color': const Color(0xFF8B2500), 'icon': Icons.favorite},
    {'name': 'Party', 'color': const Color(0xFF5C1A00), 'icon': Icons.celebration},
  ];

  // Debounced search - AJAX style
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    // Set loading state immediately for better UX
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    // Debounce the actual search by 400ms
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final results = await _apiService.searchSongs(query).timeout(
        const Duration(seconds: 10),
        onTimeout: () => <SongModel>[],
      );

      if (mounted && _searchController.text.trim() == query.trim()) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
  }

  void _searchByGenre(String genre) {
    _searchController.text = genre;
    _onSearchChanged('$genre songs');
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
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What do you want to listen to?',
                    hintMaxLines: 1,
                    hintStyle: TextStyle(
                      color: secondaryText,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: accentColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: secondaryText,
                            ),
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
                    enabledBorder: OutlineInputBorder(
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

            // Content
            Expanded(
              child: _hasSearched 
                  ? _buildSearchResults(themeProvider) 
                  : _buildGenreGrid(themeProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreGrid(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse all',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _genres.length,
            itemBuilder: (context, index) {
              final genre = _genres[index];
              return _buildGenreCard(genre, themeProvider);
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildGenreCard(Map<String, dynamic> genre, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => _searchByGenre(genre['name']),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              genre['color'],
              (genre['color'] as Color).withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (genre['color'] as Color).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Transform.rotate(
                angle: 0.3,
                child: Icon(
                  genre['icon'],
                  size: 60,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                genre['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: themeProvider.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              '${_searchResults.length} results',
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          );
        }
        return SongTile(
          song: _searchResults[index - 1],
          playlist: _searchResults,
        );
      },
    );
  }
}
