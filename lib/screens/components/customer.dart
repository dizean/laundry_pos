import 'package:flutter/material.dart';

class CustomerSelector extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final String? selectedCustomerId;
  final ValueChanged<String> onCustomerSelected;
  final ValueChanged<Map<String, String>>? onAddCustomer;

  const CustomerSelector({
    super.key,
    required this.customers,
    required this.selectedCustomerId,
    required this.onCustomerSelected,
    this.onAddCustomer,
  });

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  String search = '';

  List<Map<String, dynamic>> get filteredCustomers {
    if (search.isEmpty) return widget.customers;
    return widget.customers.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final phone = (c['phone'] as String);
      final query = search.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  Future<void> _showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'phone': phoneController.text,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && widget.onAddCustomer != null) {
      widget.onAddCustomer!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCustomerId != null) {
      final selected = widget.customers
          .firstWhere((c) => c['id'].toString() == widget.selectedCustomerId);
      return ListTile(
        title: Text('Customer: ${selected['name']}'),
        subtitle: Text(selected['phone']),
      );
    }

    final matches = filteredCustomers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search Customer',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => search = v),
        ),
        const SizedBox(height: 8),

        /// Show "Add New Customer" button always if callback exists
        if (widget.onAddCustomer != null)
          ElevatedButton.icon(
            onPressed: _showAddCustomerDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add New Customer'),
          ),

        ...matches.map((c) => ListTile(
              title: Text(c['name']),
              subtitle: Text(c['phone']),
              onTap: () => widget.onCustomerSelected(c['id'].toString()),
            )),
      ],
    );
  }
}