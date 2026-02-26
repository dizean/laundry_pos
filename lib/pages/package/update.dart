import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

class UpdatePackagePage extends StatefulWidget {
  final PackageService packageService;
  final ServiceService serviceService;
  final ProductService productService;
  final Map packageData;
  final bool isAdmin;

  const UpdatePackagePage({
    super.key,
    required this.packageService,
    required this.serviceService,
    required this.productService,
    required this.packageData,
    required this.isAdmin,
  });

  @override
  State<UpdatePackagePage> createState() => _UpdatePackagePageState();
}

class _UpdatePackagePageState extends State<UpdatePackagePage> {
  final nameCtrl = TextEditingController();
  List services = [];
  List products = [];

  final Map<String, int> selectedServices = {};
  final Map<String, int> selectedProducts = {};

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.packageData['name'];
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

  Future<void> updatePackage() async {
    if (!widget.isAdmin) return;

    double total = 0;
    final packageId = widget.packageData['id'];

    // Clear existing relations first if needed (optional depending on backend)

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
              width: 70,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Package'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updatePackage,
                    child: const Text('Update Package'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}