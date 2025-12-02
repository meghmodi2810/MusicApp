import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/song_tile.dart';

class SeeAllRecommendationsScreen extends StatefulWidget {
  final String title;
  final List<SongModel> songs;

  const SeeAllRecommendationsScreen({
    super.key,
    required this.title,
    required this.songs,
  });

  @override
  State<SeeAllRecommendationsScreen> createState() => _SeeAllRecommendationsScreenState();
}

class _SeeAllRecommendationsScreenState extends State<SeeAllRecommendationsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<SongModel> _displayedSongs = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialPage() {
    setState(() {
      _displayedSongs = widget.songs.take(_itemsPerPage).toList();
      _currentPage = 1;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSongs();
    }
  }

  void _loadMoreSongs() {
    if (_isLoadingMore) return;
    
    final startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= widget.songs.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate pagination delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.songs.length);
      final newSongs = widget.songs.sublist(startIndex, endIndex);

      setState(() {
        _displayedSongs.addAll(newSongs);
        _currentPage++;
        _isLoadingMore = false;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: themeProvider.secondaryTextColor.withOpacity(0.1),
          ),
        ),
      ),
      body: Column(
        children: [
          // Count header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${widget.songs.length} songs',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Songs list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _displayedSongs.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _displayedSongs.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                
                return SongTile(
                  song: _displayedSongs[index],
                  playlist: widget.songs,
                  index: index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
