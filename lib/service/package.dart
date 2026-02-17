import 'package:supabase_flutter/supabase_flutter.dart';

class PackageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new package
  Future<Map<String, dynamic>> addPackage({
    required String name,
    String? description,
    required double totalPrice,
  }) async {
    final response = await _supabase
        .rpc(
          'insert_package',
          params: {
            'p_name': name,
            'p_description': description ?? '',
            'p_total_price': totalPrice,
          },
        )
        .single(); // returns a single row
    return Map<String, dynamic>.from(response);
  }

  /// Update package
  Future<void> updatePackage({
    required String id,
    required String name,
    String? description,
    required double totalPrice,
  }) async {
    await _supabase.rpc(
      'update_package',
      params: {
        'p_id': id,
        'p_name': name,
        'p_description': description ?? '',
        'p_total_price': totalPrice,
      },
    );
  }

  /// Delete package
  Future<void> deletePackage(String id) async {
    await _supabase.rpc('delete_package', params: {'p_id': id});
  }

  /// Fetch all packages
Future<List<Map<String, dynamic>>> getAllPackages({
  required int limit,
  required int offset,
}) async {
  final response = await _supabase.rpc(
    'get_all_packages',
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

  /// Add service to package
  Future<void> addServiceToPackage({
    required String packageId,
    required String serviceId,
    int quantity = 1,
  }) async {
    await _supabase.rpc(
      'add_service_to_package',
      params: {
        'p_package_id': packageId,
        'p_service_id': serviceId,
        'p_quantity': quantity,
      },
    );
  }

  /// Add product to package
  Future<void> addProductToPackage({
    required String packageId,
    required String productId,
    int quantity = 1,
  }) async {
    await _supabase.rpc(
      'add_product_to_package',
      params: {
        'p_package_id': packageId,
        'p_product_id': productId,
        'p_quantity': quantity,
      },
    );
  }
}
