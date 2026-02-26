import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';
class AddPackagePage extends StatefulWidget {
  final PackageService packageService;
  final ServiceService serviceService;
  final ProductService productService;
  final bool isAdmin;

  const AddPackagePage({
    super.key,
    required this.packageService,
    required this.serviceService,
    required this.productService,
    required this.isAdmin,
  });

  @override
  State<AddPackagePage> createState() =>
      _AddPackagePageState();
}

class _AddPackagePageState
    extends State<AddPackagePage> {
  final nameCtrl = TextEditingController();
  List services = [];
  List products = [];

  final Map<String, int> selectedServices = {};
  final Map<String, int> selectedProducts = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    services =
        await widget.serviceService.getAllServices();
    products =
        await widget.productService.getAllProducts();
    setState(() {});
  }

  void toggleItem(
      Map item, Map<String, int> target) {
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

    final package =
        await widget.packageService.addPackage(
      name: nameCtrl.text,
      totalPrice: 0,
    );

    final packageId = package['id'];

    for (var s in services) {
      if (selectedServices.containsKey(s['id'])) {
        final qty =
            selectedServices[s['id']]!;
        total += s['price'] * qty;

        await widget.packageService
            .addServiceToPackage(
          packageId: packageId,
          serviceId: s['id'],
          quantity: qty,
        );
      }
    }

    for (var p in products) {
      if (selectedProducts.containsKey(p['id'])) {
        final qty =
            selectedProducts[p['id']]!;
        total += p['price'] * qty;

        await widget.packageService
            .addProductToPackage(
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom:
            MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Package',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold),
            ),
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(
                      labelText:
                          'Package Name'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: savePackage,
                child:
                    const Text('Save Package'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}