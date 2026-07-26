import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  const SessionUser({
    required this.userId,
    required this.fullName,
    required this.email,
    this.accessToken = '',
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      fullName: json['name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? json['accessToken'] as String? ?? '',
    );
  }

  factory SessionUser.fromLoginJson(Map<String, dynamic> json) {
    return SessionUser(
      userId: json['user_id'] as int? ?? 0,
      fullName: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
    );
  }

  final int userId;
  final String fullName;
  final String email;
  final String accessToken;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'PC';
    }
    if (parts.length == 1) {
      final end = parts.first.length < 2 ? parts.first.length : 2;
      return parts.first.substring(0, end).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'is_logged_in': true,
      'user_id': userId,
      'name': fullName,
      'email': email,
      'access_token': accessToken,
    };
  }
}

class SessionManager {
  static const _sessionKey = 'current_user_session';
  static const _loginStateKey = 'is_logged_in';
  static const _userIdKey = 'user_id';
  static const _nameKey = 'name';
  static const _emailKey = 'email';
  static const _accessTokenKey = 'access_token';

  static Future<SessionUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_loginStateKey) ?? false;
    if (!isLoggedIn) {
      return null;
    }

    final value = prefs.getString(_sessionKey);
    if (value != null) {
      try {
        return SessionUser.fromJson(jsonDecode(value) as Map<String, dynamic>);
      } catch (_) {
        await clearSession();
        return null;
      }
    }

    final email = prefs.getString(_emailKey) ?? '';
    if (email.isEmpty) {
      await clearSession();
      return null;
    }

    return SessionUser(
      userId: prefs.getInt(_userIdKey) ?? 0,
      fullName: prefs.getString(_nameKey) ?? '',
      email: email,
      accessToken: prefs.getString(_accessTokenKey) ?? '',
    );
  }

  static Future<void> saveSession(SessionUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginStateKey, true);
    await prefs.setInt(_userIdKey, user.userId);
    await prefs.setString(_nameKey, user.fullName);
    await prefs.setString(_emailKey, user.email);
    await prefs.setString(_accessTokenKey, user.accessToken);
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginStateKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_sessionKey);
  }

  static Future<String?> currentUserReportsKey() async {
    final user = await currentUser();
    if (user == null || user.userId <= 0) {
      return null;
    }
    return 'scan_reports_user_${user.userId}';
  }
}
