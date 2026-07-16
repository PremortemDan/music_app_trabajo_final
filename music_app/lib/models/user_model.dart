class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatar;
  final String? country;
  final bool creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ArtistProfileModel? artistProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatar,
    this.country,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    this.artistProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatar: json['avatar'],
      country: json['country'],
      creator: json['creator'] ?? false,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'])
          : DateTime.now(),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : DateTime.now(),
      artistProfile: json['artistProfile'] != null
          ? ArtistProfileModel.fromJson(json['artistProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar': avatar,
      'country': country,
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ArtistProfileModel {
  final String id;
  final String userId;
  final String artistName;
  final String? bio;
  final String? genre;
  final String? image;
  final String? website;
  final String? instagram;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.artistName,
    this.bio,
    this.genre,
    this.image,
    this.website,
    this.instagram,
    required this.verified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtistProfileModel.fromJson(Map<String, dynamic> json) {
    return ArtistProfileModel(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'] ?? '',
      artistName: json['artistName'] ?? json['artist_name'] ?? '',
      bio: json['bio'],
      genre: json['genre'],
      image: json['image'],
      website: json['website'],
      instagram: json['instagram'],
      verified: json['verified'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'artistName': artistName,
      'bio': bio,
      'genre': genre,
      'website': website,
      'instagram': instagram,
    };
  }
}