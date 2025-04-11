import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BaseAuth {
  static const String baseUrl = 'http://localhost:3000';
  static String? _accessToken;
  static String? _refreshToken;
  static String? _username;
  static String? _email;
  static String? _profilePicture; // Add this field

  static String? getAccessToken() => _accessToken;
  static String? getRefreshToken() => _refreshToken;
  static String? getEmail() => _email;
  static String? getUsername() => _username;
  static String? getProfilePicture() => _profilePicture; // Add getter

  static Future<void> updateTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    if (accessToken != null) _accessToken = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;
  }

  static void updateUserDetails({
    required String username,
    required String email,
    String? profilePicture, // Add profilePicture parameter
  }) {
    _username = username;
    _email = email;
    if (profilePicture != null) _profilePicture = profilePicture;
  }

  static Future<bool> signUp(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 201) {
        _username = username;
        _email = email;
        _profilePicture = null; // No profile picture on signup
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _username = data['user']['username'];
        _email = data['user']['email'];
        _profilePicture =
            data['user'].containsKey('profilePicture')
                ? data['user']['profilePicture']
                : null; // Store profile picture
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAuthenticated() async {
    return _accessToken != null;
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    _email = null;
    _profilePicture = null;
  }

  static Future<void> redirectIfNotAuthenticated(BuildContext context) async {
    if (!await isAuthenticated()) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
        (Route<dynamic> route) => false,
      );
    }
  }
}
