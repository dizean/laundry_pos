import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final SupabaseClient _supabase = Supabase.instance.client;

 Future<String> addCustomer({
  required String name,
  required String phone,
}) async {
  final res = await _supabase.rpc('insert_customer', params: {
    'p_name': name,
    'p_phone': phone,
  });
  // Assuming the RPC returns the inserted ID
  return res; // make sure your RPC actually returns the ID
}

  /// Update an existing customer
  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
  }) async {
    await _supabase.rpc('update_customer', params: {
      'p_id': id,
      'p_name': name,
      'p_phone': phone,
    });
  }

  /// Delete a customer
  Future<void> deleteCustomer(String id) async {
    await _supabase.rpc('delete_customer', params: {
      'p_id': id,
    });
  }

  /// Fetch all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final response = await _supabase.rpc('get_all_customers');
    return List<Map<String, dynamic>>.from(response);
  }
 Future<List<Map<String, dynamic>>> getCustomerOrders(String id) async {
  final response = await _supabase.rpc(
    'get_customer_orders',
    params: {'p_customer_id': id},
  );
  // Safely map
  if (response != null && response is List) {
    return response.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    return [];
  }
}
}
