# 🥞 Pancake Tunes - Music Streaming App

<p align="center">
  <img src="assets/images/logo.png" alt="Pancake Tunes Logo" width="200"/>
</p>

<p align="center">
  <strong>A beautiful, feature-rich music streaming application built with Flutter</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10.1+-blue?logo=flutter" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Dart-3.10.1+-blue?logo=dart" alt="Dart Version"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [Configuration](#-configuration)
- [API Integration](#-api-integration)
- [State Management](#-state-management)
- [Audio System](#-audio-system)
- [Theme System](#-theme-system)
- [Database Schema](#-database-schema)
- [Building for Production](#-building-for-production)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

Pancake Tunes is a modern, full-featured music streaming application that offers a Spotify-like experience. Built entirely with Flutter, it provides seamless music playback with advanced features like crossfade transitions, gapless playback, synced lyrics, and personalized recommendations based on listening history.

The app streams music from **JioSaavn API** (free, no API key required) and supports offline playback through downloads. It features a beautiful UI with 11 customizable themes including dynamic themes that adapt to album artwork.

---

## ✨ Features

### 🎵 Music Playback
| Feature | Description |
|---------|-------------|
| **High-Quality Streaming** | Stream music at up to 320kbps quality |
| **Crossfade Transitions** | Spotify-style smooth song transitions (1-12 seconds) |
| **5 Crossfade Curves** | Linear, Equal Power, Quadratic, Logarithmic, S-Curve |
| **Gapless Playback** | Zero silence between songs with intelligent pre-caching at 60% |
| **Bass Boost** | Adjustable bass enhancement (0-100%) |
| **Reverb Effect** | Room acoustics simulation (0-100%) |
| **Volume Normalization** | Consistent volume across all tracks |
| **Smart Autoplay** | Automatically plays similar songs when playlist ends |
| **Background Playback** | Continue listening with screen off |
| **Lock Screen Controls** | Full playback control from lock screen |
| **Notification Controls** | Play/pause/skip from notification panel |
| **Bluetooth Support** | Media button support for Bluetooth headphones |

### 🎨 Themes & Customization
| Theme Type | Themes Available |
|------------|------------------|
| **Light Themes** | Warm Yellow (default), Soft Pink, Mint Green, Lavender, Dynamic Light |
| **Dark Themes** | AMOLED Black, Dark Lavender, Dark Pink, Dark Yellow, Dark Mint Green, Dynamic Dark |

**Additional Customization:**
- **Font Size Options** - Small, Standard, Large
- **Grid/List Layout Toggle** - Switch between views
- **Progress Bar Styles** - Wavy, Modern, Straight
- **Dynamic Theme** - Colors extracted from current album artwork

### 🎧 Advanced Features
| Feature | Description |
|---------|-------------|
| **Queue Management** | Add, remove, reorder songs with drag-and-drop |
| **Smart Recommendations** | AI-powered suggestions based on listening history |
| **Search** | Find songs, artists, albums with taste-based sorting |
| **Playlist Creation** | Create and manage custom playlists |
| **Favorites/Liked Songs** | Save your favorite songs |
| **Recently Played** | Track your listening history |
| **Download Manager** | Download songs for offline playback |
| **Synced Lyrics** | Real-time lyrics display (via LRCLIB API) |
| **Artist Pages** | View artist discography, albums, and top songs |
| **Album Pages** | Browse full album track lists |

### ⚙️ Settings Categories

**Playback Settings:**
- Crossfade toggle & duration (1-12 seconds)
- 5 Crossfade curve options
- Volume Normalization
- Gapless Playback
- Autoplay
- Swipe Gestures (like/add to queue)
- Bass Boost (0-100%)
- Reverb (0-100%)

**Download Settings:**
- Quality Selection (96kbps, 160kbps, 320kbps)
- WiFi-Only Downloads
- Storage Management
- Download location

**Appearance Settings:**
- 11 Theme options
- Dynamic theme based on album art
- Font Size (Small/Standard/Large)
- Grid Layout toggle
- Progress Bar Style (Wavy/Modern/Straight)
- Animations toggle

**Data & Storage:**
- Cache management
- Clear cache
- Backup/Restore data
- Export/Import playlists

---

## 📱 Screenshots

| Home Screen | Player Screen | Search Screen |
|-------------|---------------|---------------|
| Personalized recommendations | Full-screen player with lyrics | Songs, Albums, Artists tabs |

| Library Screen | Settings | Themes |
|----------------|----------|--------|
| Playlists, Downloads, Liked Songs | All app settings | 11 beautiful themes |

---

## 🛠 Tech Stack

### Core Framework
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.10.1+ | Cross-platform UI framework |
| Dart | 3.10.1+ | Programming language |

### Audio & Media
| Package | Version | Purpose |
|---------|---------|---------|
| `just_audio` | 0.9.40 | Advanced audio player with crossfade |
| `audio_session` | 0.1.21 | Audio session management |
| `audio_service` | 0.18.15 | Background audio & notifications |
| `just_audio_background` | 0.0.1-beta.13 | Background playback support |

### State Management
| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | 6.1.2 | State management solution |

### UI & Animations
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_animate` | 4.5.0 | Smooth animations |
| `glass_kit` | 4.0.1 | Glassmorphism effects |
| `shimmer` | 3.0.0 | Loading animations |
| `cached_network_image` | 3.4.1 | Image caching |
| `iconsax` | 0.0.8 | Beautiful icons |
| `google_fonts` | 6.1.0 | Custom typography |

### Storage & Database
| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | 2.3.0 | Local SQLite database |
| `shared_preferences` | 2.2.2 | Settings storage |
| `path_provider` | 2.1.1 | File system paths |

### Networking
| Package | Version | Purpose |
|---------|---------|---------|
| `http` | 1.2.2 | HTTP requests |
| `connectivity_plus` | 6.0.5 | Network status detection |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `palette_generator` | 0.3.3+4 | Extract colors from album art |
| `crypto` | 3.0.3 | Password hashing |
| `permission_handler` | 11.3.1 | Runtime permissions |
| `file_picker` | 10.3.7 | File selection |
| `share_plus` | 12.0.1 | Share functionality |
| `url_launcher` | 6.2.2 | Open external links |
| `email_validator` | 2.1.17 | Form validation |

---

## 🏗 Architecture

The app follows a **Clean Architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Screens   │  │   Widgets   │  │  Providers  │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
├─────────────────────────────────────────────────────────┤
│                     SERVICE LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  API Service│  │Audio Handler│  │  Database   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
├─────────────────────────────────────────────────────────┤
│                      DATA LAYER                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Models    │  │ Local Store │  │    Cache    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### State Management Pattern

The app uses **Provider** with **ChangeNotifier** for reactive state management:

- **ThemeProvider** - Manages app theming and dynamic colors
- **MusicPlayerProvider** - Handles all audio playback state
- **AuthProvider** - User authentication and session management
- **PlaylistProvider** - Playlist CRUD operations
- **SettingsProvider** - App settings and preferences

### Performance Optimizations

1. **Position Updates Throttling** - Reduced from 60 FPS to 2 updates/second (500ms)
2. **ValueNotifier** - Used for position/duration to avoid full widget rebuilds
3. **Pre-caching** - Next song loads at 60% progress for instant playback
4. **Lazy Loading** - Images and data loaded on demand
5. **Database Indexing** - Optimized queries with proper indexing
6. **Image Caching** - Network images cached with `cached_network_image`

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point & MultiProvider setup
│
├── models/                            # Data Models
│   ├── song_model.dart               # Song data model with factory constructors
│   ├── album_model.dart              # Album data model
│   ├── artist_model.dart             # Artist data model
│   └── lyrics_model.dart             # Synced lyrics model
│
├── providers/                         # State Management
│   ├── music_player_provider.dart    # Audio player state & crossfade logic
│   ├── theme_provider.dart           # Theme management & dynamic colors
│   ├── auth_provider.dart            # User authentication
│   ├── playlist_provider.dart        # Playlist management
│   └── settings_provider.dart        # App settings
│
├── screens/                           # UI Screens
│   ├── home_screen.dart              # Home with recommendations
│   ├── search_screen.dart            # Search with tabs
│   ├── library_screen.dart           # Library (playlists, downloads, liked)
│   ├── player_screen.dart            # Full-screen player
│   ├── queue_screen.dart             # Queue management
│   ├── lyrics_screen.dart            # Synced lyrics display
│   ├── album_screen.dart             # Album details
│   ├── album_detail_screen.dart      # Album with songs
│   ├── artist_screen.dart            # Artist top songs
│   ├── artist_detail_screen.dart     # Artist with discography
│   ├── local_music_screen.dart       # Local/downloaded music
│   ├── first_time_setup_screen.dart  # Onboarding
│   ├── profile_screen.dart           # User profile
│   ├── settings_screen.dart          # Settings hub
│   ├── playback_settings_screen.dart # Playback settings
│   ├── appearance_settings_screen.dart # Theme settings
│   ├── storage_settings_screen.dart  # Storage management
│   ├── data_settings_screen.dart     # Data & backup
│   ├── about_settings_screen.dart    # About app
│   ├── see_all_recommendations_screen.dart
│   ├── see_all_albums_screen.dart
│   └── see_all_artists_screen.dart
│
├── services/                          # Business Logic
│   ├── music_api_service.dart        # JioSaavn API integration
│   ├── audio_handler_service.dart    # Background audio & notifications
│   ├── database_service.dart         # SQLite database operations
│   ├── download_service.dart         # Download management
│   ├── recommendation_service.dart   # Smart recommendations
│   ├── lyrics_service.dart           # LRCLIB lyrics fetching
│   ├── local_music_service.dart      # Local file scanning
│   ├── dynamic_theme_service.dart    # Album art color extraction
│   ├── backup_service.dart           # Data backup/restore
│   ├── network_service.dart          # Connectivity monitoring
│   └── stream_cache_manager.dart     # Audio stream caching
│
├── theme/                             # Theming
│   └── app_theme.dart                # 11 color schemes & ThemeData
│
├── widgets/                           # Reusable Components
│   ├── mini_player.dart              # Bottom mini player
│   ├── song_card.dart                # Song display card
│   ├── song_tile.dart                # Song list tile
│   ├── song_options_sheet.dart       # Song action bottom sheet
│   ├── synced_lyrics_widget.dart     # Lyrics display widget
│   ├── network_status_banner.dart    # Offline indicator
│   └── pixel_widgets.dart            # Retro-style widgets
│
├── core/                              # Core utilities
├── data/                              # Data layer
├── domain/                            # Domain layer
└── di/                                # Dependency injection
```

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

| Requirement | Version | Download |
|-------------|---------|----------|
| Flutter SDK | 3.10.1 or higher | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.10.1 or higher | Included with Flutter |
| Android Studio | Latest | [developer.android.com](https://developer.android.com/studio) |
| VS Code (optional) | Latest | [code.visualstudio.com](https://code.visualstudio.com/) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |

**For Android Development:**
- Android SDK (API 21+)
- Android Emulator or physical device (Android 5.0+)
- Java JDK 17

**For iOS Development (macOS only):**
- Xcode 14+
- CocoaPods
- iOS Simulator or physical device (iOS 12.0+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/music_app.git
   cd music_app
   ```

2. **Check Flutter installation**
   ```bash
   flutter doctor
   ```
   Ensure all checkmarks are green for your target platform.

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Generate launcher icons (optional)**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### Running the App

**Debug Mode:**
```bash
# Run on default device
flutter run

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device_id>         # Run on specific device

# Run on Android emulator
flutter run -d emulator-5554

# Run on Chrome (web)
flutter run -d chrome
```

**Release Mode (better performance):**
```bash
flutter run --release
```

**Profile Mode (for performance testing):**
```bash
flutter run --profile
```

---

## ⚙️ Configuration

### Android Configuration

The app is configured in `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.example.music_app"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.music_app"
        minSdk = 21        // Android 5.0 (Lollipop)
        targetSdk = 34     // Android 14
    }
}
```

### Required Permissions (AndroidManifest.xml)

```xml
<!-- Storage access -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Background playback -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### Environment Variables

No API keys required! The app uses free public APIs:
- **JioSaavn API** - Free music streaming (no key needed)
- **LRCLIB API** - Free synced lyrics (no key needed)

---

## 🌐 API Integration

### JioSaavn API

The app uses multiple JioSaavn API endpoints for reliability:

```dart
static const List<String> _saavnBaseUrls = [
  'https://jiosaavn-api-privatecvc2.vercel.app',
  'https://jiosaavn-api.vercel.app',
  'https://saavn-api-nu.vercel.app',
  'https://jio-saavn-api.vercel.app',
];
```

**Available Endpoints:**
| Endpoint | Description |
|----------|-------------|
| `/search/songs?query=` | Search songs |
| `/search/albums?query=` | Search albums |
| `/search/artists?query=` | Search artists |
| `/songs?ids=` | Get song by ID |
| `/albums?id=` | Get album details |
| `/artists/{id}/songs` | Get artist songs |
| `/artists/{id}/albums` | Get artist albums |

### LRCLIB API (Lyrics)

```dart
static const String _lrclibBaseUrl = 'https://lrclib.net/api';
```

**Endpoints:**
| Endpoint | Description |
|----------|-------------|
| `/get?track_name=&artist_name=` | Get synced lyrics |
| `/search?q=` | Search for lyrics |

---

## 🎨 Theme System

### Available Themes

```dart
enum AppColorScheme {
  // Light themes
  warmYellow,      // Creamy yellow (default)
  softPink,        // Soft pink
  mintGreen,       // Mint green
  lavender,        // Light purple
  dynamicLight,    // Based on album art

  // Dark themes
  amoledBlack,     // Pure black AMOLED
  darkLavender,    // Dark purple
  darkPink,        // Dark pink
  darkYellow,      // Dark amber
  darkMintGreen,   // Dark mint
  dynamicDark,     // Based on album art (dark)
}
```

### Dynamic Theme

The dynamic theme extracts colors from the current song's album artwork:

```dart
// In ThemeProvider
Future<void> updateDynamicTheme(String? albumArtUrl) async {
  final colors = await DynamicThemeService.extractColorsFromAlbumArt(
    albumArtUrl,
    isDarkMode,
  );
  // Apply extracted colors to UI
}
```

### Adding a Custom Theme

1. **Define colors in `lib/theme/app_theme.dart`:**
```dart
static const Color myThemeBg = Color(0xFFXXXXXX);
static const Color myThemeCard = Color(0xFFXXXXXX);
static const Color myThemeAccent = Color(0xFFXXXXXX);
```

2. **Add to enum:**
```dart
enum AppColorScheme {
  // ...existing themes
  myTheme,
}
```

3. **Update all getter methods** (`getBackgroundColor`, `getAccentColor`, etc.)

---

## 🗄️ Database Schema

The app uses SQLite via `sqflite` package:

### Tables

**users**
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TEXT NOT NULL,
  last_login TEXT
);
```

**playlists**
```sql
CREATE TABLE playlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  cover_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

**playlist_songs**
```sql
CREATE TABLE playlist_songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  playlist_id INTEGER NOT NULL,
  song_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  added_at TEXT NOT NULL,
  FOREIGN KEY (playlist_id) REFERENCES playlists (id)
);
```

**songs_cache**
```sql
CREATE TABLE songs_cache (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  album TEXT,
  album_art TEXT,
  stream_url TEXT,
  duration INTEGER,
  cached_at TEXT NOT NULL
);
```

**liked_songs**
```sql
CREATE TABLE liked_songs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  song_id TEXT NOT NULL,
  liked_at TEXT NOT NULL,
  UNIQUE(user_id, song_id)
);
```

**recently_played**
```sql
CREATE TABLE recently_played (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  song_id TEXT NOT NULL,
  played_at TEXT NOT NULL
);
```

---

## 🎵 Audio System

### Crossfade Implementation

The app implements Spotify-style crossfade with 5 curve options:

```dart
enum CrossfadeCurve {
  linear,      // Simple fade (can sound abrupt)
  equalPower,  // Spotify default - constant loudness
  quadratic,   // Smooth acceleration/deceleration
  logarithmic, // Natural for human hearing (dB scale)
  sCurve,      // Very smooth - slow start/end
}
```

### Pre-caching for Gapless Playback

```dart
// When song reaches 60% progress:
Future<void> _precacheNextSong() async {
  final nextSong = _getNextSongForCrossfade();
  _precachePlayer = AudioPlayer();
  await _precachePlayer.setUrl(nextSong.streamUrl);
  // Player is ready for instant playback
}
```

### Audio Handler (Background Playback)

The `AudioPlayerHandler` extends `BaseAudioHandler` for:
- Lock screen controls
- Notification controls
- Media button support (Bluetooth)
- Background playback

---

## 📦 Building for Production

### Android APK

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build release APK (split per ABI for smaller size)
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)

```bash
# Build for iOS
flutter build ios --release

# Build IPA
flutter build ipa --release
```

### Signing the Release Build

1. **Generate keystore:**
```bash
keytool -genkey -v -keystore ~/pancake-tunes-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pancaketunes
```

2. **Create `android/key.properties`:**
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=pancaketunes
storeFile=<path>/pancake-tunes-key.jks
```

3. **Update `android/app/build.gradle.kts`** with signing config.

---

## 🐛 Troubleshooting

### Common Issues

**1. "flutter pub get" fails**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**2. Android build fails**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**3. Notification not appearing (Android 13+)**
- Ensure `POST_NOTIFICATIONS` permission is granted
- Check that notification permission is requested at startup

**4. Audio stops when app is in background**
- Verify `FOREGROUND_SERVICE` permissions in AndroidManifest.xml
- Check AudioService is properly configured

**5. Songs not loading**
- Check internet connection
- The JioSaavn API endpoints may be temporarily down
- Try again after a few minutes

**6. Lyrics not showing**
- Not all songs have synced lyrics available
- LRCLIB may not have lyrics for that specific song/artist combination

### Debug Logs

Enable verbose logging:
```bash
flutter run --verbose
```

View logs in real-time:
```bash
flutter logs
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```

3. **Make your changes**

4. **Run tests**
   ```bash
   flutter test
   ```

5. **Format code**
   ```bash
   dart format .
   ```

6. **Analyze code**
   ```bash
   flutter analyze
   ```

7. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```

8. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```

9. **Open a Pull Request**

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

Built with ❤️ using Flutter

---

## 🙏 Acknowledgments

- **[just_audio](https://pub.dev/packages/just_audio)** - Excellent audio player package
- **[Flutter Team](https://flutter.dev/)** - Amazing cross-platform framework
- **[JioSaavn](https://www.jiosaavn.com/)** - Music streaming API
- **[LRCLIB](https://lrclib.net/)** - Free synced lyrics API
- **[Material Design](https://material.io/)** - Design guidelines
- **[Iconsax](https://iconsax.io/)** - Beautiful icon set

---

## 📞 Support

For support:
- Open an issue in the repository
- Email: support@pancaketunes.com

---

<p align="center">
  <strong>🎵 Happy Listening! 🎵</strong>
</p>