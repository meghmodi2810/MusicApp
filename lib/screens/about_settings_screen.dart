import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
}
