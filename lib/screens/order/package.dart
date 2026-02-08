import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

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
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> packages = [];
  bool submitting = false;

  String? selectedCustomerId;

  /// id, name, price, quantity (manual)
  List<Map<String, dynamic>> selectedPackages = [];

  bool isRush = false;
  String progressStatus = 'pending';
  double cashGiven = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      customers = List<Map<String, dynamic>>.from(
        await widget.customerService.getAllCustomers(),
      );
      packages = List<Map<String, dynamic>>.from(
        await widget.packageService.getAllPackages(),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  double get totalAmount {
    return selectedPackages.fold(
      0,
      (sum, p) => sum + (p['price'] as num).toDouble() * (p['quantity'] as int),
    );
  }

  double get balance {
    final b = totalAmount - cashGiven;
    return b < 0 ? 0 : b;
  }

  double get change {
    final c = cashGiven - totalAmount;
    return c < 0 ? 0 : c;
  }

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
          'quantity': 1, // default
        });
      }
    });
  }

  void updateQuantity(String id, String value) {
    final q = int.tryParse(value) ?? 1;
    setState(() {
      final pkg = selectedPackages.firstWhere((p) => p['id'] == id);
      pkg['quantity'] = q < 1 ? 1 : q;
    });
  }

  Future<void> submitOrder() async {
  if (selectedCustomerId == null || selectedPackages.isEmpty) return;

  final items = selectedPackages.map((p) {
    return {
      'id': p['id'],
      'type': 'package',
      'price': p['price'],
      'quantity': p['quantity'],
    };
  }).toList();

  try {
    await widget.orderService.createOrder(
      customerId: selectedCustomerId!,
      status: balance == 0 ? 'paid' : 'unpaid',
      totalAmount: totalAmount,
      balance: balance,
      progress: progressStatus,
      isRush: isRush,
      items: items,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order created successfully')),
    );

    /// ✅ WAIT 2 SECONDS AFTER SUCCESS
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    widget.onBack();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // HEADER
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const Text(
                'Create Order',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CUSTOMER
          if (selectedCustomerId == null) ...[
            const Text(
              'Select Customer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...customers.map(
              (c) => ListTile(
                title: Text(c['name']),
                subtitle: Text(c['phone']),
                onTap: () =>
                    setState(() => selectedCustomerId = c['id'].toString()),
              ),
            ),
          ],

          // PACKAGES
          if (selectedCustomerId != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Select Packages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: packages.map((p) {
                final selected = selectedPackages.any(
                  (x) => x['id'] == p['id'],
                );
                return ChoiceChip(
                  label: Text('${p['name']} (₱${p['total_price']})'),
                  selected: selected,
                  onSelected: (_) => togglePackage(p),
                );
              }).toList(),
            ),
          ],

          // MANUAL QUANTITY + PAYMENT
          if (selectedPackages.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Packages & Quantity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ...selectedPackages.map(
              (p) => Card(
                child: ListTile(
                  title: Text(p['name']),
                  subtitle: Text('₱${p['price']} each'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      onChanged: (v) => updateQuantity(p['id'], v),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text('Total: ₱${totalAmount.toStringAsFixed(2)}'),

            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cash Given'),
              onChanged: (v) =>
                  setState(() => cashGiven = double.tryParse(v) ?? 0),
            ),

            const SizedBox(height: 8),
            Text(
              'Change: ₱${change.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              'Balance: ₱${balance.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red),
            ),

            DropdownButtonFormField<String>(
              value: progressStatus,
              decoration: const InputDecoration(labelText: 'Progress'),
              items: ['pending', 'ongoing', 'done']
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => progressStatus = v!),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: submitting ? null : submitOrder,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm & Create Order'),
            ),
          ],
        ],
      ),
    );
  }
}
