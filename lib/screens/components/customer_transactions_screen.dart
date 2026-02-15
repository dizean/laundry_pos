import 'package:flutter/material.dart';
import 'package:laundry_pos/service/customer.dart';

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
          await _customerService.getCustomerOrders(
        widget.customerId,
      );

      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error loading orders: $e')),
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
    final isDesktop =
        MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title:
            Text("${widget.customerName}'s Transactions"),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text(
                      "No transactions found"),
                )
              : Padding(
                  padding: EdgeInsets.all(
                      isDesktop ? 32 : 16),
                  child: ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder:
                        (context, index) {
                      final order =
                          _orders[index];

                      return Card(
                        margin:
                            const EdgeInsets
                                .only(
                                    bottom:
                                        16),
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                "Order ID: ${order['order_id']}",
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              const SizedBox(
                                  height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                        order[
                                            'status']),
                                    backgroundColor:
                                        _statusColor(
                                            order[
                                                'status']),
                                  ),
                                  const SizedBox(
                                      width:
                                          8),
                                  Chip(
                                    label: Text(
                                        order[
                                            'progress']),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height: 12),
                              Text(
                                  "Total: ₱${order['total_amount']}"),
                              Text(
                                  "Balance: ₱${order['balance']}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}