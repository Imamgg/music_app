class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final String highResCoverUrl;
  final int durationSeconds;
  final String? youtubeVideoId;
  final String? streamUrl;
  final bool isLiked;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.highResCoverUrl,
    required this.durationSeconds,
    this.youtubeVideoId,
    this.streamUrl,
    this.isLiked = false,
  });

  /// Factory untuk mem-parsing data dari Deezer API
  factory SongModel.fromDeezerJson(Map<String, dynamic> json) {
    final artistObj = json['artist'] as Map<String, dynamic>? ?? {};
    final albumObj = json['album'] as Map<String, dynamic>? ?? {};

    final coverSmall = albumObj['cover_medium'] ??
        albumObj['cover'] ??
        artistObj['picture_medium'] ??
        '';
    final coverBig = albumObj['cover_xl'] ??
        albumObj['cover_big'] ??
        artistObj['picture_xl'] ??
        coverSmall;

    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      artist: artistObj['name']?.toString() ?? 'Unknown Artist',
      album: albumObj['title']?.toString() ?? '',
      coverUrl: coverSmall.toString(),
      highResCoverUrl: coverBig.toString(),
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }

  /// Factory untuk JSON serialisasi lokal / Supabase
  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      album: json['album']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString() ?? '',
      highResCoverUrl: json['high_res_cover_url']?.toString() ??
          json['cover_url']?.toString() ??
          '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      youtubeVideoId: json['youtube_video_id']?.toString(),
      streamUrl: json['stream_url']?.toString(),
      isLiked: json['is_liked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'cover_url': coverUrl,
      'high_res_cover_url': highResCoverUrl,
      'duration_seconds': durationSeconds,
      'youtube_video_id': youtubeVideoId,
      'is_liked': isLiked,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    String? highResCoverUrl,
    int? durationSeconds,
    String? youtubeVideoId,
    String? streamUrl,
    bool? isLiked,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      highResCoverUrl: highResCoverUrl ?? this.highResCoverUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      streamUrl: streamUrl ?? this.streamUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
