import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/customer.dart';
import 'package:laundry_pos/screens/components/package_selector.dart';
import 'package:laundry_pos/screens/components/claimable.dart';
import 'package:laundry_pos/helpers/utils.dart';
import 'package:laundry_pos/styles.dart';
import 'package:laundry_pos/helpers/functions.dart';

class PackageOrderScreen extends StatefulWidget {
  final VoidCallback onBack;
  final CustomerService customerService;
  final PackageService packageService;
  final OrderService orderService;

  const PackageOrderScreen({
    super.key,
    required this.onBack,
    required this.customerService,
    required this.packageService,
    required this.orderService,
  });

  @override
  State<PackageOrderScreen> createState() => _PackageOrderScreenState();
}

class _PackageOrderScreenState extends State<PackageOrderScreen> {
  /// ================= STATE =================
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> selectedPackages = [];

  String? selectedCustomerId;
  bool loading = true;
  bool submitting = false;
  bool isRush = false;
  String progressStatus = 'pending';
  double cashGiven = 0;
  DateTime? claimableDate;

  static const double rushFee = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    customers = List<Map<String, dynamic>>.from(
      await widget.customerService.getAllCustomers(),
    );
    packages = List<Map<String, dynamic>>.from(
      await widget.packageService.getAllPackages(),
    );
    setState(() => loading = false);
  }

  /// ================= COMPUTED =================
  double get totalAmount => calculateTotal(selectedPackages, isRush: isRush);
  double get balance => calculateBalance(totalAmount, cashGiven);

  /// ================= ACTIONS =================
  void togglePackage(Map<String, dynamic> pkg) {
    setState(() {
      final index = selectedPackages.indexWhere((p) => p['id'] == pkg['id']);
      if (index >= 0) {
        selectedPackages.removeAt(index);
      } else {
        selectedPackages.add({
          'id': pkg['id'],
          'name': pkg['name'],
          'price': pkg['total_price'],
          'quantity': 1,
        });
      }
    });
  }

  void updateQuantity(String id, int value) {
    setState(() {
      final p = selectedPackages.firstWhere((x) => x['id'] == id);
      p['quantity'] = value < 1 ? 1 : value;
    });
  }

  Future<void> pickClaimableDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        claimableDate = DateTime(picked.year, picked.month, picked.day, 17);
      });
    }
  }

  Future<void> submitOrder() async {
    if (selectedCustomerId == null ||
        selectedPackages.isEmpty ||
        claimableDate == null ||
        submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      await widget.orderService.createOrder(
        customerId: selectedCustomerId!,
        status: balance == 0 ? 'paid' : 'unpaid',
        totalAmount: totalAmount,
        balance: balance,
        progress: progressStatus,
        isRush: isRush,
        items: selectedPackages
            .map(
              (p) => {
                'id': p['id'],
                'type': 'package',
                'price': p['price'],
                'quantity': p['quantity'],
              },
            )
            .toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );

      await Future.delayed(const Duration(seconds: 1));
      widget.onBack();
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// HEADER
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              const Text(
                'Package Order',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// CUSTOMER SECTION
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer', style: AppTextStyles.sectionTitle),
                  const Divider(thickness: 1),
                  CustomerSelector(
                    customers: customers,
                    selectedCustomerId: selectedCustomerId,
                    onCustomerSelected: (id) =>
                        setState(() => selectedCustomerId = id),
                    onAddCustomer: (data) async {
                      final newId = await widget.customerService.addCustomer(
                        name: data['name']!,
                        phone: data['phone']!,
                      );
                      setState(() => selectedCustomerId = newId);
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (selectedCustomerId != null) ...[
            const SizedBox(height: 16),

            /// OPTIONS: RUSH + CLAIMABLE DATE
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: isRush,
                    onChanged: (v) => setState(() => isRush = v ?? false),
                    title: Text('Rush Order', style: AppTextStyles.itemTitle),
                    subtitle: Text('Adds ₱50', style: AppTextStyles.labelText),
                    secondary: const Icon(
                      Icons.flash_on,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const Divider(),
                  ClaimableDateTile(
                    date: claimableDate,
                    onTap: pickClaimableDate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// PACKAGE SELECTOR
            Card(
              child: PackageSelector(
                packages: packages,
                selectedPackages: selectedPackages,
                onToggle: togglePackage,
              ),
            ),
          ],

          if (selectedPackages.isNotEmpty) ...[
            const SizedBox(height: 16),

            /// SELECTED PACKAGES
            Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Selected Packages',
                          style: AppTextStyles.sectionTitle),
                    ),
                  ),
                  const Divider(),
                  ...selectedPackages.map(
                    (p) => ListTile(
                      title: Text(p['name'], style: AppTextStyles.itemTitle),
                      subtitle:
                          Text('₱${p['price']} each', style: AppTextStyles.priceText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                updateQuantity(p['id'], p['quantity'] - 1),
                          ),
                          Text(
                            p['quantity'].toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                updateQuantity(p['id'], p['quantity'] + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// PAYMENT
            Card(
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
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Cash Given',
                        labelStyle: TextStyle(fontSize: 16),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          setState(() => cashGiven = double.tryParse(v) ?? 0),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// CONFIRM BUTTON
            ElevatedButton(
              onPressed: submitting ? null : submitOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CONFIRM & CREATE ORDER'),
            ),
          ],
        ],
      ),
    );
  }
}