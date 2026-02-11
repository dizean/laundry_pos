import 'package:flutter/material.dart';
import 'transaction_card.dart';

class TransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final void Function(Map<String, dynamic>) onTap;

  const TransactionsList({
    super.key,
    required this.orders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        return TransactionCard(
          order: order,
          onTap: () => onTap(order),
        );
      },
    );
  }
}