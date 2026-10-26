import 'package:xml/xml.dart';

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({required this.timestamp, required this.text});

  /// Preserve text nodes between spans: a span can contain just one syllable.
  static List<LyricLine> parseTtml(String content) {
    if (content.trim().isEmpty || content.length > 2000000) return [];
    Duration? time(String? input) {
      if (input == null) return null;
      final value = input.trim();
      double? seconds;
      if (value.endsWith('ms')) {
        final ms = double.tryParse(value.substring(0, value.length - 2));
        seconds = ms == null ? null : ms / 1000;
      } else if (value.endsWith('s')) {
        seconds = double.tryParse(value.substring(0, value.length - 1));
      } else {
        final parts = value.split(':');
        if (parts.length > 3) return null;
        var total = 0.0;
        for (final part in parts) {
          final number = double.tryParse(part);
          if (number == null) return null;
          total = total * 60 + number;
        }
        seconds = total;
      }
      if (seconds == null || !seconds.isFinite || seconds < 0) return null;
      return Duration(milliseconds: (seconds * 1000).round());
    }

    try {
      final document = XmlDocument.parse(content);
      final lines = <LyricLine>[];
      for (final body in document.descendants.whereType<XmlElement>().where(
        (element) => element.name.local == 'body',
      )) {
        for (final paragraph in body.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 'p',
        )) {
          var start = time(paragraph.getAttribute('begin'));
          start ??= paragraph.descendants
              .whereType<XmlElement>()
              .map((element) => time(element.getAttribute('begin')))
              .whereType<Duration>()
              .fold<Duration?>(null, (a, b) => a == null || b < a ? b : a);
          final text = paragraph.innerText
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (start != null && text.isNotEmpty) {
            lines.add(LyricLine(timestamp: start, text: text));
          }
        }
      }
      lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return lines;
    } catch (_) {
      return [];
    }
  }

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
          if (millisGroup.length == 1) {
            milliseconds = (int.tryParse(millisGroup) ?? 0) * 100;
          } else if (millisGroup.length == 2) {
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
    return -1;
  }
}
