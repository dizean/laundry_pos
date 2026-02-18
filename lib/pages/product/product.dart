import 'package:flutter/material.dart';
import 'package:laundry_pos/helpers/session.dart';
import 'package:laundry_pos/service/main.dart';

class ProductManagementPage extends StatefulWidget {
  final Function(Widget) openPage;
  const ProductManagementPage({super.key, required this.openPage});

  @override
  State<ProductManagementPage> createState() =>
      _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _productService = ProductService();

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  int _currentPage = 1;
  final int _perPage = 10;

  bool get isAdmin => userSession.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({int page = 1}) async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final products = await _productService.getPaginatedProducts(
        limit: _perPage,
        offset: (page - 1) * _perPage,
      );

      if (!mounted) return;

      setState(() {
        _products = products;
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

  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                await _productService.addProduct(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price:
                      double.tryParse(priceController.text.trim()) ?? 0,
                );
                Navigator.pop(context);
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
    final nameController =
        TextEditingController(text: product['name']);
    final descController =
        TextEditingController(text: product['description']);
    final priceController =
        TextEditingController(text: product['price'].toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                await _productService.updateProduct(
                  id: product['id'].toString(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  price:
                      double.tryParse(priceController.text.trim()) ?? 0,
                );
                Navigator.pop(context);
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
    _loadProducts(page: _currentPage);
  }

  @override
Widget build(BuildContext context) {
  final bool hasNextPage = _products.length == _perPage;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Products Management'),
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProduct,
          )
      ],
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
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _products.isEmpty
                          ? [
                              const DataRow(
                                cells: [
                                  DataCell(Text('No data')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                ],
                              )
                            ]
                          : _products.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                      Text(product['name'] ?? '')),
                                  DataCell(Text(
                                      product['description'] ?? '')),
                                  DataCell(Text(
                                      product['price'].toString())),
                                  DataCell(
                                    isAdmin
                                        ? Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.edit,
                                                    color:
                                                        Colors.orange),
                                                onPressed: () =>
                                                    _editProduct(
                                                        product),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete,
                                                    color:
                                                        Colors.red),
                                                onPressed: () =>
                                                    _deleteProduct(
                                                        product['id']
                                                            .toString()),
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),
                                  ),
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
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
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
                    ? () => _loadProducts(
                        page: _currentPage - 1)
                    : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              Text('Page $_currentPage'),
              const SizedBox(width: 16),
              TextButton(
                onPressed: !_loading && hasNextPage
                    ? () => _loadProducts(
                        page: _currentPage + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}}