class SongModel {
  final String id;
  final String ownerId;
  final String? artistId;
  final String? albumId;
  final String title;
  final double duration;
  final String? genre;
  final String filePath;
  final String? coverImage;
  final int plays;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SongOwner? owner;
  final SongArtist? artist;
  final SongAlbum? album;

  SongModel({
    required this.id,
    required this.ownerId,
    this.artistId,
    this.albumId,
    required this.title,
    required this.duration,
    this.genre,
    required this.filePath,
    this.coverImage,
    required this.plays,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
    this.artist,
    this.album,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'],
      ownerId: json['ownerId'] ?? json['owner_id'] ?? '',
      artistId: json['artistId'] ?? json['artist_id'],
      albumId: json['albumId'] ?? json['album_id'],
      title: json['title'] ?? '',
      duration: (json['duration'] ?? 0).toDouble(),
      genre: json['genre'],
      filePath: json['filePath'] ?? json['file_path'] ?? '',
      coverImage: json['coverImage'] ?? json['cover_image'],
      plays: json['plays'] ?? 0,
      isPublic: json['isPublic'] ?? json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
      owner: json['owner'] != null ? SongOwner.fromJson(json['owner']) : null,
      artist: json['artist'] != null ? SongArtist.fromJson(json['artist']) : null,
      album: json['album'] != null ? SongAlbum.fromJson(json['album']) : null,
    );
  }

  // URL para streaming (usa el ID de la canción, no el filePath)
  String get audioUrl => 'http://10.0.2.2:3000/api/stream/$id';
  String? get coverUrl => coverImage != null ? 'http://10.0.2.2:3000$coverImage' : null;

  String get formattedDuration {
    final totalSeconds = duration.toInt();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedPlays {
    if (plays >= 1000000) {
      return '${(plays / 1000000).toStringAsFixed(1)}M';
    } else if (plays >= 1000) {
      return '${(plays / 1000).toStringAsFixed(1)}K';
    }
    return plays.toString();
  }
}

class SongOwner {
  final String id;
  final String username;
  final String? avatar;

  SongOwner({required this.id, required this.username, this.avatar});

  factory SongOwner.fromJson(Map<String, dynamic> json) {
    return SongOwner(
      id: json['id'],
      username: json['username'],
      avatar: json['avatar'],
    );
  }
}

class SongArtist {
  final String id;
  final String artistName;
  final String? image;

  SongArtist({required this.id, required this.artistName, this.image});

  factory SongArtist.fromJson(Map<String, dynamic> json) {
    return SongArtist(
      id: json['id'],
      artistName: json['artistName'] ?? json['artist_name'] ?? '',
      image: json['image'],
    );
  }
}

class SongAlbum {
  final String id;
  final String title;
  final String? cover;

  SongAlbum({required this.id, required this.title, this.cover});

  factory SongAlbum.fromJson(Map<String, dynamic> json) {
    return SongAlbum(
      id: json['id'],
      title: json['title'],
      cover: json['cover'],
    );
  }
}