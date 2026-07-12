import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isCreator => _user?.creator ?? false;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      try {
        final data = await ApiService.get('/auth/me');
        _user = UserModel.fromJson(data);
      } catch (e) {
        _token = null;
        await prefs.remove('token');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(
        '/auth/register',
        body: {'email': email, 'username': username, 'password': password},
        auth: false,
      );

      _token = data['token'];
      _user = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.post(
        '/auth/login',
        body: {'email': email, 'password': password},
        auth: false,
      );

      _token = data['token'];
      _user = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

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

  Future<void> refreshUser() async {
    try {
      final data = await ApiService.get('/auth/me');
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}