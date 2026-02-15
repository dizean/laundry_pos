import 'package:flutter/material.dart';
import 'package:laundry_pos/helpers/session.dart';
import 'package:laundry_pos/service/customer.dart';
import 'package:laundry_pos/screens/components/main.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState
    extends State<CustomerManagementScreen> {
  final CustomerService _customerService = CustomerService();

  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;

  int _currentPage = 1;
  final int _perPage = 10;
  int _totalCustomers = 0;

  bool get isAdmin => userSession.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers({int page = 1}) async {
    setState(() => _loading = true);

    try {
      if (_allCustomers.isEmpty) {
        final data = await _customerService.getAllCustomers();

        _allCustomers = data.map((c) {
          return {
            'id': c['id'].toString(),
            'name': c['name'] ?? '',
            'phone': c['phone'] ?? '',
          };
        }).toList();

        _totalCustomers = _allCustomers.length;
      }

      final from = (page - 1) * _perPage;
      final to = (from + _perPage).clamp(0, _allCustomers.length);

      _customers = _allCustomers.sublist(from, to);
      _currentPage = page;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? customer}) async {
    final nameController =
        TextEditingController(text: customer?['name'] ?? '');
    final phoneController =
        TextEditingController(text: customer?['phone'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(customer != null ? 'Edit Customer' : 'Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration:
                  const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              try {
                if (customer != null) {
                  await _customerService.updateCustomer(
                    id: customer['id'],
                    name: name,
                    phone: phone,
                  );
                } else {
                  await _customerService.addCustomer(
                    name: name,
                    phone: phone,
                  );
                }

                Navigator.pop(context);
                _allCustomers.clear();
                _loadCustomers(page: _currentPage);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(customer != null ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(String id) async {
    if (!isAdmin) return;

    try {
      await _customerService.deleteCustomer(id);
      _allCustomers.clear();
      _loadCustomers(page: _currentPage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:
            Text('Error deleting customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages =
        (_totalCustomers / _perPage).ceil();

    final isDesktop =
        MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(
                        isDesktop ? 32 : 16),
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context)
                            .size
                            .width,
                        child: DataTable(
                          columnSpacing: 40,
                          columns: const [
                            DataColumn(
                                label: Text('Name')),
                            DataColumn(
                                label: Text('Phone')),
                            DataColumn(
                                label: Text('Actions')),
                          ],
                          rows: _customers.map(
                            (customer) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CustomerTransactionsScreen(
                                              customerId:
                                                  customer[
                                                      'id'],
                                              customerName:
                                                  customer[
                                                      'name'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        customer['name'],
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.blue,
                                          decoration:
                                              TextDecoration
                                                  .underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                      customer['phone'])),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors
                                              .orange,
                                        ),
                                        onPressed: () =>
                                            _showAddEditDialog(
                                                customer:
                                                    customer),
                                      ),
                                      if (isAdmin)
                                        IconButton(
                                          icon:
                                              const Icon(
                                            Icons.delete,
                                            color:
                                                Colors
                                                    .red,
                                          ),
                                          onPressed: () =>
                                              _deleteCustomer(
                                                  customer[
                                                      'id']),
                                        ),
                                    ],
                                  )),
                                ],
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                          vertical: 12),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed:
                            _currentPage > 1
                                ? () =>
                                    _loadCustomers(
                                        page:
                                            _currentPage -
                                                1)
                                : null,
                        child:
                            const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Text(
                          'Page $_currentPage of $totalPages'),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed:
                            _currentPage <
                                    totalPages
                                ? () =>
                                    _loadCustomers(
                                        page:
                                            _currentPage +
                                                1)
                                : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}