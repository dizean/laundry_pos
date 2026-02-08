import 'package:flutter/material.dart';
import 'package:laundry_pos/helpers/session.dart';
import 'package:laundry_pos/service/service.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final ServiceService _serviceService = ServiceService();

  List<Map<String, dynamic>> _allServices = []; // All services
  List<Map<String, dynamic>> _services = []; // Current page
  bool _loading = true;

  int _currentPage = 1;
  int _perPage = 10;
  int _totalServices = 0;

  bool get isAdmin => userSession.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices({int page = 1}) async {
    setState(() => _loading = true);
    try {
      if (_allServices.isEmpty) {
        final raw = await _serviceService.getAllServices();
        _allServices = raw.map((s) {
          return {
            'id': s['id'].toString(),
            'name': s['name'] ?? '',
            'description': s['description'] ?? '',
            'price': (s['price'] is num)
                ? s['price']
                : double.tryParse(s['price'].toString()) ?? 0,
          };
        }).toList();
        _totalServices = _allServices.length;
      }

      // Pagination
      final from = (page - 1) * _perPage;
      final to = (from + _perPage).clamp(0, _allServices.length);

      if (from >= to) {
        _services = [];
      } else {
        _services = _allServices.sublist(from, to);
      }

      _currentPage = page;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? service}) async {
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final descriptionController =
        TextEditingController(text: service?['description'] ?? '');
    final priceController =
        TextEditingController(text: service?['price']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(service != null ? 'Edit Service' : 'Add Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          if (isAdmin)
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0;

                try {
                  if (service != null) {
                    await _serviceService.updateService(
                      id: service['id'].toString(),
                      name: name,
                      description: description,
                      price: price,
                    );
                  } else {
                    await _serviceService.addService(
                      name: name,
                      description: description,
                      price: price,
                    );
                  }

                  Navigator.pop(context);
                  _allServices.clear(); // Clear cache
                  _loadServices(page: _currentPage);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
  }

  Future<void> _deleteService(String id) async {
    if (!isAdmin) return;

    try {
      await _serviceService.deleteService(id);
      _allServices.clear(); // Clear cache
      _loadServices(page: _currentPage);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalServices / _perPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Management'),
        actions: [
          if (isAdmin)
            IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditDialog()),
        ],
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
                            const DataColumn(label: Text('Service Name')),
                            const DataColumn(label: Text('Description')),
                            const DataColumn(label: Text('Price')),
                            if (isAdmin) const DataColumn(label: Text('Actions')),
                          ],
                          rows: _services.map((service) {
                            return DataRow(
                              cells: [
                                DataCell(Text(service['name'] ?? '')),
                                DataCell(Text(service['description'] ?? '')),
                                DataCell(Text((service['price'] as num).toStringAsFixed(2))),
                                if (isAdmin)
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showAddEditDialog(service: service),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteService(service['id'].toString()),
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
                // Pagination controls
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 1
                            ? () => _loadServices(page: _currentPage - 1)
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Text('Page $_currentPage of $totalPages'),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _currentPage < totalPages
                            ? () => _loadServices(page: _currentPage + 1)
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
