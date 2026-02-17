import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/helpers/utils.dart';

class PackageManagementPage extends StatefulWidget {
  final Function(Widget) openPage;
  const PackageManagementPage({super.key, required this.openPage});

  @override
  State<PackageManagementPage> createState() => _PackageManagementPageState();
}

class _PackageManagementPageState extends State<PackageManagementPage> {
  final  _packageService = PackageService();
  final  _serviceService = ServiceService();
  final  _productService = ProductService();
  int _currentPage = 1;
  final int _perPage = 15;
  bool get isAdmin => userSession.role == 'admin';

  List packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

Future<void> _loadPackages() async {
  setState(() => _loading = true);

  try {
    final data = await _packageService.getAllPackages(
      limit: _perPage,
      offset: (_currentPage - 1) * _perPage,
    );

    setState(() => packages = data);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading packages: $e')),
    );
  } finally {
    setState(() => _loading = false);
  }
}

  void openAddPackageModal({Map? package}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPackageModal(
        packageService: _packageService,
        serviceService: _serviceService,
        productService: _productService,
        existingPackage: package,
        isAdmin: isAdmin,
      ),
    );
    _loadPackages();
  }

  Future<void> _deletePackage(String packageId) async {
    try {
      await _packageService.deletePackage(packageId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package deleted successfully')),
      );
      _loadPackages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting package: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packages')),

      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => openAddPackageModal(),
              child: const Icon(Icons.add),
            )
          : null,

      body: _loading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: packages.length,
              itemBuilder: (_, i) {
                final p = packages[i];
                return ListTile(
                  title: Text(p['name']),
                  subtitle: Text('₱${p['total_price']}'),
                  trailing: isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () =>
                                  openAddPackageModal(package: p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deletePackage(p['id']),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          ),

          // ✅ PAGINATION CONTROLS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadPackages();
                        }
                      : null,
                ),
                Text('Page $_currentPage'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: packages.length == _perPage
                      ? () {
                          setState(() => _currentPage++);
                          _loadPackages();
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),);
  }
}

class AddPackageModal extends StatefulWidget {
  final PackageService packageService;
  final ServiceService serviceService;
  final ProductService productService;
  final Map? existingPackage;
  final bool isAdmin;

  const AddPackageModal({
    super.key,
    required this.packageService,
    required this.serviceService,
    required this.productService,
    required this.isAdmin,
    this.existingPackage,
  });

  @override
  State<AddPackageModal> createState() => _AddPackageModalState();
}

class _AddPackageModalState extends State<AddPackageModal> {
  final nameCtrl = TextEditingController();
  List services = [];
  List products = [];

  final Map<String, int> selectedServices = {};
  final Map<String, int> selectedProducts = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingPackage != null) {
      nameCtrl.text = widget.existingPackage!['name'];
    }
    fetchData();
  }

  Future<void> fetchData() async {
    services = await widget.serviceService.getAllServices();
    products = await widget.productService.getAllProducts();
    setState(() {});
  }

  void toggleItem(Map item, Map<String, int> target) {
    if (!widget.isAdmin) return;

    final id = item['id'];
    setState(() {
      if (target.containsKey(id)) {
        target.remove(id);
      } else {
        target[id] = 1;
      }
    });
  }

  Future<void> savePackage() async {
    if (!widget.isAdmin) return;

    double total = 0;
    String packageId;

    if (widget.existingPackage != null) {
      packageId = widget.existingPackage!['id'];
      await widget.packageService.updatePackage(
        id: packageId,
        name: nameCtrl.text,
        totalPrice: 0,
      );
    } else {
      final package = await widget.packageService.addPackage(
        name: nameCtrl.text,
        totalPrice: 0,
      );
      packageId = package['id'];
    }

    for (var s in services) {
      if (selectedServices.containsKey(s['id'])) {
        final qty = selectedServices[s['id']]!;
        total += s['price'] * qty;
        await widget.packageService.addServiceToPackage(
          packageId: packageId,
          serviceId: s['id'],
          quantity: qty,
        );
      }
    }

    for (var p in products) {
      if (selectedProducts.containsKey(p['id'])) {
        final qty = selectedProducts[p['id']]!;
        total += p['price'] * qty;
        await widget.packageService.addProductToPackage(
          packageId: packageId,
          productId: p['id'],
          quantity: qty,
        );
      }
    }

    await widget.packageService.updatePackage(
      id: packageId,
      name: nameCtrl.text,
      totalPrice: total,
    );

    Navigator.pop(context);
  }

  Widget buildItem(Map item, Map<String, int> target) {
    final id = item['id'];
    final selected = target.containsKey(id);

    return ListTile(
      title: Text(item['name']),
      subtitle: Text('₱${item['price']}'),
      trailing: selected && widget.isAdmin
          ? SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Qty'),
                onChanged: (v) =>
                    target[id] = int.tryParse(v) ?? 1,
              ),
            )
          : null,
      onTap: widget.isAdmin ? () => toggleItem(item, target) : null,
      tileColor: selected ? Colors.green.shade100 : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingPackage != null
                  ? 'Edit Package'
                  : 'Create Package',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: nameCtrl,
              enabled: widget.isAdmin,
              decoration:
                  const InputDecoration(labelText: 'Package Name'),
            ),

            const SizedBox(height: 16),
            const Text('Services'),
            ...services.map((s) => buildItem(s, selectedServices)),

            const SizedBox(height: 16),
            const Text('Products'),
            ...products.map((p) => buildItem(p, selectedProducts)),

            const SizedBox(height: 24),

            if (widget.isAdmin)
              ElevatedButton(
                onPressed: savePackage,
                child: Text(
                  widget.existingPackage != null
                      ? 'Update Package'
                      : 'Save Package',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
