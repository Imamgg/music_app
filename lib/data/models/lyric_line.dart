class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  /// Mengonversi teks format .LRC (Time-synced lyrics) menjadi daftar [LyricLine]
  static List<LyricLine> parseLrc(String lrcContent) {
    if (lrcContent.trim().isEmpty) return [];

    final lines = lrcContent.split('\n');
    final result = <LyricLine>[];

    // Regex untuk format: [01:23.45] atau [01:23.456] atau [01:23]
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');

    for (final rawLine in lines) {
      final match = regex.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final millisGroup = match.group(3);

        int milliseconds = 0;
        if (millisGroup != null) {
          if (millisGroup.length == 2) {
            milliseconds = (int.tryParse(millisGroup) ?? 0) * 10;
          } else {
            milliseconds = int.tryParse(millisGroup) ?? 0;
          }
        }

        final text = (match.group(4) ?? '').trim();
        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        if (text.isNotEmpty) {
          result.add(LyricLine(timestamp: timestamp, text: text));
        }
      }
    }

    // Urutkan berdasarkan timestamp
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  /// Menemukan indeks lirik yang sedang aktif pada durasi saat ini
  static int findActiveIndex(List<LyricLine> lyrics, Duration position) {
    if (lyrics.isEmpty) return -1;
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (position >= lyrics[i].timestamp) {
        return i;
      }
    }
    return 0;
  }
}
