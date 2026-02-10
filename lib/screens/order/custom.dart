import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/components.dart';
import 'package:laundry_pos/helpers/utils.dart';
import 'package:laundry_pos/styles.dart';

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
  late final TextEditingController cashController;
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
    cashController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    cashController.dispose();
    super.dispose();
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

    final items = selectedItems
        .map(
          (i) => {
            'id': i['id'],
            'type': i['type'],
            'price': i['price'],
            'quantity': i['quantity'],
          },
        )
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
          CustomerSelector(
            customers: customers,
            selectedCustomerId: selectedCustomerId,
            onCustomerSelected: (id) {
              setState(() {
                if (id == '__RESET__') {
                  selectedCustomerId = null;
                  selectedItems.clear();
                } else {
                  selectedCustomerId = id;
                }
              });
            },
            onAddCustomer: (data) async {
              final newId = await widget.customerService.addCustomer(
                name: data['name']!,
                phone: data['phone']!,
              );
              setState(() => selectedCustomerId = newId);
              _loadData();
            },
          ),

          if (selectedCustomerId != null) ...[
            const SizedBox(height: 16),

            /// RUSH ORDER
            CheckboxListTile(
              value: isRush,
              onChanged: (v) => setState(() => isRush = v ?? false),
              title: Text('Rush Order', style: AppTextStyles.itemTitle),
              subtitle: Text('Adds ₱50', style: AppTextStyles.labelText),
              // secondary: const Icon(Icons.flash_on, color: Colors.red),
            ),

            const Divider(),

            /// CLAIMABLE DATE
            ClaimableDateTile(date: claimableDate, onTap: pickClaimableDate),

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
                final selected = selectedItems.any(
                  (i) => i['id'] == item['id'] && i['type'] == type,
                );
                return ChoiceChip(
                  selected: selected,
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₱${item['price']}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  onSelected: (_) => toggleItem(item, type),
                );
              }).toList(),
            ),

            if (selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),

              /// SELECTED ITEMS
              SelectedPackagesCard(
                selectedPackages: selectedItems,
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
        ],
      ),
    );
  }
}
