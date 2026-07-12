import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';

class SongProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> _songs = [];
  List<SongModel> _mySongs = [];
  List<SongModel> _likedSongs = [];
  SongModel? _currentSong;
  bool _isLoading = false;
  bool _isPlaying = false;
  int _totalSongs = 0;

  // Estado del reproductor
  double _currentPosition = 0;
  double _totalDuration = 0;

  List<SongModel> get songs => _songs;
  List<SongModel> get mySongs => _mySongs;
  List<SongModel> get likedSongs => _likedSongs;
  SongModel? get currentSong => _currentSong;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  int get totalSongs => _totalSongs;
  double get currentPosition => _currentPosition;
  double get totalDuration => _totalDuration;
  AudioPlayer get player => _player;

  SongProvider() {
    // Usar scheduleMicrotask para evitar notifyListeners durante build
    scheduleMicrotask(() {
      _player.playerStateStream.listen((state) {
        if (state.playing != _isPlaying) {
          _isPlaying = state.playing;
          notifyListeners();
        }
        if (state.processingState == ProcessingState.completed) {
          _playNext();
        }
      });

      _player.positionStream.listen((position) {
        _currentPosition = position.inSeconds.toDouble();
        notifyListeners();
      });

      _player.durationStream.listen((duration) {
        if (duration != null && _totalDuration != duration.inSeconds.toDouble()) {
          _totalDuration = duration.inSeconds.toDouble();
          notifyListeners();
        }
      });
    });
  }

  void setPlaying(bool playing) {
    if (_currentSong == null) return;

    if (playing) {
      _player.play();
    } else {
      _player.pause();
    }
    _isPlaying = playing;
    notifyListeners();
  }

  Future<void> setCurrentSong(SongModel? song) async {
    _currentSong = song;
    _currentPosition = 0;
    _totalDuration = song?.duration ?? 0;
    notifyListeners();

    if (song != null) {
      try {
        final audioUrl = song.audioUrl;
        // Agregar token de autenticación como query parameter
        final token = await ApiService.getToken();
        final url = token != null ? '$audioUrl?token=$token' : audioUrl;

        await _player.setAudioSource(
          AudioSource.uri(Uri.parse(url)),
        );
        _player.play();
        _isPlaying = true;

        // Incrementar plays en el backend (fire and forget)
        ApiService.post('/songs/${song.id}/play', auth: false);
      } catch (e) {
        debugPrint('Error al reproducir: $e');
        _isPlaying = false;
      }
      notifyListeners();
    }
  }

  Future<void> seekTo(double seconds) async {
    await _player.seek(Duration(seconds: seconds.toInt()));
    _currentPosition = seconds;
    notifyListeners();
  }

  void _playNext() {
    if (_currentSong == null || _songs.isEmpty) return;
    final currentIndex = _songs.indexWhere((s) => s.id == _currentSong!.id);
    if (currentIndex < _songs.length - 1) {
      setCurrentSong(_songs[currentIndex + 1]);
    }
  }

  void playNext() {
    if (_currentSong == null || _songs.isEmpty) return;
    final currentIndex = _songs.indexWhere((s) => s.id == _currentSong!.id);
    if (currentIndex < _songs.length - 1) {
      setCurrentSong(_songs[currentIndex + 1]);
    }
  }

  void playPrevious() {
    if (_currentSong == null || _songs.isEmpty) return;
    final currentIndex = _songs.indexWhere((s) => s.id == _currentSong!.id);
    if (currentIndex > 0) {
      setCurrentSong(_songs[currentIndex - 1]);
    }
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
      final isLiked = _likedSongs.any((s) => s.id == songId);
      if (isLiked) {
        _likedSongs.removeWhere((s) => s.id == songId);
      } else {
        final song = _songs.firstWhere(
          (s) => s.id == songId,
          orElse: () => _currentSong!,
        );
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}