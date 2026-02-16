import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'details.dart'; 

class CustomerTransactionsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerTransactionsScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerTransactionsScreen> createState() =>
      _CustomerTransactionsScreenState();
}

class _CustomerTransactionsScreenState
    extends State<CustomerTransactionsScreen> {
  final CustomerService _customerService = CustomerService();
  final OrderService _orderService = OrderService(); // 👈 Added

  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data =
          await _customerService.getCustomerOrders(widget.customerId);

      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 600 && screenWidth <= 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.customerName}'s Transactions"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text("No transactions found"))
              : Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: isDesktop || isTablet
                      ? GridView.builder(
                          itemCount: _orders.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.4,
                          ),
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_orders[index]);
                          },
                        )
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_orders[index]);
                          },
                        ),
                ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// CLICKABLE ORDER CARD
  ////////////////////////////////////////////////////////////

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showOrderDetailsDialog(
          context,
          order['order_id'],
          _orderService,
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order ID: ${order['order_id']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(order['status']),
                    backgroundColor: _statusColor(order['status']),
                  ),
                  Chip(label: Text(order['progress'])),
                ],
              ),

              const Spacer(),
              const Divider(),

              Text(
                "Total: ₱${order['total_amount']}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              Text(
                "Balance: ₱${order['balance']}",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: (order['balance'] ?? 0) > 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}