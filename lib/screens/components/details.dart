import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

Future<void> showOrderDetailsDialog(
  BuildContext context,
  String orderId,
  OrderService orderService,
) async {
  // Load order detailsr
  final orders = await orderService.getOrderDetails(orderId);
  print(orders);
  if (orders.isEmpty) {
    // Show empty state
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Order Details"),
        content: const Text("No details found for this order."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // Group items by order (all rows share same order info)
  final order = orders.first;
  final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
    order['items'] ?? [],
  );

  // Show dialog
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order['order_id'].toString().substring(0, 8)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Order info
            Text("Customer: ${order['customer_name']}"),
            const SizedBox(height: 4),
            Text("Progress: ${order['progress']}"),
            const SizedBox(height: 4),
            Text("Rush: ${order['is_rush'] == true ? 'Yes' : 'No'}"),
            const SizedBox(height: 8),
            Text(
              "Total Amount: ₱${order['total_amount']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Balance: ₱${order['balance']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Items List
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  final name = item['name']?.toString() ?? 'Unknown';
                  final type = item['type']?.toString() ?? 'item';
                  final qty = item['quantity'] ?? 0;
                  final price = item['price'] ?? 0;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    subtitle: Text("${type.capitalize()} x$qty"),
                    trailing: Text("₱$price"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extension to capitalize first letter
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
