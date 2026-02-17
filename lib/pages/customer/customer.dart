import 'package:flutter/material.dart';
import 'package:laundry_pos/helpers/utils.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/main.dart';

class CustomerManagementPage extends StatefulWidget {
  final Function(Widget) openPage;

  const CustomerManagementPage({
    super.key,
    required this.openPage,
  });

  @override
  State<CustomerManagementPage> createState() =>
      _CustomerManagementPageState();
}

class _CustomerManagementPageState
    extends State<CustomerManagementPage> {
  final _customerService = CustomerService();

  List<Map<String, dynamic>> _customers = [];

  bool _loading = true;

  int _currentPage = 1;
  final int _perPage = 15;
  // int _totalCustomers = 0; // optional if you fetch count

  bool get isAdmin => userSession.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers({int page = 1}) async {
    setState(() => _loading = true);

    try {
      final offset = (page - 1) * _perPage;

      final data = await _customerService.getAllCustomers(
        limit: _perPage,
        offset: offset,
      );

      setState(() {
        _customers = data.map((c) {
          return {
            'id': c['id'].toString(),
            'name': c['name'] ?? '',
            'phone': c['phone'] ?? '',
          };
        }).toList();

        _currentPage = page;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteCustomer(String id) async {
    if (!isAdmin) return;

    try {
      await _customerService.deleteCustomer(id);
      await _loadCustomers(page: _currentPage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.all(isDesktop ? 32 : 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth:
                                    constraints.maxWidth),
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
                              rows:
                                  _customers.map((customer) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      InkWell(
                                        onTap: () =>
                                            widget.openPage(
                                          CustomerTransactionsScreen(
                                            customerId:
                                                customer['id'],
                                            customerName:
                                                customer['name'],
                                          ),
                                        ),
                                        child: Text(
                                          customer['name'],
                                          style:
                                              const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration
                                                    .underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                        Text(customer['phone'])),
                                    DataCell(
                                      Row(
                                        children: [
                                          if (isAdmin)
                                            IconButton(
                                              icon:
                                                  const Icon(
                                                Icons.delete,
                                                color:
                                                    Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _deleteCustomer(
                                                      customer[
                                                          'id']),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
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
                        onPressed: _currentPage > 1
                            ? () => _loadCustomers(
                                page:
                                    _currentPage - 1)
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Text('Page $_currentPage'),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _customers.length ==
                                _perPage
                            ? () => _loadCustomers(
                                page:
                                    _currentPage + 1)
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