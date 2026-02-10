import 'package:flutter/material.dart';
import 'package:laundry_pos/helpers/session.dart';
import 'package:laundry_pos/service/main.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> _allProducts = []; // All products fetched
  List<Map<String, dynamic>> _products = []; // Current page
  bool _loading = true;

  int _currentPage = 1;
  int _totalProducts = 0;
  final int _perPage = 10;

  bool get isAdmin => userSession.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({int page = 1}) async {
  setState(() => _loading = true);
  try {
    // Fetch all products once
    if (_allProducts.isEmpty) {
      final rawProducts = await _productService.getAllProducts();

      // Ensure all items are Maps with correct types
      _allProducts = rawProducts.map((p) {
        return {
          'id': p['id'].toString(),
          'name': p['name'] ?? '',
          'description': p['description'] ?? '',
          'price': (p['price'] is num) ? p['price'] : double.tryParse(p['price'].toString()) ?? 0,
        };
      }).toList();

      _totalProducts = _allProducts.length;
    }

    // Pagination logic
    final from = (page - 1) * _perPage;
    final to = (from + _perPage).clamp(0, _allProducts.length);

    if (from >= to) {
      _products = [];
    } else {
      _products = _allProducts.sublist(from, to);
    }

    _currentPage = page;
  } catch (e, st) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading products: $e')),
    );
  } finally {
    setState(() => _loading = false);
  }
}

  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                await _productService.addProduct(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price: double.tryParse(priceController.text.trim()) ?? 0,
                );
                Navigator.pop(context);

                // Clear cached products and reload
                _allProducts.clear();
                _loadProducts(page: _currentPage);
              },
              child: const Text('Add'),
            ),
        ],
      ),
    );

    nameController.dispose();
    descController.dispose();
    priceController.dispose();
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final nameController = TextEditingController(text: product['name']);
    final descController = TextEditingController(text: product['description']);
    final priceController = TextEditingController(text: product['price'].toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                await _productService.updateProduct(
                  id: product['id'].toString(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price: double.tryParse(priceController.text.trim()) ?? 0,
                );
                Navigator.pop(context);

                // Clear cache and reload
                _allProducts.clear();
                _loadProducts(page: _currentPage);
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );

    nameController.dispose();
    descController.dispose();
    priceController.dispose();
  }

  Future<void> _deleteProduct(String id) async {
    if (!isAdmin) return;
    await _productService.deleteProduct(id);

    // Clear cache and reload
    _allProducts.clear();
    _loadProducts(page: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalProducts / _perPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        actions: [if (isAdmin) IconButton(icon: const Icon(Icons.add), onPressed: _addProduct)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: DataTable(
                          columnSpacing: 30,
                          columns: [
                            const DataColumn(label: Text('Name')),
                            const DataColumn(label: Text('Description')),
                            const DataColumn(label: Text('Price')),
                            if (isAdmin) const DataColumn(label: Text('Actions')),
                          ],
                          rows: _products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(Text(product['name'] ?? '')),
                                DataCell(Text(product['description'] ?? '')),
                                DataCell(Text(product['price'].toString())),
                                if (isAdmin)
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () => _editProduct(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteProduct(product['id'].toString()),
                                      ),
                                    ],
                                  )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 1 ? () => _loadProducts(page: _currentPage - 1) : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Text('Page $_currentPage of $totalPages'),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _currentPage < totalPages ? () => _loadProducts(page: _currentPage + 1) : null,
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
