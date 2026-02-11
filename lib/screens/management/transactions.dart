import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/screens/components/main.dart';
import 'package:laundry_pos/helpers/utils.dart';
class TransactionsScreen extends StatefulWidget {
  final OrderService orderService;
  final int pageSize;

  const TransactionsScreen({
    super.key,
    required this.orderService,
    this.pageSize = 5,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}


class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _allOrders = [];
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

    final orders = await widget.orderService.getAllOrders();

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

  List<Map<String, dynamic>> get _currentPageOrders {
    final start = (_currentPage - 1) * widget.pageSize;
    final end =
        (start + widget.pageSize).clamp(0, _filteredOrders.length);

    return _filteredOrders.sublist(start, end);
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          child: TransactionsList(
            orders: _currentPageOrders,
            onTap: (order) {
              showOrderDetailsDialog(
                context,
                order['order_id'],
                widget.orderService,
              );
            },
          ),
        ),
        if (_totalPages > 1) _buildPagination(),
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
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
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
    );
  }
}