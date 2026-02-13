import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

class UpdateOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final OrderService orderService;

  const UpdateOrderDialog({
    super.key,
    required this.order,
    required this.orderService,
  });

  @override
  State<UpdateOrderDialog> createState() => _UpdateOrderDialogState();
}

class _UpdateOrderDialogState extends State<UpdateOrderDialog> {
  late String progress;
  late double currentBalance;
  late double computedBalance;
  final TextEditingController paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    progress =
        (widget.order['progress'] ?? 'ongoing').toString().toLowerCase();

    currentBalance =
        (widget.order['balance'] is num)
            ? (widget.order['balance'] as num).toDouble()
            : double.tryParse(widget.order['balance'].toString()) ?? 0;

    computedBalance = currentBalance;
  }

  void _calculateBalance(String value) {
    final payment = double.tryParse(value) ?? 0;

    double newBalance = currentBalance - payment;

    if (newBalance < 0) newBalance = 0;

    setState(() {
      computedBalance = newBalance;
    });
  }

  Future<void> _save() async {
    await widget.orderService.updateOrder(
      orderId: widget.order['order_id'],
      progress: progress,
      balance: computedBalance,
    );

    if (!mounted) return;

    Navigator.pop(context); // close update dialog
    Navigator.pop(context); // close details dialog
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: screenWidth < 600 ? screenWidth * 0.95 : 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update Order",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              /// ================= PROGRESS =================
              const Text(
                "Progress",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              RadioListTile<String>(
                value: "ongoing",
                groupValue: progress,
                title: const Text("Ongoing"),
                onChanged: (value) {
                  setState(() => progress = value!);
                },
              ),

              RadioListTile<String>(
                value: "done",
                groupValue: progress,
                title: const Text("Completed"),
                onChanged: (value) {
                  setState(() => progress = value!);
                },
              ),

              const SizedBox(height: 24),

              /// ================= CURRENT BALANCE =================
              const Text(
                "Current Balance",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              _balanceDisplay(
                amount: currentBalance,
                isFinal: false,
              ),

              const SizedBox(height: 20),

              /// ================= PAYMENT =================
              const Text(
                "Payment Amount",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: paymentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "₱ ",
                  hintText: "Enter payment amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _calculateBalance,
              ),

              const SizedBox(height: 20),

              /// ================= NEW BALANCE =================
              const Text(
                "New Balance",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              _balanceDisplay(
                amount: computedBalance,
                isFinal: true,
              ),

              const SizedBox(height: 32),

              /// ================= ACTIONS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceDisplay({
    required double amount,
    required bool isFinal,
  }) {
    final isPaid = amount == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isFinal
            ? (isPaid ? Colors.green.shade50 : Colors.red.shade50)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFinal
              ? (isPaid ? Colors.green : Colors.red)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        "₱ ${amount.toStringAsFixed(2)}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isFinal
              ? (isPaid ? Colors.green : Colors.red)
              : Colors.black,
        ),
      ),
    );
  }
}