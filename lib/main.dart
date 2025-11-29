import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/music_player_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/playlist_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'widgets/mini_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
        ChangeNotifierProvider(create: (_) => MusicPlayerProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
          create: (_) => PlaylistProvider(),
          update: (_, authProvider, playlistProvider) {
            final userId = authProvider.isLoggedIn && authProvider.currentUser != null
                ? authProvider.currentUser!['id'] as int
                : null;
            playlistProvider?.updateUserId(userId);
            return playlistProvider ?? PlaylistProvider();
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Update system UI based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode 
                  ? Brightness.light 
                  : Brightness.dark,
              systemNavigationBarColor: themeProvider.backgroundColor,
            ),
          );
          
          return MaterialApp(
            title: 'Melodify',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            home: const MainScreen(),
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = themeProvider.primaryColor;
    
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  themeProvider.backgroundColor.withOpacity(0.9),
                  themeProvider.backgroundColor,
                ],
              ),
            ),
            child: NavigationBar(
              elevation: 0,
              height: 65,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  selectedIcon: Icon(Icons.home_rounded, color: primaryColor),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  selectedIcon: Icon(Icons.search_rounded, color: primaryColor),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  selectedIcon: Icon(Icons.library_music_rounded, color: primaryColor),
                  label: 'Library',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
