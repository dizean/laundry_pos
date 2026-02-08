import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> addProduct({
    required String name,
    String? description,
    required double price,
  }) async {
    await _supabase.rpc('insert_product', params: {
      'p_name': name,
      'p_description': description ?? '',
      'p_price': price,
    });
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    String? description,
    required double price,
  }) async {
    await _supabase.rpc('update_product', params: {
      'p_id': id,
      'p_name': name,
      'p_description': description ?? '',
      'p_price': price,
    });
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.rpc('delete_product', params: {
      'p_id': id,
    });
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final response = await _supabase.rpc('get_all_products');
    return List<Map<String, dynamic>>.from(response);
  }
}
