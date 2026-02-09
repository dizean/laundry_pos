import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/customer.dart';
import 'package:laundry_pos/screens/components/claimable.dart';
import 'package:laundry_pos/helpers/utils.dart';
import 'package:laundry_pos/styles.dart';
import 'package:laundry_pos/helpers/functions.dart';

class CustomOrderScreen extends StatefulWidget {
  final VoidCallback onBack;
  final CustomerService customerService;
  final ServiceService serviceService;
  final ProductService productService;
  final OrderService orderService;

  const CustomOrderScreen({
    super.key,
    required this.onBack,
    required this.customerService,
    required this.serviceService,
    required this.productService,
    required this.orderService,
  });

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> products = [];

  String? selectedCustomerId;
  bool loading = true;
  bool submitting = false;

  double cashGiven = 0;
  bool isRush = false;
  String progressStatus = 'pending';
  DateTime? claimableDate;

  List<Map<String, dynamic>> selectedItems = [];
  bool showServices = true;

  static const double rushFee = 50;

  List<Map<String, dynamic>> get filteredCustomers {
    return customers;
  }

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
      services = List<Map<String, dynamic>>.from(
        await widget.serviceService.getAllServices(),
      );
      products = List<Map<String, dynamic>>.from(
        await widget.productService.getAllProducts(),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  /// ================= COMPUTED =================
  double get baseTotal {
    return selectedItems.fold(
      0,
      (sum, i) => sum + (i['price'] as num).toDouble() * (i['quantity'] as int),
    );
  }

  double get totalAmount => baseTotal + (isRush ? rushFee : 0);
  double get balance => calculateBalance(totalAmount, cashGiven);

  /// ================= ACTIONS =================
  void toggleItem(Map<String, dynamic> item, String type) {
    setState(() {
      final index =
          selectedItems.indexWhere((i) => i['id'] == item['id'] && i['type'] == type);
      if (index >= 0) {
        selectedItems.removeAt(index);
      } else {
        selectedItems.add({
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'quantity': 1,
          'type': type,
        });
      }
    });
  }

  void updateQuantity(String id, int value) {
    setState(() {
      final p = selectedItems.firstWhere((x) => x['id'] == id);
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
    if (selectedCustomerId == null || selectedItems.isEmpty || claimableDate == null || submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => submitting = true);

    final items = selectedItems
        .map((i) => {
              'id': i['id'],
              'type': i['type'],
              'price': i['price'],
              'quantity': i['quantity'],
            })
        .toList();

    try {
      await widget.orderService.createOrder(
        customerId: selectedCustomerId!,
        status: balance == 0 ? 'paid' : 'unpaid',
        totalAmount: totalAmount,
        balance: balance,
        progress: progressStatus,
        isRush: isRush,
        claimableDate: claimableDate,
        items: items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order created successfully')));

      await Future.delayed(const Duration(seconds: 1));
      widget.onBack();
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

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
                'Custom Order',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// CUSTOMER
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer', style: AppTextStyles.sectionTitle),
                  const Divider(),
                  CustomerSelector(
                    customers: customers,
                    selectedCustomerId: selectedCustomerId,
                    onCustomerSelected: (id) =>
                        setState(() => selectedCustomerId = id),
                    onAddCustomer: (data) async {
                      final newCustomerId =
                          await widget.customerService.addCustomer(
                        name: data['name']!,
                        phone: data['phone']!,
                      );
                      setState(() => selectedCustomerId = newCustomerId);
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (selectedCustomerId != null) ...[
            const SizedBox(height: 16),

            /// RUSH ORDER
            CheckboxListTile(
              value: isRush,
              onChanged: (v) => setState(() => isRush = v ?? false),
              title: Text('Rush Order', style: AppTextStyles.itemTitle),
              subtitle: Text('Adds ₱50', style: AppTextStyles.labelText),
              secondary: const Icon(Icons.flash_on, color: Colors.red),
            ),

            const Divider(),

            /// CLAIMABLE DATE
            ClaimableDateTile(
              date: claimableDate,
              onTap: pickClaimableDate,
            ),

            const SizedBox(height: 16),

            /// SERVICES / PRODUCTS TOGGLE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => showServices = true),
                  child: const Text('Services'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() => showServices = false),
                  child: const Text('Products'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// SERVICE/PRODUCT SELECTION
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: (showServices ? services : products).map((item) {
                final type = showServices ? 'service' : 'product';
                final selected = selectedItems
                    .any((i) => i['id'] == item['id'] && i['type'] == type);
                return ChoiceChip(
                  label: Text('${item['name']} (₱${item['price']})'),
                  selected: selected,
                  onSelected: (_) => toggleItem(item, type),
                );
              }).toList(),
            ),

            if (selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),

              /// SELECTED ITEMS
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Selected Items', style: AppTextStyles.sectionTitle),
                      ),
                    ),
                    const Divider(),
                    ...selectedItems.map(
                      (i) => ListTile(
                        title: Text(i['name'], style: AppTextStyles.itemTitle),
                        subtitle: Text('₱${i['price']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  updateQuantity(i['id'], i['quantity'] - 1),
                            ),
                            Text(i['quantity'].toString(),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  updateQuantity(i['id'], i['quantity'] + 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// PAYMENT SUMMARY
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Summary', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      Text('Total: ${formatCurrency(totalAmount)}',
                          style: AppTextStyles.paymentTotal),
                      const SizedBox(height: 6),
                      Text('Balance: ${formatCurrency(balance)}',
                          style: AppTextStyles.paymentBalance),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cash Given'),
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
        ],
      ),
    );
  }
}