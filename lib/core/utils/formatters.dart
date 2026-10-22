class Formatters {
  Formatters._();

  /// Mengonversi objek [Duration] ke format teks menit:detik (contoh: "03:45" atau "1:02:30")
  static String formatDuration(Duration? duration) {
    if (duration == null || duration.inSeconds < 0) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }

  /// Mengonversi detik ke format menit:detik
  static String formatSeconds(int seconds) {
    return formatDuration(Duration(seconds: seconds));
  }

  /// Membersihkan teks judul lagu dari tag video YouTube yang mengganggu pencarian audio
  static String cleanTrackTitle(String title) {
    var cleaned = title;
    // Hapus konten dalam kurung seperti (Official Video), [MV], (Audio), dll.
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\((official|video|music video|audio|remastered|lyric|lyrics|explicit|hd|4k)[^)]*\)',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\[(official|video|music video|audio|remastered|lyric|lyrics|explicit|hd|4k)[^\]]*\]',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\.+'), '');
    return cleaned.trim();
  }

  /// Menghasilkan kueri pencarian YouTube yang optimal
  static String buildYouTubeSearchQuery(String artist, String title) {
    final cleanTitle = cleanTrackTitle(title);
    return '$artist $cleanTitle Official Audio';
  }
}
