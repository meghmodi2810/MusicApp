import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/music_player_provider.dart';
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
    return ChangeNotifierProvider(
      create: (context) => MusicPlayerProvider(),
      child: MaterialApp(
        title: 'Melodify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0d0d0d),
          primaryColor: const Color(0xFF1DB954),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF1DB954),
            secondary: const Color(0xFF1ed760),
            surface: const Color(0xFF121212),
            background: const Color(0xFF0d0d0d),
            onBackground: Colors.white,
            onSurface: Colors.white,
            tertiary: const Color(0xFF7C4DFF),
          ),
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
            bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF0d0d0d).withOpacity(0.95),
            indicatorColor: const Color(0xFF1DB954).withOpacity(0.2),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1DB954));
              }
              return TextStyle(fontSize: 12, color: Colors.grey[500]);
            }),
          ),
        ),
        home: const MainScreen(),
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
                  const Color(0xFF0d0d0d).withOpacity(0.9),
                  const Color(0xFF0d0d0d),
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
                  icon: Icon(Icons.home_outlined, color: Colors.grey[500]),
                  selectedIcon: const Icon(Icons.home_rounded, color: Color(0xFF1DB954)),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                  selectedIcon: const Icon(Icons.search_rounded, color: Color(0xFF1DB954)),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined, color: Colors.grey[500]),
                  selectedIcon: const Icon(Icons.library_music_rounded, color: Color(0xFF1DB954)),
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
