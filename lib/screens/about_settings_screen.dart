import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../services/download_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final downloadService = Provider.of<DownloadService>(context);
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
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
          // App Info Section
          _buildSectionHeader('App Information', secondaryText),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pancake Tunes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Storage Section
          _buildSectionHeader('Storage', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.storage,
            title: 'Cache Size',
            subtitle: '${settingsProvider.cacheSize} MB used',
            themeProvider: themeProvider,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.folder,
            title: 'Downloaded Songs',
            subtitle: '${downloadService.downloadedSongs.length} songs (${downloadService.formattedTotalSize})',
            themeProvider: themeProvider,
            onTap: () => _showDownloadsDialog(context, themeProvider, downloadService),
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
          
          // Legal Section
          _buildSectionHeader('Legal', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            themeProvider: themeProvider,
            onTap: () => _openUrl('https://pancaketunes.com/terms'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            themeProvider: themeProvider,
            onTap: () => _openUrl('https://pancaketunes.com/privacy'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gavel_outlined,
            title: 'Open Source Licenses',
            themeProvider: themeProvider,
            onTap: () => _showLicensesDialog(context, themeProvider),
          ),
          
          const SizedBox(height: 24),
          
          // Support Section
          _buildSectionHeader('Support', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            themeProvider: themeProvider,
            onTap: () => _openUrl('https://pancaketunes.com/help'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            themeProvider: themeProvider,
            onTap: () => _openUrl('https://github.com/pancaketunes/issues'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.email_outlined,
            title: 'Contact Us',
            subtitle: 'support@pancaketunes.com',
            themeProvider: themeProvider,
            onTap: () => _openUrl('mailto:support@pancaketunes.com'),
          ),
          
          const SizedBox(height: 24),
          
          // Credits
          _buildSectionHeader('Credits', secondaryText),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Made with ❤️ by the Pancake Tunes Team\n\nMusic data provided by Saavn API\nIcons by Material Design',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color secondaryText) {
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

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                      child: const Text('Delete All', style: TextStyle(color: Colors.red)),
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
                          Icon(Icons.download_done, size: 64, color: themeProvider.secondaryTextColor),
                          const SizedBox(height: 16),
                          Text(
                            'No downloaded songs',
                            style: TextStyle(fontSize: 16, color: themeProvider.secondaryTextColor),
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
                            onPressed: () => downloadService.deleteDownload(song.id),
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
        title: Text('Clear Cache', style: TextStyle(color: themeProvider.textColor)),
        content: Text(
          'This will remove all cached data. Are you sure?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: themeProvider.secondaryTextColor)),
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

  void _showLicensesDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Open Source Licenses', style: TextStyle(color: themeProvider.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'This app uses the following open source packages:',
                style: TextStyle(color: themeProvider.secondaryTextColor),
              ),
              const SizedBox(height: 16),
              ...[
                'flutter',
                'provider',
                'just_audio',
                'audio_service',
                'cached_network_image',
                'firebase_auth',
                'cloud_firestore',
                'shared_preferences',
              ].map((package) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• $package',
                  style: TextStyle(color: themeProvider.textColor, fontSize: 14),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: themeProvider.primaryColor)),
          ),
        ],
      ),
    );
  }
}
