import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laundry_pos/pages/order/custom.dart';
import 'package:laundry_pos/pages/order/package.dart';
import 'package:laundry_pos/screens/components/main.dart';
import 'package:laundry_pos/service/main.dart';

enum OrderView { menu, package, custom }

class OrderScreen extends StatefulWidget {
  final Function(Widget) openPage;
  final OrderView view;
  final VoidCallback onPackageTap;
  final VoidCallback onCustomTap;
  final VoidCallback onBack;

  const OrderScreen({
    super.key,
    required this.openPage,
    required this.view,
    required this.onPackageTap,
    required this.onCustomTap,
    required this.onBack,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<List<Map<String, dynamic>>> _recentOrders;

  @override
  void initState() {
    super.initState();
    _recentOrders = _loadRecentOrders();
  }

  Future<List<Map<String, dynamic>>> _loadRecentOrders() async {
    final orderService = context.read<OrderService>();
    final orders = await orderService.getAllOrders();

    // Rush first, then newest
    orders.sort((a, b) {
      final rushA = a['is_rush'] == true;
      final rushB = b['is_rush'] == true;

      if (rushA != rushB) return rushB ? 1 : -1;

      final dateA = DateTime.parse(a['date_created']);
      final dateB = DateTime.parse(b['date_created']);
      return dateB.compareTo(dateA);
    });

    return orders.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {

    switch (widget.view) {
      case OrderView.menu:
        return _OrderMenu(
          onPackageTap: widget.onPackageTap,
          onCustomTap: widget.onCustomTap,
          recentOrders: _recentOrders,
        );

      case OrderView.package:
        return PackageOrderScreen(
          onBack: widget.onBack
        );

      case OrderView.custom:
        return CustomOrderScreen(
          onBack: widget.onBack
        );
    }
  }
}

/* ===================== MENU ===================== */

class _OrderMenu extends StatelessWidget {
  final VoidCallback onPackageTap;
  final VoidCallback onCustomTap;
  final Future<List<Map<String, dynamic>>> recentOrders;

  const _OrderMenu({
    required this.onPackageTap,
    required this.onCustomTap,
    required this.recentOrders,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _OrderOptionCard(
                  icon: Icons.local_laundry_service,
                  title: "Package Order",
                  description: "Select a laundry package",
                  onTap: onPackageTap,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OrderOptionCard(
                  icon: Icons.edit_note,
                  title: "Custom Order",
                  description: "Create a custom transaction",
                  onTap: onCustomTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _RecentOrdersSection(recentOrders: recentOrders),
        ],
      ),
    );
  }
}

/* ===================== RECENT ORDERS ===================== */

class _RecentOrdersSection extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> recentOrders;

  const _RecentOrdersSection({required this.recentOrders});

  @override
  Widget build(BuildContext context) {
    final orderService = context.read<OrderService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Orders",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: recentOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text("Error loading orders"),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Text("No recent orders"),
              );
            }

            return Column(
              children: snapshot.data!.map((order) {
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
                    onTap: () => showOrderDetailsDialog(
                      context,
                      order['order_id'],
                      orderService,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/* ===================== OPTION CARD ===================== */

class _OrderOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OrderOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}