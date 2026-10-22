import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String title;
  final String description;
  final String? coverUrl;
  final List<SongModel> songs;
  final DateTime createdAt;

  const PlaylistModel({
    required this.id,
    required this.title,
    this.description = '',
    this.coverUrl,
    this.songs = const [],
    required this.createdAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final rawSongs = json['songs'] as List<dynamic>? ?? [];
    return PlaylistModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Playlist',
      description: json['description']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString(),
      songs: rawSongs
          .map((s) => SongModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'songs': songs.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<SongModel>? songs,
    DateTime? createdAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
