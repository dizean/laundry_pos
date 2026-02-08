import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/selector/customer.dart';

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

  /// id, name, price, quantity, type
  List<Map<String, dynamic>> selectedItems = [];

  bool showServices = true;
  String customerSearch = '';

  static const double rushFee = 50;

  List<Map<String, dynamic>> get filteredCustomers {
    if (customerSearch.isEmpty) return customers;
    return customers
        .where(
          (c) =>
              (c['name'] as String).toLowerCase().contains(
                customerSearch.toLowerCase(),
              ) ||
              (c['phone'] as String).contains(customerSearch),
        )
        .toList();
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

  double get baseTotal {
    return selectedItems.fold(
      0,
      (sum, i) => sum + (i['price'] as num).toDouble() * (i['quantity'] as int),
    );
  }

  double get totalAmount => baseTotal + (isRush ? rushFee : 0);

  double get balance {
    final b = totalAmount - cashGiven;
    return b < 0 ? 0 : b;
  }

  double get change {
    final c = cashGiven - totalAmount;
    return c < 0 ? 0 : c;
  }

  void toggleItem(Map<String, dynamic> item, String type) {
    setState(() {
      final index = selectedItems.indexWhere(
        (i) => i['id'] == item['id'] && i['type'] == type,
      );

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

  void updateQuantity(String id, String type, String value) {
    final q = int.tryParse(value) ?? 1;
    setState(() {
      final item = selectedItems.firstWhere(
        (i) => i['id'] == id && i['type'] == type,
      );
      item['quantity'] = q < 1 ? 1 : q;
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
        claimableDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          17, // default 5PM claim time
        );
      });
    }
  }

  Future<void> submitOrder() async {
    if (selectedCustomerId == null ||
        selectedItems.isEmpty ||
        claimableDate == null ||
        submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => submitting = true);

    final items = selectedItems.map((i) {
      return {
        'id': i['id'],
        'type': i['type'],
        'price': i['price'],
        'quantity': i['quantity'],
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
        claimableDate: claimableDate, // timestamptz
        items: items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );

      await Future.delayed(const Duration(seconds: 1));
      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const Text(
                'Custom Order',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// CUSTOMER
          CustomerSelector(
            customers: customers,
            selectedCustomerId: selectedCustomerId,
            onCustomerSelected: (id) => setState(() => selectedCustomerId = id),
            onAddCustomer: (data) async {
              // data = {'name': '...', 'phone': '...'}
              final newCustomerId = await widget.customerService.addCustomer(
                name: data['name']!,
                phone: data['phone']!,
              );
              setState(() => selectedCustomerId = newCustomerId);
              _loadData();
            },
          ),

          if (selectedCustomerId != null) ...[
            const SizedBox(height: 16),

            /// RUSH CHECKBOX
            CheckboxListTile(
              value: isRush,
              onChanged: (v) => setState(() => isRush = v ?? false),
              title: const Text('Rush Order'),
              subtitle: const Text('Adds ₱50 to total'),
              secondary: const Icon(Icons.flash_on, color: Colors.red),
            ),

            /// CLAIMABLE DATE
            ListTile(
              title: const Text('Claimable Date'),
              subtitle: Text(
                claimableDate == null
                    ? 'Select date'
                    : claimableDate!.toLocal().toString(),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickClaimableDate,
            ),

            const Divider(),

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

            Wrap(
              spacing: 12,
              children: (showServices ? services : products).map((item) {
                final type = showServices ? 'service' : 'product';
                final selected = selectedItems.any(
                  (i) => i['id'] == item['id'] && i['type'] == type,
                );
                return ChoiceChip(
                  label: Text('${item['name']} (₱${item['price']})'),
                  selected: selected,
                  onSelected: (_) => toggleItem(item, type),
                );
              }).toList(),
            ),

            if (selectedItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...selectedItems.map(
                (i) => ListTile(
                  title: Text(i['name']),
                  subtitle: Text('₱${i['price']}'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      onChanged: (v) => updateQuantity(i['id'], i['type'], v),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text('Total: ₱${totalAmount.toStringAsFixed(2)}'),
              Text('Balance: ₱${balance.toStringAsFixed(2)}'),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cash Given'),
                onChanged: (v) =>
                    setState(() => cashGiven = double.tryParse(v) ?? 0),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitting ? null : submitOrder,
                child: submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm & Create Order'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
