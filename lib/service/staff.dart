import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_pos/helpers/utils.dart';

class StaffService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createStaff({required String email, required String password}) async {
    final passwordHash = hashPassword(password);
    await _supabase.rpc('insert_staff', params: {
      'p_email': email,
      'p_password_hash': passwordHash,
    });
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    final response = await _supabase.rpc('get_all_staff');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteStaff(String id) async {
    await _supabase.rpc('delete_staff_record', params: {'p_id': id});
  }

  Future<void> updateStaff({
    required String id,
    required String email,
    String? password,
  }) async {
    final passwordHash = password != null ? hashPassword(password) : null;
    await _supabase.rpc('update_staff_record', params: {
      'p_id': id,
      'p_email': email,
      'p_password_hash': passwordHash,
    });
  }
}
