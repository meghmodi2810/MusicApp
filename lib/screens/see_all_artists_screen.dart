import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist_model.dart';
import '../providers/theme_provider.dart';
import 'artist_screen.dart';

class SeeAllArtistsScreen extends StatefulWidget {
  final String title;
  final List<ArtistModel> artists;

  const SeeAllArtistsScreen({
    super.key,
    required this.title,
    required this.artists,
  });

  @override
  State<SeeAllArtistsScreen> createState() => _SeeAllArtistsScreenState();
}

class _SeeAllArtistsScreenState extends State<SeeAllArtistsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ArtistModel> _displayedArtists = [];
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
      _displayedArtists = widget.artists.take(_itemsPerPage).toList();
      _currentPage = 1;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreArtists();
    }
  }

  void _loadMoreArtists() {
    if (_isLoadingMore) return;
    
    final startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= widget.artists.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.artists.length);
      final newArtists = widget.artists.sublist(startIndex, endIndex);

      setState(() {
        _displayedArtists.addAll(newArtists);
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${widget.artists.length} artists',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _displayedArtists.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _displayedArtists.length) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  );
                }
                
                return _buildArtistCard(_displayedArtists[index], themeProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtistScreen(artist: artist),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.primaryColor.withOpacity(0.1),
              ),
              child: ClipOval(
                child: artist.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.person, color: themeProvider.primaryColor, size: 40),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.person, color: themeProvider.primaryColor, size: 40),
                        ),
                      )
                    : Icon(Icons.person, color: themeProvider.primaryColor, size: 40),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
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
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
