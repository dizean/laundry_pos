import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? email;
  String? role; // 'admin' or 'staff'

  bool get isLoggedIn => email != null && role != null;

  // Utility to hash passwords
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

// Singleton instance
final userSession = UserSession();
