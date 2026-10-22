import 'package:auno/core/utils/formatters.dart';
import 'package:auno/data/models/lyric_line.dart';
import 'package:auno/data/models/playlist_model.dart';
import 'package:auno/data/models/song_model.dart';
import 'package:auno/presentation/providers/settings_provider.dart';
import 'package:auno/presentation/providers/sleep_timer_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters Tests', () {
    test('formatDuration formats mm:ss correctly', () {
      expect(Formatters.formatDuration(const Duration(seconds: 75)), '01:15');
      expect(Formatters.formatDuration(const Duration(seconds: 0)), '00:00');
      expect(Formatters.formatDuration(null), '00:00');
      expect(
        Formatters.formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
    });

    test('cleanTrackTitle removes unwanted brackets and tags', () {
      expect(
        Formatters.cleanTrackTitle('Shape of You (Official Music Video)'),
        'Shape of You',
      );
      expect(
        Formatters.cleanTrackTitle('Blinding Lights [Official Audio]'),
        'Blinding Lights',
      );
      expect(
        Formatters.cleanTrackTitle('Song Title (Remastered 2024)'),
        'Song Title',
      );
    });

    test('buildYouTubeSearchQuery builds clean search query', () {
      final query = Formatters.buildYouTubeSearchQuery(
        'Ed Sheeran',
        'Bad Habits (Official Video)',
      );
      expect(query, 'Ed Sheeran Bad Habits Official Audio');
    });
  });

  group('LyricLine Tests', () {
    test('parseLrc parses standard LRC format properly', () {
      const lrc = '''
[00:05.10]First line of lyrics
[00:12.50]Second line of lyrics
[00:20.00]Third line of lyrics
''';
      final parsed = LyricLine.parseLrc(lrc);
      expect(parsed.length, 3);
      expect(parsed[0].text, 'First line of lyrics');
      expect(
        parsed[0].timestamp,
        const Duration(seconds: 5, milliseconds: 100),
      );
      expect(
        parsed[1].timestamp,
        const Duration(seconds: 12, milliseconds: 500),
      );
      expect(parsed[2].timestamp, const Duration(seconds: 20));
    });

    test(
      'findActiveIndex finds the correct active line according to duration',
      () {
        const lrc = '''
[00:05.00]Line 1
[00:10.00]Line 2
[00:15.00]Line 3
''';
        final lyrics = LyricLine.parseLrc(lrc);
        expect(
          LyricLine.findActiveIndex(lyrics, const Duration(seconds: 2)),
          -1,
        );
        expect(
          LyricLine.findActiveIndex(lyrics, const Duration(seconds: 7)),
          0,
        );
        expect(
          LyricLine.findActiveIndex(lyrics, const Duration(seconds: 10)),
          1,
        );
        expect(
          LyricLine.findActiveIndex(lyrics, const Duration(seconds: 12)),
          1,
        );
        expect(
          LyricLine.findActiveIndex(lyrics, const Duration(seconds: 25)),
          2,
        );
      },
    );
  });

  group('SongModel & PlaylistModel Tests', () {
    test('SongModel fromDeezerJson parses valid Deezer API JSON', () {
      final json = {
        'id': 12345,
        'title': 'Starboy',
        'duration': 230,
        'artist': {
          'name': 'The Weeknd',
          'picture_medium': 'https://example.com/artist.jpg',
        },
        'album': {
          'title': 'Starboy Album',
          'cover_medium': 'https://example.com/cover.jpg',
          'cover_xl': 'https://example.com/cover_xl.jpg',
        },
      };

      final song = SongModel.fromDeezerJson(json);
      expect(song.id, '12345');
      expect(song.title, 'Starboy');
      expect(song.artist, 'The Weeknd');
      expect(song.album, 'Starboy Album');
      expect(song.durationSeconds, 230);
      expect(song.coverUrl, 'https://example.com/cover.jpg');
      expect(song.highResCoverUrl, 'https://example.com/cover_xl.jpg');
    });

    test('SongModel serializes and deserializes to JSON correctly', () {
      const song = SongModel(
        id: '99',
        title: 'Espresso',
        artist: 'Sabrina Carpenter',
        album: 'Short n Sweet',
        coverUrl: 'https://example.com/espresso.jpg',
        highResCoverUrl: 'https://example.com/espresso_hd.jpg',
        durationSeconds: 175,
        isLiked: true,
      );

      final json = song.toJson();
      final revived = SongModel.fromJson(json);

      expect(revived.id, song.id);
      expect(revived.title, song.title);
      expect(revived.artist, song.artist);
      expect(revived.durationSeconds, song.durationSeconds);
      expect(revived.isLiked, true);
    });

    test('PlaylistModel serializes to JSON correctly', () {
      final playlist = PlaylistModel(
        id: 'p1',
        title: 'My Chill Mix',
        description: 'Vibes',
        createdAt: DateTime(2026, 1, 1),
        songs: const [
          SongModel(
            id: '1',
            title: 'Song 1',
            artist: 'Artist 1',
            album: 'Album 1',
            coverUrl: '',
            highResCoverUrl: '',
            durationSeconds: 180,
          ),
        ],
      );

      final json = playlist.toJson();
      final revived = PlaylistModel.fromJson(json);
      expect(revived.id, 'p1');
      expect(revived.title, 'My Chill Mix');
      expect(revived.songs.length, 1);
    });
  });

  group('Settings & Sleep Timer Tests', () {
    test('AudioQuality handles keys and default fallback', () {
      expect(AudioQuality.fromString('high'), AudioQuality.high);
      expect(AudioQuality.fromString('low'), AudioQuality.low);
      expect(AudioQuality.fromString('normal'), AudioQuality.normal);
      expect(AudioQuality.fromString('invalid'), AudioQuality.normal);
      expect(AudioQuality.high.key, 'high');
      expect(AudioQuality.normal.key, 'normal');
      expect(AudioQuality.low.key, 'low');
    });

    test('LyricsFontSize maps sizes accurately', () {
      expect(LyricsFontSize.fromString('small'), LyricsFontSize.small);
      expect(LyricsFontSize.fromString('large'), LyricsFontSize.large);
      expect(LyricsFontSize.fromString('medium'), LyricsFontSize.medium);
      expect(LyricsFontSize.fromString('unknown'), LyricsFontSize.medium);
      expect(LyricsFontSize.small.baseSize, 15.0);
      expect(LyricsFontSize.medium.baseSize, 18.0);
      expect(LyricsFontSize.large.baseSize, 22.0);
    });

    test('SleepTimerState formattedRemaining displays minutes and seconds', () {
      const stateOff = SleepTimerState();
      expect(stateOff.isActive, false);
      expect(stateOff.formattedRemaining, 'Nonaktif');

      const stateDuration = SleepTimerState(
        mode: SleepTimerMode.duration,
        remainingSeconds: 905, // 15m 5s
        totalSeconds: 905,
      );
      expect(stateDuration.isActive, true);
      expect(stateDuration.formattedRemaining, '15:05');

      const stateEndOfTrack = SleepTimerState(mode: SleepTimerMode.endOfTrack);
      expect(stateEndOfTrack.isActive, true);
      expect(stateEndOfTrack.formattedRemaining, 'Di akhir lagu ini');
    });

    test('ContentLanguage fromCode maps properly with fallback to system', () {
      expect(ContentLanguage.fromCode('id'), ContentLanguage.indonesian);
      expect(ContentLanguage.fromCode('en'), ContentLanguage.english);
      expect(ContentLanguage.fromCode('ja'), ContentLanguage.japanese);
      expect(ContentLanguage.fromCode('ko'), ContentLanguage.korean);
      expect(ContentLanguage.fromCode('system'), ContentLanguage.system);
      expect(ContentLanguage.fromCode('nonexistent'), ContentLanguage.system);
    });
  });
}
