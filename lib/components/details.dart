import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'order_update.dart';

class OrderDetailsDialog extends StatefulWidget {
  final String orderId;
  final OrderService orderService;

  const OrderDetailsDialog({
    super.key,
    required this.orderId,
    required this.orderService,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  Map<String, dynamic>? order;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orders =
        await widget.orderService.getOrderDetails(widget.orderId);

    if (mounted) {
      setState(() {
        if (orders.isNotEmpty) {
          order = orders.first;
        }
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: screenWidth < 800 ? screenWidth * 0.95 : screenWidth * 0.7,
        height: screenHeight < 700 ? screenHeight * 0.9 : screenHeight * 0.75,
        padding: const EdgeInsets.all(24),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : order == null
                ? const Center(
                    child: Text("No details found for this order."),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen =
                          constraints.maxWidth < 700;

                      final items =
                          List<Map<String, dynamic>>.from(
                        order!['items'] ?? [],
                      );

                      return isSmallScreen
                          ? Column(
                              children: [
                                Expanded(
                                  child: _ReceiptSection(
                                    order: order!,
                                    items: items,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _ActionButtons(
                                  order: order!,
                                  orderService:
                                      widget.orderService,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _ReceiptSection(
                                    order: order!,
                                    items: items,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: _ActionButtons(
                                    order: order!,
                                    orderService:
                                        widget.orderService,
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// ================= RECEIPT SECTION =================
////////////////////////////////////////////////////////////

class _ReceiptSection extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;

  const _ReceiptSection({
    required this.order,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = _parseToNum(order['total_amount']);
    final balance = _parseToNum(order['balance']);

    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${order['order_id'].toString().substring(0, 8)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),

            Text("Customers: ${order['customer_name'] ?? ''}"),
            Text("Progress: ${order['progress'] ?? ''}"),
            Text("Rush: ${order['is_rush'] == true ? 'Yes' : 'No'}"),

            const Divider(height: 24),

            const Text(
              "Items",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];

                  final name = item['name'] ?? 'Unknown';
                  final type =
                      (item['type'] ?? 'item').toString();
                  final qty = _parseToNum(item['quantity']);
                  final price = _parseToNum(item['price']);
                  final total = qty * price;

                  // final packageItems =
                  //     List<dynamic>.from(item['package_items'] ?? []);

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  type.capitalize(),
                                  style: TextStyle(
                                    color: Colors
                                        .grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "$qty × ₱$price = ₱$total",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                Text("₱$totalAmount",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("Balance:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                Text(
                  "₱$balance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// ================= ACTION BUTTONS =================
////////////////////////////////////////////////////////////

class _ActionButtons extends StatelessWidget {
  final Map<String, dynamic> order;
  final OrderService orderService;

  const _ActionButtons({
    required this.order,
    required this.orderService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (_) => UpdateOrderDialog(
                order: order,
                orderService: orderService,
              ),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text("Update"),
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.print),
          label: const Text("Print"),
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, 48),
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// ================= HELPERS =================
////////////////////////////////////////////////////////////

num _parseToNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}