import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cambia esta URL según tu entorno
  static const String baseUrl = 'http://127.0.0.1:3000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // GET
  static Future<dynamic> get(String endpoint, {bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // POST
  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // PUT
  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // DELETE
  static Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    final headers = await _getHeaders(auth: auth);
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Multipart upload
  static Future<dynamic> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    required List<MapEntry<String, File>> files,
    bool auth = true,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    
    if (auth && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    for (final fileEntry in files) {
      request.files.add(
        await http.MultipartFile.fromPath(fileEntry.key, fileEntry.value.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw HttpException(body['error'] ?? 'Error desconocido');
    }
  }
}