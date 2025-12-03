import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/music_player_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/settings_provider.dart';
import 'services/download_service.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/first_time_setup_screen.dart';
import 'widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL FIX: Don't await - run in background
  DownloadService().initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerProvider()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
          create: (_) => PlaylistProvider(),
          update: (_, authProvider, playlistProvider) {
            final userId =
                authProvider.isLoggedIn && authProvider.currentUser != null
                ? authProvider.currentUser!['id'] as int
                : null;
            playlistProvider?.updateUserId(userId);
            return playlistProvider ?? PlaylistProvider();
          },
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          // Sync crossfade settings with music player
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final player = Provider.of<MusicPlayerProvider>(
              context,
              listen: false,
            );
            player.setCrossfade(
              settingsProvider.crossfadeEnabled,
              settingsProvider.crossfadeDuration,
            );
            player.setVolumeNormalization(settingsProvider.volumeNormalization);
          });

          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: themeProvider.navBarColor,
            ),
          );

          return MaterialApp(
            title: 'Pancake Tunes',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            // Disable default animations for better performance
            themeAnimationDuration: Duration.zero,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // CRITICAL FIX: Show loading screen while checking auth
                if (authProvider.isLoading) {
                  return Scaffold(
                    backgroundColor: themeProvider.backgroundColor,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  );
                }

                // Show first-time setup if no user exists
                if (!authProvider.isLoggedIn) {
                  return const FirstTimeSetupScreen();
                }
                return const MainScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      // Use jumpToPage instead of animateToPage for instant navigation
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe for better performance
        children: const [HomeScreen(), SearchScreen(), LibraryScreen()],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CRITICAL FIX: Always render MiniPlayer, even if empty
          // This prevents the column from collapsing
          const MiniPlayer(),

          // CRITICAL FIX: Bottom nav is now ALWAYS visible
          Container(
            decoration: BoxDecoration(
              color: themeProvider.navBarColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'Home',
                      themeProvider,
                    ),
                    _buildNavItem(
                      1,
                      Icons.search_outlined,
                      Icons.search,
                      'Search',
                      themeProvider,
                    ),
                    _buildNavItem(
                      2,
                      Icons.library_music_outlined,
                      Icons.library_music,
                      'Library',
                      themeProvider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    ThemeProvider themeProvider,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
