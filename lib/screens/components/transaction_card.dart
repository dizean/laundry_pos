import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRush = order['is_rush'] == true;

    return Card(
      elevation: isRush ? 6 : 2,
      color: isRush ? Colors.red.shade50 : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isRush ? Icons.flash_on : Icons.receipt_long,
          color: isRush ? Colors.red : Colors.grey,
        ),
        title: Text(
          "Order #${order['order_id'].toString().substring(0, 8)}",
          style: TextStyle(
            fontWeight: isRush ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          "₱${order['total_amount']} • ${order['progress']}",
        ),
        trailing: isRush
            ? const Chip(
                label: Text("RUSH"),
                backgroundColor: Colors.redAccent,
                labelStyle: TextStyle(color: Colors.white),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}