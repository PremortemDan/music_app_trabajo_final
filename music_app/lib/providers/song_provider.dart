import 'dart:io';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';

class SongProvider extends ChangeNotifier {
  List<SongModel> _songs = [];
  List<SongModel> _mySongs = [];
  List<SongModel> _likedSongs = [];
  SongModel? _currentSong;
  bool _isLoading = false;
  bool _isPlaying = false;
  int _totalSongs = 0;

  List<SongModel> get songs => _songs;
  List<SongModel> get mySongs => _mySongs;
  List<SongModel> get likedSongs => _likedSongs;
  SongModel? get currentSong => _currentSong;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  int get totalSongs => _totalSongs;

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setCurrentSong(SongModel? song) {
    _currentSong = song;
    notifyListeners();
  }

  Future<void> loadSongs({String? genre, String? search, String? artistId, int limit = 50, int offset = 0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String query = '?limit=$limit&offset=$offset';
      if (genre != null) query += '&genre=$genre';
      if (search != null) query += '&search=$search';
      if (artistId != null) query += '&artistId=$artistId';

      final data = await ApiService.get('/songs$query', auth: false);
      final List<dynamic> songsJson = data['songs'];
      _songs = songsJson.map((json) => SongModel.fromJson(json)).toList();
      _totalSongs = data['total'] ?? _songs.length;
    } catch (e) {
      _songs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMySongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/songs/my-songs');
      final List<dynamic> songsJson = data;
      _mySongs = songsJson.map((json) => SongModel.fromJson(json)).toList();
    } catch (e) {
      _mySongs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLikedSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/users/liked-songs');
      final List<dynamic> songsJson = data;
      _likedSongs = songsJson.map((json) => SongModel.fromJson(json)).toList();
    } catch (e) {
      _likedSongs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLike(String songId) async {
    try {
      await ApiService.post('/users/like/$songId');
      // Actualizar likedSongs
      final isLiked = _likedSongs.any((s) => s.id == songId);
      if (isLiked) {
        _likedSongs.removeWhere((s) => s.id == songId);
      } else {
        // Buscar canción en songs
        final song = _songs.firstWhere((s) => s.id == songId, orElse: () => _currentSong!);
        _likedSongs.add(song);
      }
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  bool isSongLiked(String songId) {
    return _likedSongs.any((s) => s.id == songId);
  }

  Future<bool> uploadSong({
    required String title,
    String? genre,
    String? albumId,
    bool isPublic = true,
    required String songPath,
    String? coverPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Usar multipart
      final fields = <String, String>{
        'title': title,
        'isPublic': isPublic.toString(),
      };
      if (genre != null) fields['genre'] = genre;
      if (albumId != null) fields['albumId'] = albumId;

      final files = <MapEntry<String, File>>[
        MapEntry('song', File(songPath)),
      ];
      if (coverPath != null) {
        files.add(MapEntry('cover', File(coverPath)));
      }

      await ApiService.multipartPost(
        '/songs/upload',
        fields: fields,
        files: files,
      );

      await loadMySongs();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteSong(String songId) async {
    try {
      await ApiService.delete('/songs/$songId');
      _mySongs.removeWhere((s) => s.id == songId);
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }
}