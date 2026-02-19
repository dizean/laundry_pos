import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new service (Admin only)
  Future<void> addService({
    required String name,
    String? description,
    required double price,
  }) async {
    await _supabase.rpc('insert_service', params: {
      'p_name': name,
      'p_description': description ?? '',
      'p_price': price,
    });
  }

  /// Update an existing service (Admin only)
  Future<void> updateService({
    required String id,
    required String name,
    String? description,
    required double price,
  }) async {
    await _supabase.rpc('update_service', params: {
      'p_id': id,
      'p_name': name,
      'p_description': description ?? '',
      'p_price': price,
    });
  }

  /// Delete a service (Admin only)
  Future<void> deleteService(String id) async {
    await _supabase.rpc('delete_service', params: {
      'p_id': id,
    });
  }

  /// Fetch all services
  Future<List<Map<String, dynamic>>> getAllServices() async {
    final response = await _supabase.rpc('get_all_services');
    return List<Map<String, dynamic>>.from(response);
  }
  Future<List<Map<String, dynamic>>> getPaginatedServices({
  required int limit,
  required int offset,
}) async {
  final response = await _supabase.rpc(
    'get_all_products',
    params: {
      'p_limit': limit,
      'p_offset': offset,
    },
  );

  if (response == null) return [];

  return (response as List)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}
}
