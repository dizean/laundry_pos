import 'package:flutter/material.dart';
import 'package:laundry_pos/styles.dart';
import 'package:laundry_pos/helpers/utils.dart';
class PaymentSummaryCard extends StatelessWidget {
  final double totalAmount;
  final double balance;
  final TextEditingController cashController;
  final ValueChanged<double> onCashChanged;

  const PaymentSummaryCard({
    super.key,
    required this.totalAmount,
    required this.balance,
    required this.cashController,
    required this.onCashChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Summary', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Text(
              'Total: ${formatCurrency(totalAmount)}',
              style: AppTextStyles.paymentTotal,
            ),
            const SizedBox(height: 6),
            Text(
              'Balance: ${formatCurrency(balance)}',
              style: AppTextStyles.paymentBalance,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cashController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Cash Given',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  onCashChanged(double.tryParse(v) ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}