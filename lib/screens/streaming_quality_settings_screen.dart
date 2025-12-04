import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/music_player_provider.dart'; // Added for audio effects

class StreamingQualitySettingsScreen extends StatelessWidget {
  const StreamingQualitySettingsScreen({super.key});

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
          'Streaming & Quality',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
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
            onTap: () => _showAudioQualityDialog(
              context,
              themeProvider,
              settingsProvider,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.download,
            title: 'Download Quality',
            subtitle: '${settingsProvider.downloadBitrate} kbps',
            themeProvider: themeProvider,
            onTap: () => _showDownloadQualityDialog(
              context,
              themeProvider,
              settingsProvider,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.wifi,
            title: 'Download over WiFi only',
            subtitle: 'Save mobile data',
            themeProvider: themeProvider,
            trailing: Switch(
              value: settingsProvider.downloadOverWifiOnly,
              onChanged: (value) =>
                  settingsProvider.setDownloadOverWifiOnly(value),
              activeColor: accentColor,
            ),
          ),

          // NEW: Audio Effects Section
          _buildSectionHeader('Audio Effects', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.graphic_eq,
            title: 'Bass Boost',
            subtitle: settingsProvider.bassBoostEnabled
                ? '${(settingsProvider.bassBoostLevel * 100).round()}%'
                : 'Off',
            themeProvider: themeProvider,
            onTap: () =>
                _showBassBoostDialog(context, themeProvider, settingsProvider),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.waves,
            title: 'Reverb',
            subtitle: settingsProvider.reverbEnabled
                ? '${(settingsProvider.reverbLevel * 100).round()}%'
                : 'Off',
            themeProvider: themeProvider,
            onTap: () =>
                _showReverbDialog(context, themeProvider, settingsProvider),
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
          child: Icon(icon, color: themeProvider.primaryColor, size: 22),
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
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right,
                    color: themeProvider.secondaryTextColor,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showAudioQualityDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
  ) {
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
          ].map(
            (quality) => ListTile(
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
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDownloadQualityDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
  ) {
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
          ].map(
            (quality) => ListTile(
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
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showBassBoostDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
  ) {
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
            Icon(Icons.graphic_eq, size: 48, color: themeProvider.primaryColor),
            const SizedBox(height: 12),
            Text(
              'Bass Boost',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enhance low-frequency sounds',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(
                'Enable Bass Boost',
                style: TextStyle(color: themeProvider.textColor),
              ),
              value: settingsProvider.bassBoostEnabled,
              onChanged: (value) async {
                await settingsProvider.setBassBoostEnabled(value);
                final player = Provider.of<MusicPlayerProvider>(
                  context,
                  listen: false,
                );
                await player.setBassBoost(
                  value,
                  settingsProvider.bassBoostLevel,
                );
                setState(() {});
              },
              activeColor: themeProvider.primaryColor,
            ),
            if (settingsProvider.bassBoostEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bass Level',
                          style: TextStyle(color: themeProvider.textColor),
                        ),
                        Text(
                          '${(settingsProvider.bassBoostLevel * 100).round()}%',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settingsProvider.bassBoostLevel,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: themeProvider.primaryColor,
                      inactiveColor: themeProvider.primaryColor.withOpacity(
                        0.3,
                      ),
                      onChanged: (value) async {
                        await settingsProvider.setBassBoostLevel(value);
                        final player = Provider.of<MusicPlayerProvider>(
                          context,
                          listen: false,
                        );
                        await player.setBassBoost(
                          settingsProvider.bassBoostEnabled,
                          value,
                        );
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

  void _showReverbDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
  ) {
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
            Icon(Icons.waves, size: 48, color: themeProvider.primaryColor),
            const SizedBox(height: 12),
            Text(
              'Reverb',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add room acoustics and spaciousness',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(
                'Enable Reverb',
                style: TextStyle(color: themeProvider.textColor),
              ),
              value: settingsProvider.reverbEnabled,
              onChanged: (value) async {
                await settingsProvider.setReverbEnabled(value);
                final player = Provider.of<MusicPlayerProvider>(
                  context,
                  listen: false,
                );
                await player.setReverb(value, settingsProvider.reverbLevel);
                setState(() {});
              },
              activeColor: themeProvider.primaryColor,
            ),
            if (settingsProvider.reverbEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reverb Level',
                          style: TextStyle(color: themeProvider.textColor),
                        ),
                        Text(
                          '${(settingsProvider.reverbLevel * 100).round()}%',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settingsProvider.reverbLevel,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: themeProvider.primaryColor,
                      inactiveColor: themeProvider.primaryColor.withOpacity(
                        0.3,
                      ),
                      onChanged: (value) async {
                        await settingsProvider.setReverbLevel(value);
                        final player = Provider.of<MusicPlayerProvider>(
                          context,
                          listen: false,
                        );
                        await player.setReverb(
                          settingsProvider.reverbEnabled,
                          value,
                        );
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
