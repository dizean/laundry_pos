import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
// import 'package:laundry_pos/screens/components/main.dart';
import 'package:laundry_pos/helpers/utils.dart';
class TransactionsPage extends StatefulWidget {
  final Function(Widget) openPage;
  const TransactionsPage({super.key, required this.openPage});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}


class _TransactionsPageState extends State<TransactionsPage> {
  final _orderService = OrderService();
  List<Map<String, dynamic>> _allOrders = [];
  bool _loading = true;

  int _currentPage = 1;
  final int _perPage = 10;

  bool get isAdmin => userSession.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({int page = 1}) async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final orders = await _orderService.getPaginatedOrders(
        limit: _perPage,
        offset: (page - 1) * _perPage,
      );

      if (!mounted) return;

      setState(() {
        _allOrders = orders;
        _currentPage = page;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNextPage = _allOrders.length == _perPage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: DataTable(
                        columnSpacing: 30,
                        columns: const [
                          DataColumn(label: Text('Transaction ID')),
                          DataColumn(label: Text('Date of Transaction')),
                          DataColumn(label: Text('Progress')),
                        ],
                        rows: _allOrders.isEmpty
                            ? [
                                const DataRow(
                                  cells: [
                                    DataCell(Text('No data')),
                                    DataCell(Text('')),
                                    DataCell(Text('')),
                                    DataCell(Text('')),
                                  ],
                                ),
                              ]
                            : _allOrders.map((product) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(product['id'] ?? '')),
                                    DataCell(
                                      Text(product['date_created'] ?? ''),
                                    ),
                                    DataCell(Text(product['progress'].toString())),
                                  ],
                                );
                              }).toList(),
                      ),
                    ),
                  ),

                  // 🔹 Loader overlay
                  if (_loading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black12,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Pagination Controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: !_loading && _currentPage > 1
                      ? () => _loadOrders(page: _currentPage - 1)
                      : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Text('Page $_currentPage'),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: !_loading && hasNextPage
                      ? () => _loadOrders(page: _currentPage + 1)
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
