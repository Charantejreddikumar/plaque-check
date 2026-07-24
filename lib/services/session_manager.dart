import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  const SessionUser({
    required this.userId,
    required this.fullName,
    required this.email,
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
      fullName: json['name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  factory SessionUser.fromLoginJson(Map<String, dynamic> json) {
    return SessionUser(
      userId: json['user_id'] as int? ?? 0,
      fullName: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  final int userId;
  final String fullName;
  final String email;

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
    };
  }
}

class SessionManager {
  static const _sessionKey = 'current_user_session';
  static const _loginStateKey = 'is_logged_in';
  static const _userIdKey = 'user_id';
  static const _nameKey = 'name';
  static const _emailKey = 'email';

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
    );
  }

  static Future<void> saveSession(SessionUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginStateKey, true);
    await prefs.setInt(_userIdKey, user.userId);
    await prefs.setString(_nameKey, user.fullName);
    await prefs.setString(_emailKey, user.email);
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginStateKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_sessionKey);
  }
}
