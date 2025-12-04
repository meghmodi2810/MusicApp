/// Model class for synced lyrics (LRC format)
class LyricsModel {
  final String songId;
  final String songTitle;
  final String artist;
  final List<LyricLine> lines;
  final bool isSynced;
  final String? plainLyrics; // Fallback plain text lyrics

  LyricsModel({
    required this.songId,
    required this.songTitle,
    required this.artist,
    required this.lines,
    this.isSynced = true,
    this.plainLyrics,
  });

  /// Parse LRC format lyrics string
  /// LRC format: [mm:ss.xx]lyrics text
  factory LyricsModel.fromLrc(String lrcContent, {
    required String songId,
    required String songTitle,
    required String artist,
  }) {
    final lines = <LyricLine>[];
    final lrcLines = lrcContent.split('\n');
    
    // RegExp to match LRC timestamp format [mm:ss.xx] or [mm:ss:xx]
    final timeRegex = RegExp(r'\[(\d{2}):(\d{2})[\.:]+(\d{2,3})\]');
    
    for (final line in lrcLines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Skip metadata lines like [ar:Artist], [ti:Title], etc.
      if (trimmedLine.startsWith('[') && !timeRegex.hasMatch(trimmedLine)) {
        continue;
      }
      
      // Find all timestamps in the line (some LRC files have multiple)
      final matches = timeRegex.allMatches(trimmedLine);
      if (matches.isEmpty) continue;
      
      // Get the lyrics text (everything after the last timestamp)
      String lyricsText = trimmedLine.replaceAll(timeRegex, '').trim();
      if (lyricsText.isEmpty) continue;
      
      // Create a LyricLine for each timestamp
      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3)!;
        // Handle both 2-digit (centiseconds) and 3-digit (milliseconds)
        final millis = millisStr.length == 2 
            ? int.parse(millisStr) * 10 
            : int.parse(millisStr);
        
        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
        
        lines.add(LyricLine(
          timestamp: timestamp,
          text: lyricsText,
        ));
      }
    }
    
    // Sort lines by timestamp
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return LyricsModel(
      songId: songId,
      songTitle: songTitle,
      artist: artist,
      lines: lines,
      isSynced: lines.isNotEmpty,
      plainLyrics: lines.isEmpty ? lrcContent : null,
    );
  }

  /// Create from plain text lyrics (no sync)
  factory LyricsModel.fromPlainText(String plainLyrics, {
    required String songId,
    required String songTitle,
    required String artist,
  }) {
    final lines = plainLyrics
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => LyricLine(
              timestamp: Duration.zero,
              text: line.trim(),
            ))
        .toList();

    return LyricsModel(
      songId: songId,
      songTitle: songTitle,
      artist: artist,
      lines: lines,
      isSynced: false,
      plainLyrics: plainLyrics,
    );
  }

  /// Get the current lyric line index based on position
  int getCurrentLineIndex(Duration position) {
    if (lines.isEmpty) return -1;
    
    for (int i = lines.length - 1; i >= 0; i--) {
      if (position >= lines[i].timestamp) {
        return i;
      }
    }
    return 0;
  }

  /// Get the current lyric line based on position
  LyricLine? getCurrentLine(Duration position) {
    final index = getCurrentLineIndex(position);
    if (index >= 0 && index < lines.length) {
      return lines[index];
    }
    return null;
  }

  bool get hasLyrics => lines.isNotEmpty || (plainLyrics?.isNotEmpty ?? false);
}

/// Single line of lyrics with timestamp
class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() => '[${_formatDuration(timestamp)}] $text';

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }
}
