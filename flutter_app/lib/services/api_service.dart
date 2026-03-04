import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dating_app/config/app_config.dart';
import 'package:dating_app/services/storage_service.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/models/profile.dart';
import 'package:dating_app/models/match.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final StorageService _storage;
  final http.Client _client;
  final String baseUrl;

  ApiService({
    required StorageService storage,
    http.Client? client,
    String? baseUrl,
  })  : _storage = storage,
        _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _storage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['message'] as String? ?? 'Unknown error';
    throw ApiException(response.statusCode, message);
  }

  // ─── Auth ───────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    return _handleResponse(response);
  }

  // ─── Profile ────────────────────────────────────────────

  Future<Profile> getProfile(String userId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    return Profile.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
      body: jsonEncode(profile.toJson()),
    );
    final data = await _handleResponse(response);
    return Profile.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─── Swipe / Cards ─────────────────────────────────────

  Future<List<Profile>> getCards({int page = 1, int size = 10}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/cards?page=$page&size=$size'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'] as List<dynamic>;
    return list
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> swipe({
    required String targetUserId,
    required String action, // "like" or "pass"
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/swipe'),
      headers: _headers,
      body: jsonEncode({
        'target_user_id': targetUserId,
        'action': action,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Matches ────────────────────────────────────────────

  Future<List<Match>> getMatches({int page = 1, int size = 20}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/matches?page=$page&size=$size'),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'] as List<dynamic>;
    return list
        .map((item) => Match.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ─── Photos ─────────────────────────────────────────────

  Future<String> uploadPhoto(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/photo'),
    );
    final token = _storage.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('photo', file.path),
    );
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final data = await _handleResponse(response);
    return data['url'] as String;
  }

  // ─── Discover ───────────────────────────────────────────

  Future<List<Profile>> discoverNearby({
    double? lat,
    double? lng,
    int radius = 50,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'radius': '$radius',
    };
    if (lat != null) queryParams['lat'] = '$lat';
    if (lng != null) queryParams['lng'] = '$lng';

    final uri = Uri.parse('$baseUrl/discover')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers);
    final data = await _handleResponse(response);
    final list = data['data'] as List<dynamic>;
    return list
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
