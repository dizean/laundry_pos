import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_pos/helpers/session.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> login({
    required String email,
    required String password,
  }) async {

    // 1️⃣ ADMIN login (Supabase Auth)
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user != null) {
        userSession.email = user.email;
        userSession.role = 'admin';
        return 'admin';
      }
    } on AuthException {
      // continue to staff login
    }

    // 2️⃣ STAFF login via RPC
    final response = await _supabase.rpc(
      'staff_login',
      params: {
        'input_email': email,
        'input_password_hash': userSession.hashPassword(password),
      },
    );

    final List data = response as List;

    if (data.isEmpty) {
      throw 'Invalid email or password';
    }

    userSession.email = email;
    userSession.role = data.first['role'];

    return userSession.role!;
  }
}
