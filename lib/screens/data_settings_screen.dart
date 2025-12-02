import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/backup_service.dart';

class DataSettingsScreen extends StatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  State<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends State<DataSettingsScreen> {
  final _backupService = BackupService.instance;
  String _backupSize = 'Calculating...';
  Map<String, int> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final size = await _backupService.getBackupSize();
    final stats = await _backupService.getDatabaseStats();
    
    if (mounted) {
      setState(() {
        _backupSize = size;
        _stats = stats;
      });
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    
    final success = await _backupService.exportData();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Backup exported successfully!' 
            : 'Failed to export backup'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _importData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(context, listen: false).cardColor,
        title: Text(
          'Import Backup',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context, listen: false).textColor,
          ),
        ),
        content: Text(
          'This will replace all your current data with the backup file. Continue?',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context, listen: false).secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context, listen: false).secondaryTextColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Import',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context, listen: false).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    final result = await _backupService.importData();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      if (result['success']) {
        // Show restart prompt
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Provider.of<ThemeProvider>(context, listen: false).cardColor,
            title: Text(
              'Restart Required',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context, listen: false).textColor,
              ),
            ),
            content: Text(
              'Please close and restart the app to apply changes.',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context, listen: false).secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Provider.of<ThemeProvider>(context, listen: false).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: themeProvider.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(color: themeProvider.secondaryTextColor),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionHeader('Backup Information', themeProvider),
                
                _buildInfoCard(
                  context,
                  icon: Icons.storage_rounded,
                  title: 'Backup Size',
                  subtitle: _backupSize,
                  themeProvider: themeProvider,
                ),
                
                _buildInfoCard(
                  context,
                  icon: Icons.favorite,
                  title: 'Liked Songs',
                  subtitle: '${_stats['likedSongs'] ?? 0} songs',
                  themeProvider: themeProvider,
                ),
                
                _buildInfoCard(
                  context,
                  icon: Icons.playlist_play,
                  title: 'Playlists',
                  subtitle: '${_stats['playlists'] ?? 0} playlists',
                  themeProvider: themeProvider,
                ),
                
                _buildInfoCard(
                  context,
                  icon: Icons.history,
                  title: 'Listening History',
                  subtitle: '${_stats['recentlyPlayed'] ?? 0} songs',
                  themeProvider: themeProvider,
                ),
                
                _buildInfoCard(
                  context,
                  icon: Icons.cached,
                  title: 'Cached Songs',
                  subtitle: '${_stats['cachedSongs'] ?? 0} songs',
                  themeProvider: themeProvider,
                ),
                
                const SizedBox(height: 24),
                
                _buildSectionHeader('Backup & Restore', themeProvider),
                
                _buildActionTile(
                  context,
                  icon: Icons.upload_file,
                  title: 'Export Data',
                  subtitle: 'Create a backup file of all your data',
                  themeProvider: themeProvider,
                  onTap: _exportData,
                ),
                
                _buildActionTile(
                  context,
                  icon: Icons.download_rounded,
                  title: 'Import Data',
                  subtitle: 'Restore from a backup file',
                  themeProvider: themeProvider,
                  onTap: _importData,
                ),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: themeProvider.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your backup file contains all your music taste data, settings, playlists, and preferences. Keep it safe!',
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: themeProvider.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeProvider themeProvider,
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
        trailing: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
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
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.secondaryTextColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: themeProvider.secondaryTextColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
