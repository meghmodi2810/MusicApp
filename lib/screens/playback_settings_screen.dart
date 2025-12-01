import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/music_player_provider.dart';

class PlaybackSettingsScreen extends StatelessWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Playback',
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
          // Audio Quality Section
          _buildSectionHeader('Audio Quality', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.graphic_eq,
            title: 'Streaming Quality',
            subtitle: '${settingsProvider.audioBitrate} kbps',
            themeProvider: themeProvider,
            onTap: () => _showAudioQualityDialog(context, themeProvider, settingsProvider),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.download,
            title: 'Download Quality',
            subtitle: '${settingsProvider.downloadBitrate} kbps',
            themeProvider: themeProvider,
            onTap: () => _showDownloadQualityDialog(context, themeProvider, settingsProvider),
          ),
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
          
          const SizedBox(height: 24),
          
          // Playback Features Section
          _buildSectionHeader('Playback Features', secondaryText),
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
                final player = Provider.of<MusicPlayerProvider>(context, listen: false);
                player.setVolumeNormalization(value);
              },
              activeColor: accentColor,
            ),
          ),
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
            'Streaming Quality',
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
}
