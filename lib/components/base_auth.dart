import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BaseAuth {
  static const String baseUrl = 'http://192.168.100.39:3000';
  //static const String baseUrl = 'http://localhost:3000';
  static String? _accessToken;
  static String? _refreshToken;
  static String? _username;

  static String? getAccessToken() => _accessToken;
  static String? getRefreshToken() => _refreshToken;

  static Future<void> updateTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    if (accessToken != null) _accessToken = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;
  }

  static Future<bool> signUp(
    String username,
    String email,
    String password,

    // Add this field
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
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('SignUp Error: $e');
      return false;
    }
  }

  static String? getUsername() => _username;

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
        _username = 'Hey, ' + data['user']['username'];
        return true;
      }
      return false;
    } catch (e) {
      print('SignIn Error: $e');
      return false;
    }
  }

  static Future<bool> isAuthenticated() async {
    return _accessToken != null;
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
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
