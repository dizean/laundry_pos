import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/main.dart';
import 'package:laundry_pos/helpers/utils.dart';
import 'package:laundry_pos/styles.dart';

class PackageOrderScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PackageOrderScreen({super.key, required this.onBack});

  @override
  State<PackageOrderScreen> createState() => _PackageOrderScreenState();
}

class _PackageOrderScreenState extends State<PackageOrderScreen> {
  /// ================= STATE =================
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> selectedPackages = [];
  int _currentPage = 1;
  final int _perPage = 15;
  late final TextEditingController cashController;

  String? selectedCustomerId;
  bool loading = true;
  bool submitting = false;
  bool isRush = false;
  String progressStatus = 'pending';
  double cashGiven = 0;
  DateTime? claimableDate;

  @override
  void initState() {
    super.initState();
    cashController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    cashController.dispose();
    super.dispose();
  }

  /// ================= LOAD DATA =================
  Future<void> _loadData({int page = 1}) async {
    final customerService = context.read<CustomerService>();
    final packageService = context.read<PackageService>();

    setState(() => loading = true);

    try {
      // Load only first 50 customers for selector
      final offset = (page - 1) * _perPage;

      customers = await customerService.getAllCustomers(
        limit: _perPage,
        offset: offset,
      );

      packages = await packageService.getAllPackages(
      limit: _perPage,
      offset: (_currentPage - 1) * _perPage,
    );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
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
      final orderService = context.read<OrderService>();

      await orderService.createOrder(
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
      if (mounted) {
        setState(() => submitting = false);
      }
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
          CustomerSelector(
            customers: customers,
            selectedCustomerId: selectedCustomerId,
            onCustomerSelected: (id) {
              setState(() {
                if (id == '__RESET__') {
                  selectedCustomerId = null;
                  selectedPackages.clear();
                } else {
                  selectedCustomerId = id;
                }
              });
            },
            onAddCustomer: (data) async {
              final customerService = context.read<CustomerService>();

              final newId = await customerService.addCustomer(
                name: data['name']!,
                phone: data['phone']!,
              );

              setState(() => selectedCustomerId = newId);
              await _loadData();
            },
          ),

          if (selectedCustomerId != null) ...[
            const SizedBox(height: 16),

            /// RUSH OPTION
            CheckboxListTile(
              value: isRush,
              onChanged: (v) => setState(() => isRush = v ?? false),
              title: Text('Rush Order', style: AppTextStyles.itemTitle),
              subtitle: Text('Adds ₱50', style: AppTextStyles.labelText),
            ),

            const Divider(),

            /// CLAIMABLE DATE
            ClaimableDateTile(date: claimableDate, onTap: pickClaimableDate),

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
            SelectedPackagesCard(
              selectedPackages: selectedPackages,
              onUpdateQuantity: updateQuantity,
            ),

            const SizedBox(height: 16),

            /// PAYMENT SUMMARY
            PaymentSummaryCard(
              totalAmount: totalAmount,
              balance: balance,
              cashController: cashController,
              onCashChanged: (value) {
                setState(() => cashGiven = value);
              },
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
