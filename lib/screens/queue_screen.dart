import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_player_provider.dart';
import '../providers/theme_provider.dart';
import '../models/song_model.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Queue',
          style: TextStyle(
            color: themeProvider.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<MusicPlayerProvider>(
            builder: (context, player, _) {
              if (player.queue.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  player.clearQueue();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Queue cleared'),
                      backgroundColor: themeProvider.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Text(
                  'Clear',
                  style: TextStyle(color: themeProvider.primaryColor),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MusicPlayerProvider>(
        builder: (context, player, child) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Now Playing Section
              if (player.currentSong != null) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Now Playing', themeProvider),
                ),
                SliverToBoxAdapter(
                  child: _buildNowPlayingCard(player.currentSong!, player, themeProvider),
                ),
              ],

              // Queue Section
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Up Next${player.queue.isNotEmpty ? ' (${player.queue.length})' : ''}',
                  themeProvider,
                ),
              ),

              if (player.queue.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyQueue(themeProvider),
                )
              else
                SliverReorderableList(
                  itemCount: player.queue.length,
                  onReorder: (oldIndex, newIndex) {
                    player.reorderQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = player.queue[index];
                    return ReorderableDragStartListener(
                      key: ValueKey('${song.id}_$index'),
                      index: index,
                      child: _buildQueueItem(context, song, index, player, themeProvider),
                    );
                  },
                ),

              // Coming Up From Playlist
              if (player.playlist.isNotEmpty && player.currentIndex < player.playlist.length - 1) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Coming Up From Playlist', themeProvider),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final actualIndex = player.currentIndex + index + 1;
                      if (actualIndex >= player.playlist.length) return null;
                      final song = player.playlist[actualIndex];
                      return _buildPlaylistItem(context, song, actualIndex, player, themeProvider);
                    },
                    childCount: (player.playlist.length - player.currentIndex - 1).clamp(0, 10),
                  ),
                ),
              ],

              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeProvider.textColor,
        ),
      ),
    );
  }

  Widget _buildNowPlayingCard(SongModel song, MusicPlayerProvider player, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.primaryColor.withOpacity(0.2),
            themeProvider.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Album Art with animation
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArt!,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                    )
                  : Container(
                      color: themeProvider.primaryColor,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Playing indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              player.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueue(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 64,
            color: themeProvider.secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Your queue is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap and hold on any song to add it to the queue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    SongModel song,
    int index,
    MusicPlayerProvider player,
    ThemeProvider themeProvider,
  ) {
    return Dismissible(
      key: ValueKey('dismiss_${song.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        player.removeFromQueue(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${song.title}" from queue'),
            backgroundColor: themeProvider.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                player.addToQueue(song);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArt!,
                      fit: BoxFit.cover,
                      memCacheWidth: 100,
                    )
                  : Container(
                      color: themeProvider.primaryColor.withOpacity(0.2),
                      child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                    ),
            ),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist,
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow, color: themeProvider.primaryColor),
                onPressed: () {
                  player.removeFromQueue(index);
                  player.playSong(song);
                },
              ),
              Icon(
                Icons.drag_handle,
                color: themeProvider.secondaryTextColor,
              ),
            ],
          ),
          onTap: () {
            player.removeFromQueue(index);
            player.playSong(song);
          },
        ),
      ),
    );
  }

  Widget _buildPlaylistItem(
    BuildContext context,
    SongModel song,
    int index,
    MusicPlayerProvider player,
    ThemeProvider themeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child: song.albumArt != null
                ? CachedNetworkImage(
                    imageUrl: song.albumArt!,
                    fit: BoxFit.cover,
                    memCacheWidth: 100,
                  )
                : Container(
                    color: themeProvider.primaryColor.withOpacity(0.2),
                    child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                  ),
          ),
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: themeProvider.textColor.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: TextStyle(
            color: themeProvider.secondaryTextColor,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_to_queue, color: themeProvider.secondaryTextColor),
          onPressed: () {
            player.addToQueue(song);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${song.title}" to queue'),
                backgroundColor: themeProvider.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
        onTap: () => player.playSong(song, playlist: player.playlist),
      ),
    );
  }
}
