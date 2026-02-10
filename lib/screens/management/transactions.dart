import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/components.dart';

class TransactionsScreen extends StatefulWidget {
  final int pageSize;

  const TransactionsScreen({
    super.key,
    this.pageSize = 10,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum TransactionStatus { all, pending, ongoing, done }

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.ongoing:
        return 'Ongoing';
      case TransactionStatus.done:
        return 'Done';
      case TransactionStatus.all:
        return 'All';
    }
  }

  String? get value {
    switch (this) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.ongoing:
        return 'ongoing';
      case TransactionStatus.done:
        return 'done';
      case TransactionStatus.all:
        return null;
    }
  }
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _currentPageOrders = [];
  bool _loading = true;
  int _currentPage = 1;
  TransactionStatus _selectedStatus = TransactionStatus.all;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final orders = await _orderService.getAllOrders();

    // Rush first, newest next
    orders.sort((a, b) {
      final rushA = a['is_rush'] == true;
      final rushB = b['is_rush'] == true;
      if (rushA != rushB) return rushB ? 1 : -1;

      final dateA = DateTime.parse(a['date_created']);
      final dateB = DateTime.parse(b['date_created']);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _allOrders = orders;
      _currentPage = 1;
      _updatePage();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedStatus.value == null) return _allOrders;
    return _allOrders
        .where((o) => o['progress'] == _selectedStatus.value)
        .toList();
  }

  int get _totalPages =>
      (_filteredOrders.length / widget.pageSize).ceil().clamp(1, 9999);

  void _updatePage() {
    final start = (_currentPage - 1) * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, _filteredOrders.length);
    _currentPageOrders = _filteredOrders.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _updatePage();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updatePage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Transactions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: _currentPageOrders.isEmpty
              ? const Center(child: Text('No transactions found'))
              : ListView.builder(
                  itemCount: _currentPageOrders.length,
                  itemBuilder: (context, index) {
                    final order = _currentPageOrders[index];
                    final isRush = order['is_rush'] == true;

                    return Card(
                      elevation: isRush ? 6 : 2,
                      color: isRush ? Colors.red.shade50 : null,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isRush ? Icons.flash_on : Icons.receipt_long,
                          color: isRush ? Colors.red : Colors.grey,
                        ),
                        title: Text(
                          "Order #${order['order_id'].toString().substring(0, 8)}",
                          style: TextStyle(
                            fontWeight: isRush
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          "₱${order['total_amount']} • ${order['progress']}",
                        ),
                        trailing: isRush
                            ? const Chip(
                                label: Text("RUSH"),
                                backgroundColor: Colors.redAccent,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : null,
                        onTap: () => showOrderDetailsDialog(
                          context,
                          order['order_id'],
                          _orderService,
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _currentPage > 1 ? _previousPage : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Text('Page $_currentPage of $_totalPages'),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _currentPage < _totalPages ? _nextPage : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TransactionStatus.values.map((status) {
          final isSelected = status == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                  _currentPage = 1;
                  _updatePage();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}