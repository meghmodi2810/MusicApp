import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header with settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: themeProvider.textColor),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.settings_outlined, color: themeProvider.textColor),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Profile Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: authProvider.isLoggedIn
                    ? Center(
                        child: Text(
                          (authProvider.currentUser?['display_name'] as String?)
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              
              // User Name
              Text(
                authProvider.isLoggedIn
                    ? (authProvider.currentUser?['display_name'] ?? 'User')
                    : 'Guest User',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              if (authProvider.isLoggedIn) ...[
                const SizedBox(height: 4),
                Text(
                  authProvider.currentUser?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Stats Section - Simplified (no followers/following)
              if (authProvider.isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Liked', '${playlistProvider.likedSongsCount}', themeProvider),
                      Container(width: 1, height: 40, color: themeProvider.secondaryTextColor.withOpacity(0.2)),
                      _buildStatItem('Playlists', '${playlistProvider.playlists.length}', themeProvider),
                      Container(width: 1, height: 40, color: themeProvider.secondaryTextColor.withOpacity(0.2)),
                      _buildStatItem('Settings', '', themeProvider, icon: Icons.settings),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Recently Played Section
              if (playlistProvider.recentlyPlayed.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentItem(playlistProvider, themeProvider),
                const SizedBox(height: 24),
              ],
              
              // Your Playlists Section
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Playlists',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    Text(
                      'Seed',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Liked Songs Card
              _buildPlaylistItem(
                context,
                icon: Icons.favorite,
                title: 'Liked Songs',
                subtitle: 'Artist',
                themeProvider: themeProvider,
                onTap: () {},
              ),
              
              // User Playlists
              ...playlistProvider.playlists.take(3).map((playlist) => 
                _buildPlaylistItem(
                  context,
                  icon: Icons.queue_music,
                  title: playlist.name,
                  subtitle: 'Artist',
                  themeProvider: themeProvider,
                  onTap: () {},
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Login/Logout Button
              if (!authProvider.isLoggedIn)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 48,
                        color: themeProvider.secondaryTextColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'re browsing as a guest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to save your playlists and liked songs',
                        style: TextStyle(
                          fontSize: 13,
                          color: themeProvider.secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showLogoutDialog(context, authProvider, themeProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeProvider themeProvider, {IconData? icon}) {
    return GestureDetector(
      child: Column(
        children: [
          if (icon != null)
            Icon(icon, size: 24, color: themeProvider.primaryColor)
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(PlaylistProvider playlistProvider, ThemeProvider themeProvider) {
    final recent = playlistProvider.recentlyPlayed.isNotEmpty 
        ? playlistProvider.recentlyPlayed.first 
        : null;
    
    if (recent == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 50,
              height: 50,
              color: themeProvider.primaryColor.withOpacity(0.2),
              child: recent.albumArt != null
                  ? Image.network(recent.albumArt!, fit: BoxFit.cover)
                  : Icon(Icons.music_note, color: themeProvider.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recent.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  recent.artist,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: themeProvider.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: themeProvider.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: themeProvider.secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: TextStyle(color: themeProvider.textColor)),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
