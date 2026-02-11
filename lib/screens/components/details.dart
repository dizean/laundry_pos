import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

Future<void> showOrderDetailsDialog(
  BuildContext context,
  String orderId,
  OrderService orderService,
) async {
  final orders = await orderService.getOrderDetails(orderId);

  if (orders.isEmpty) {
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

  final order = orders.first;
  final List<Map<String, dynamic>> items =
      List<Map<String, dynamic>>.from(order['items'] ?? []);

  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            /// ================= LEFT COLUMN: RECEIPT =================
            Expanded(
              flex: 3,
              child: Material(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        "Order #${order['order_id'].toString().substring(0, 8)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),

                      // Customer & Info
                      Text("Customer: ${order['customer_name']}"),
                      Text("Progress: ${order['progress']}"),
                      Text("Rush: ${order['is_rush'] == true ? 'Yes' : 'No'}"),
                      const Divider(height: 24),

                      // Items
                      const Text(
                        "Items",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final name = item['name'] ?? 'Unknown';
                            final type = (item['type'] ?? 'item').toString();
                            final qty = item['quantity'] ?? 1;
                            final price = item['price'] ?? 0;
                            final total = qty * price;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(type.capitalize(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                                Text("$qty × ₱$price = ₱$total", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            );
                          },
                        ),
                      ),
                      const Divider(height: 24),

                      // Total and Balance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("₱${order['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Balance:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "₱${order['balance']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: order['balance'] > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 24),

            /// ================= RIGHT COLUMN: ACTION BUTTONS =================
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Static for now
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Update"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Static for now
                    },
                    icon: const Icon(Icons.print),
                    label: const Text("Print"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Capitalize first letter
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}