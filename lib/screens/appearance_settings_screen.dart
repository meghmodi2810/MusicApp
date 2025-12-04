import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final textColor = themeProvider.textColor;
    final secondaryText = themeProvider.secondaryTextColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appearance',
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
          // Color Theme Section
          _buildSectionHeader('Color Theme', secondaryText),
          _buildColorSchemeSelector(context, themeProvider),

          const SizedBox(height: 24),

          // Interface Settings
          _buildSectionHeader('Interface', secondaryText),
          _buildSettingsTile(
            context,
            icon: Icons.show_chart,
            title: 'Progress Bar Style',
            subtitle: _getProgressBarStyleName(
              settingsProvider.progressBarStyle,
            ),
            themeProvider: themeProvider,
            onTap: () => _showProgressBarStyleDialog(
              context,
              themeProvider,
              settingsProvider,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.text_fields,
            title: 'Font Size',
            subtitle: _getFontSizeName(settingsProvider.fontSize),
            themeProvider: themeProvider,
            onTap: () =>
                _showFontSizeDialog(context, themeProvider, settingsProvider),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.grid_view,
            title: 'Grid Layout',
            subtitle: 'Compact view for album covers',
            themeProvider: themeProvider,
            trailing: Switch(
              value: settingsProvider.gridLayoutEnabled,
              onChanged: (value) =>
                  settingsProvider.setGridLayoutEnabled(value),
              activeColor: themeProvider.primaryColor,
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

  Widget _buildColorSchemeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final lightThemes = [
      AppColorScheme.warmYellow,
      AppColorScheme.softPink,
      AppColorScheme.mintGreen,
      AppColorScheme.lavender,
    ];

    final darkThemes = [
      AppColorScheme.amoledBlack,
      AppColorScheme.darkLavender,
      AppColorScheme.darkPink,
      AppColorScheme.darkYellow,
      AppColorScheme.darkMintGreen,
    ];

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

          Text(
            'LIGHT THEMES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeProvider.secondaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: lightThemes.map((scheme) {
              return _buildThemeOption(scheme, themeProvider);
            }).toList(),
          ),

          const SizedBox(height: 24),

          Text(
            'DARK THEMES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeProvider.secondaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: darkThemes.map((scheme) {
              return _buildThemeOption(scheme, themeProvider);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(AppColorScheme scheme, ThemeProvider themeProvider) {
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
                ? Icon(
                    Icons.check,
                    color: AppTheme.getTextColor(scheme),
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              schemeName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? themeProvider.primaryColor
                    : themeProvider.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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

  void _showFontSizeDialog(
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
            'Font Size',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('small', 'Small'),
            ('standard', 'Standard'),
            ('large', 'Large'),
          ].map(
            (size) => ListTile(
              title: Text(
                size.$2,
                style: TextStyle(color: themeProvider.textColor),
              ),
              trailing: settingsProvider.fontSize == size.$1
                  ? Icon(Icons.check, color: themeProvider.primaryColor)
                  : null,
              onTap: () {
                settingsProvider.setFontSize(size.$1);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showProgressBarStyleDialog(
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
            'Progress Bar Style',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('Straight', 'straight'),
            ('Wavy (Less)', 'wavy1'),
            ('Wavy (More)', 'wavy2'),
            ('Modern', 'modern'),
          ].map(
            (style) => ListTile(
              title: Text(
                style.$1,
                style: TextStyle(color: themeProvider.textColor),
              ),
              trailing: settingsProvider.progressBarStyle == style.$2
                  ? Icon(Icons.check, color: themeProvider.primaryColor)
                  : null,
              onTap: () {
                settingsProvider.setProgressBarStyle(style.$2);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getProgressBarStyleName(String style) {
    switch (style) {
      case 'straight':
        return 'Straight';
      case 'wavy1':
        return 'Wavy (Less)';
      case 'wavy2':
        return 'Wavy (More)';
      case 'modern':
        return 'Modern';
      default:
        return 'Wavy (More)';
    }
  }

  String _getFontSizeName(String size) {
    switch (size) {
      case 'small':
        return 'Small';
      case 'large':
        return 'Large';
      case 'standard':
      default:
        return 'Standard';
    }
  }
}
