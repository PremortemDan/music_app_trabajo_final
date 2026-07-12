import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ArtistProvider extends ChangeNotifier {
  List<ArtistProfileModel> _artists = [];
  ArtistProfileModel? _myProfile;
  bool _isLoading = false;
  String? _error;

  List<ArtistProfileModel> get artists => _artists;
  ArtistProfileModel? get myProfile => _myProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadArtists() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/artists', auth: false);
      final List<dynamic> artistsJson = data;
      _artists = artistsJson.map((json) => ArtistProfileModel.fromJson(json)).toList();
    } catch (e) {
      _artists = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/artists/profile/me');
      _myProfile = ArtistProfileModel.fromJson(data);
    } catch (e) {
      _myProfile = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registerAsCreator({
    required String artistName,
    String? bio,
    String? genre,
    String? website,
    String? instagram,
    String? imagePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (imagePath != null) {
        final fields = <String, String>{
          'artistName': artistName,
        };
        if (bio != null) fields['bio'] = bio;
        if (genre != null) fields['genre'] = genre;
        if (website != null) fields['website'] = website;
        if (instagram != null) fields['instagram'] = instagram;

        await ApiService.multipartPost(
          '/artists/register',
          fields: fields,
          files: [MapEntry('image', File(imagePath))],
        );
      } else {
        await ApiService.post('/artists/register', body: {
          'artistName': artistName,
          if (bio != null) 'bio': bio,
          if (genre != null) 'genre': genre,
          if (website != null) 'website': website,
          if (instagram != null) 'instagram': instagram,
        });
      }

      await loadMyProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('HttpException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}