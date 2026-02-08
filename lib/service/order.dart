import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a new order with items, supports partial payment via balance
 Future<String> createOrder({
  required String customerId,
  String? staffId,
  String status = 'unpaid',
  String progress = 'pending',
  required double totalAmount,
  required double balance,
  bool isRush = false,
  DateTime? claimableDate,
  required List<Map<String, dynamic>> items,
}) async {
  // Ensure items are JSON-safe
  final safeItems = items.map((i) {
    return {
      'id': i['id'].toString(),
      'type': i['type'],
      'price': (i['price'] as num).toDouble(),
      'quantity': (i['quantity'] as int),
    };
  }).toList();

  final res = await _supabase.rpc(
    'create_order',
    params: {
      'p_customer_id': customerId,
      'p_staff_id': staffId,
      'p_status': status,
      'p_progress': progress,
      'p_total_amount': totalAmount,
      'p_balance': balance,
      'p_items': safeItems,
      'p_is_rush': isRush,
      'p_claimable_date': claimableDate?.toUtc().toIso8601String(),
    },
  );

  if (res == null) throw Exception('Order creation failed');
  return res as String;
}
  /// Update order status or progress
  Future<void> updateOrderStatus({
    required String orderId,
    String? status,
    String? progress,
  }) async {
    try {
      await _supabase.rpc(
        'update_order_status',
        params: {
          'p_order_id': orderId,
          'p_status': status,
          'p_progress': progress,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete order by ID
  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabase.rpc('delete_order', params: {'p_order_id': orderId});
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all orders
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final res = await _supabase.rpc('get_all_orders');

      if (res == null) return [];
      // print(res);
      // Convert dynamic list to List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch order details by order ID
  Future<List<Map<String, dynamic>>> getOrderDetails(String orderId) async {
    try {
      final res = await _supabase.rpc(
        'get_order_details',
        params: {'p_order_id': orderId},
      );

      if (res == null) return [];
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (e) {
      rethrow;
    }
  }
}
