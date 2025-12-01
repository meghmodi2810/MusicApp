import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/music_player_provider.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final downloadService = Provider.of<DownloadService>(context);
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account', secondaryText),
          if (authProvider.isLoggedIn) ...[
            _buildAccountCard(context, authProvider, themeProvider),
          ] else ...[
            _buildLoginPrompt(context, themeProvider),
          ],
          
          const SizedBox(height: 24),
          
          // Color Scheme Section
          _buildSectionHeader(context, 'Appearance', secondaryText),
          _buildColorSchemeSelector(context, themeProvider),
          
          const SizedBox(height: 24),
          
          // Playback Section
          _buildSectionHeader(context, 'Playback', secondaryText),
          
          // Audio Quality
          _buildSettingsTile(
            context,
            icon: Icons.graphic_eq,
            title: 'Audio Quality',
            subtitle: '${settingsProvider.audioBitrate} kbps',
            themeProvider: themeProvider,
            onTap: () => _showAudioQualityDialog(context, themeProvider, settingsProvider),
          ),
          
          // Crossfade
          _buildSettingsTile(
            context,
            icon: Icons.swap_horiz,
            title: 'Crossfade',
            subtitle: settingsProvider.crossfadeEnabled 
                ? '${settingsProvider.crossfadeDuration} seconds'
                : 'Off',
            themeProvider: themeProvider,
            onTap: () => _showCrossfadeDialog(context, themeProvider, settingsProvider),
          ),
          
          // Volume Normalization
          _buildSettingsTile(
            context,
            icon: Icons.volume_up,
            title: 'Volume Normalization',
            subtitle: 'Set the same volume level for all songs',
            themeProvider: themeProvider,
            trailing: Switch(
              value: settingsProvider.volumeNormalization,
              onChanged: (value) {
                settingsProvider.setVolumeNormalization(value);
                // Sync with player
                final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                player.setVolumeNormalization(value);
              },
              activeColor: accentColor,
            ),
          ),
          
          // Gapless Playback
          _buildSettingsTile(
            context,
            icon: Icons.all_inclusive,
            title: 'Gapless Playback',
            subtitle: 'No silence between songs',
            themeProvider: themeProvider,
            trailing: Switch(
              value: settingsProvider.gaplessPlayback,
              onChanged: (value) => settingsProvider.setGaplessPlayback(value),
              activeColor: accentColor,
            ),
          ),
          
          // Autoplay
          _buildSettingsTile(
            context,
            icon: Icons.skip_next,
            title: 'Autoplay',
            subtitle: 'Play similar songs when music ends',
            themeProvider: themeProvider,
            trailing: Switch(
              value: settingsProvider.autoplay,
              onChanged: (value) => settingsProvider.setAutoplay(value),
              activeColor: accentColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Downloads Section
          _buildSectionHeader(context, 'Downloads', secondaryText),
          
          // Download Quality
          _buildSettingsTile(
            context,
            icon: Icons.download,
            title: 'Download Quality',
            subtitle: '${settingsProvider.downloadBitrate} kbps',
            themeProvider: themeProvider,
            onTap: () => _showDownloadQualityDialog(context, themeProvider, settingsProvider),
          ),
          
          // Download over WiFi only
          _buildSettingsTile(
            context,
            icon: Icons.wifi,
            title: 'Download over WiFi only',
            subtitle: 'Save mobile data',
            themeProvider: themeProvider,
            trailing: Switch(
              value: settingsProvider.downloadOverWifiOnly,
              onChanged: (value) => settingsProvider.setDownloadOverWifiOnly(value),
              activeColor: accentColor,
            ),
          ),
          
          // Downloaded Songs
          _buildSettingsTile(
            context,
            icon: Icons.folder,
            title: 'Downloaded Songs',
            subtitle: '${downloadService.downloadedSongs.length} songs (${downloadService.formattedTotalSize})',
            themeProvider: themeProvider,
            onTap: () => _showDownloadsDialog(context, themeProvider, downloadService),
          ),
          
          const SizedBox(height: 24),
          
          // Storage Section
          _buildSectionHeader(context, 'Storage', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.storage,
            title: 'Cache Size',
            subtitle: '${settingsProvider.cacheSize} MB used',
            themeProvider: themeProvider,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Free up space on your device',
            themeProvider: themeProvider,
            onTap: () => _showClearCacheDialog(context, themeProvider, settingsProvider),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader(context, 'About', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            themeProvider: themeProvider,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            themeProvider: themeProvider,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            themeProvider: themeProvider,
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          if (authProvider.isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context, authProvider, themeProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color secondaryText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: secondaryText,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthProvider authProvider, ThemeProvider themeProvider) {
    final user = authProvider.currentUser;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: themeProvider.primaryColor,
            child: Text(
              (user?['display_name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['display_name'] ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: themeProvider.secondaryTextColor,
            ),
            onPressed: () => _showEditProfileDialog(context, authProvider, themeProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_circle,
            size: 48,
            color: themeProvider.secondaryTextColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to sync your music',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save playlists, liked songs, and more',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSchemeSelector(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your color theme',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppColorScheme.values.map((scheme) {
              final isSelected = themeProvider.colorScheme == scheme;
              final previewColor = themeProvider.getSchemePreviewColor(scheme);
              final schemeName = themeProvider.getSchemeName(scheme);
              
              return GestureDetector(
                onTap: () => themeProvider.setColorScheme(scheme),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: themeProvider.primaryColor, width: 3)
                            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: previewColor.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: AppTheme.getTextColor(scheme), size: 24)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      schemeName.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? themeProvider.primaryColor : themeProvider.secondaryTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required ThemeProvider themeProvider,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: themeProvider.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: themeProvider.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.secondaryTextColor,
                ),
              )
            : null,
        trailing: trailing ?? (onTap != null 
            ? Icon(Icons.chevron_right, color: themeProvider.secondaryTextColor)
            : null),
        onTap: onTap,
      ),
    );
  }

  void _showAudioQualityDialog(BuildContext context, ThemeProvider themeProvider, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeProvider.secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Audio Quality',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Higher quality uses more data',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('low', 'Low', '96 kbps'),
            ('normal', 'Normal', '160 kbps'),
            ('high', 'High', '320 kbps'),
          ].map((quality) => ListTile(
            title: Text(
              quality.$2,
              style: TextStyle(color: themeProvider.textColor),
            ),
            subtitle: Text(
              quality.$3,
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
            trailing: settingsProvider.audioQuality == quality.$1
                ? Icon(Icons.check, color: themeProvider.primaryColor)
                : null,
            onTap: () {
              settingsProvider.setAudioQuality(quality.$1);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showCrossfadeDialog(BuildContext context, ThemeProvider themeProvider, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeProvider.secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Crossfade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Blend songs together for seamless transitions',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('Enable Crossfade', style: TextStyle(color: themeProvider.textColor)),
              value: settingsProvider.crossfadeEnabled,
              onChanged: (value) {
                settingsProvider.setCrossfadeEnabled(value);
                // Sync with player
                final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                player.setCrossfade(value, settingsProvider.crossfadeDuration);
                setState(() {});
              },
              activeColor: themeProvider.primaryColor,
            ),
            if (settingsProvider.crossfadeEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration',
                          style: TextStyle(color: themeProvider.textColor),
                        ),
                        Text(
                          '${settingsProvider.crossfadeDuration} seconds',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settingsProvider.crossfadeDuration.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      activeColor: themeProvider.primaryColor,
                      inactiveColor: themeProvider.primaryColor.withOpacity(0.3),
                      onChanged: (value) {
                        settingsProvider.setCrossfadeDuration(value.round());
                        // Sync with player
                        final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                        player.setCrossfade(settingsProvider.crossfadeEnabled, value.round());
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDownloadQualityDialog(BuildContext context, ThemeProvider themeProvider, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeProvider.secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Download Quality',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Higher quality uses more storage',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('low', 'Low', '96 kbps', '~1 MB per song'),
            ('normal', 'Normal', '160 kbps', '~2 MB per song'),
            ('high', 'High', '320 kbps', '~4 MB per song'),
          ].map((quality) => ListTile(
            title: Text(
              quality.$2,
              style: TextStyle(color: themeProvider.textColor),
            ),
            subtitle: Text(
              '${quality.$3} • ${quality.$4}',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
            trailing: settingsProvider.downloadQuality == quality.$1
                ? Icon(Icons.check, color: themeProvider.primaryColor)
                : null,
            onTap: () {
              settingsProvider.setDownloadQuality(quality.$1);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDownloadsDialog(BuildContext context, ThemeProvider themeProvider, DownloadService downloadService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeProvider.secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloaded Songs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  if (downloadService.downloadedSongs.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: themeProvider.cardColor,
                            title: Text('Delete All', style: TextStyle(color: themeProvider.textColor)),
                            content: Text(
                              'Remove all downloaded songs?',
                              style: TextStyle(color: themeProvider.secondaryTextColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
                              ),
                              TextButton(
                                onPressed: () {
                                  downloadService.deleteAllDownloads();
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Delete All',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: downloadService.downloadedSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_done,
                            size: 64,
                            color: themeProvider.secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No downloaded songs',
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: downloadService.downloadedSongs.length,
                      itemBuilder: (context, index) {
                        final song = downloadService.downloadedSongs[index];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.music_note, color: themeProvider.primaryColor),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(color: themeProvider.textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: TextStyle(color: themeProvider.secondaryTextColor),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              downloadService.deleteDownload(song.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, ThemeProvider themeProvider, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Cache',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: Text(
          'This will remove all cached data. Are you sure?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              settingsProvider.clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cache cleared'),
                  backgroundColor: themeProvider.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider, ThemeProvider themeProvider) {
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?['display_name'] ?? '');
    
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
          left: 24,
          right: 24,
          top: 24,
        ),
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
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: TextStyle(color: themeProvider.textColor),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(color: themeProvider.secondaryTextColor),
                filled: true,
                fillColor: themeProvider.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await authProvider.updateProfile({
                    'display_name': nameController.text.trim(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
