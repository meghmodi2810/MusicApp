import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album_model.dart';
import '../providers/theme_provider.dart';
import 'album_screen.dart';

class SeeAllAlbumsScreen extends StatefulWidget {
  final String title;
  final List<AlbumModel> albums;

  const SeeAllAlbumsScreen({
    super.key,
    required this.title,
    required this.albums,
  });

  @override
  State<SeeAllAlbumsScreen> createState() => _SeeAllAlbumsScreenState();
}

class _SeeAllAlbumsScreenState extends State<SeeAllAlbumsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<AlbumModel> _displayedAlbums = [];
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
      _displayedAlbums = widget.albums.take(_itemsPerPage).toList();
      _currentPage = 1;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreAlbums();
    }
  }

  void _loadMoreAlbums() {
    if (_isLoadingMore) return;
    
    final startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= widget.albums.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.albums.length);
      final newAlbums = widget.albums.sublist(startIndex, endIndex);

      setState(() {
        _displayedAlbums.addAll(newAlbums);
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
                  '${widget.albums.length} albums',
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
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _displayedAlbums.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _displayedAlbums.length) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  );
                }
                
                return _buildAlbumCard(_displayedAlbums[index], themeProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(AlbumModel album, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumScreen(album: album),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: album.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: album.highQualityImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.album, color: themeProvider.primaryColor),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          child: Icon(Icons.album, color: themeProvider.primaryColor),
                        ),
                      )
                    : Container(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.album, color: themeProvider.primaryColor),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
          ],
        ),
      ),
    );
  }
}
