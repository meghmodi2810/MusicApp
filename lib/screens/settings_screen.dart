import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account', isDark),
          if (authProvider.isLoggedIn) ...[
            _buildAccountCard(context, authProvider, isDark),
          ] else ...[
            _buildLoginPrompt(context, isDark),
          ],
          
          const SizedBox(height: 24),
          
          // Appearance Section
          _buildSectionHeader(context, 'Appearance', isDark),
          _buildThemeSelector(context, themeProvider, isDark),
          
          const SizedBox(height: 24),
          
          // Playback Section
          _buildSectionHeader(context, 'Playback', isDark),
          _buildSettingsTile(
            context,
            icon: Icons.graphic_eq,
            title: 'Audio Quality',
            subtitle: 'High (320 kbps)',
            isDark: isDark,
            onTap: () => _showAudioQualityDialog(context, isDark),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.skip_next,
            title: 'Autoplay',
            subtitle: 'Play similar songs when music ends',
            isDark: isDark,
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: themeProvider.primaryColor,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.volume_up,
            title: 'Normalize Volume',
            subtitle: 'Set the same volume for all songs',
            isDark: isDark,
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: themeProvider.primaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data Saver Section
          _buildSectionHeader(context, 'Data Saver', isDark),
          _buildSettingsTile(
            context,
            icon: Icons.data_saver_on,
            title: 'Data Saver',
            subtitle: 'Reduce data usage while streaming',
            isDark: isDark,
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: themeProvider.primaryColor,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.download,
            title: 'Download using Wi-Fi only',
            subtitle: 'Save mobile data',
            isDark: isDark,
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: themeProvider.primaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Storage Section
          _buildSectionHeader(context, 'Storage', isDark),
          _buildSettingsTile(
            context,
            icon: Icons.storage,
            title: 'Storage',
            subtitle: '0 MB used',
            isDark: isDark,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Free up space on your device',
            isDark: isDark,
            onTap: () => _showClearCacheDialog(context, isDark),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader(context, 'About', isDark),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            isDark: isDark,
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            isDark: isDark,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            isDark: isDark,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.code,
            title: 'Open Source Licenses',
            isDark: isDark,
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          if (authProvider.isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context, authProvider, isDark),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthProvider authProvider, bool isDark) {
    final user = authProvider.currentUser;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1DB954),
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
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: () => _showEditProfileDialog(context, authProvider, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_circle,
            size: 48,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to sync your music',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save playlists, liked songs, and more',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: AppThemeMode.values.map((mode) {
          final isSelected = themeProvider.themeMode == mode;
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? themeProvider.primaryColor.withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF2a2a2a) : Colors.grey[100]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeProvider.getThemeIcon(mode),
                color: isSelected 
                    ? themeProvider.primaryColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            title: Text(
              themeProvider.getThemeName(mode),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              themeProvider.getThemeDescription(mode),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: themeProvider.primaryColor)
                : null,
            onTap: () => themeProvider.setTheme(mode),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null 
          ? Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400])
          : null),
      onTap: onTap,
    );
  }

  void _showAudioQualityDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Audio Quality',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('Low', '96 kbps'),
            ('Normal', '160 kbps'),
            ('High', '320 kbps'),
          ].map((quality) => ListTile(
            title: Text(
              quality.$1,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              quality.$2,
              style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            trailing: quality.$1 == 'High'
                ? const Icon(Icons.check, color: Color(0xFF1DB954))
                : null,
            onTap: () => Navigator.pop(context),
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        title: Text(
          'Clear Cache',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'This will remove all cached data. Are you sure?',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        title: Text(
          'Log Out',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
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

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider, bool isDark) {
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?['display_name'] ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  color: Colors.grey[600],
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
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
