import 'package:flutter/material.dart';
import 'package:laundry_pos/pages/package/add.dart';
import 'package:laundry_pos/pages/package/update.dart';
import 'package:laundry_pos/service/main.dart';
import 'package:laundry_pos/helpers/utils.dart';

class PackageManagementPage extends StatefulWidget {
  final Function(Widget) openPage;

  const PackageManagementPage({
    super.key,
    required this.openPage,
  });

  @override
  State<PackageManagementPage> createState() =>
      _PackageManagementPageState();
}

class _PackageManagementPageState
    extends State<PackageManagementPage> {
  final _packageService = PackageService();
  final _serviceService = ServiceService();
  final _productService = ProductService();

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
        SnackBar(
          content: Text('Error loading packages: $e'),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// OPEN ADD PAGE (FULL SCREEN)
  Future<void> _openAddPage() async {
    await widget.openPage(
      AddPackagePage(
        packageService: _packageService,
        serviceService: _serviceService,
        productService: _productService,
        isAdmin: isAdmin,
      ),
    );

    _loadPackages();
  }

  /// OPEN UPDATE PAGE (FULL SCREEN)
  Future<void> _openUpdatePage(Map package) async {
    await widget.openPage(
      UpdatePackagePage(
        packageService: _packageService,
        serviceService: _serviceService,
        productService: _productService,
        packageData: package,
        isAdmin: isAdmin,
      ),
    );

    _loadPackages();
  }

  Future<void> _deletePackage(String packageId) async {
    try {
      await _packageService.deletePackage(packageId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package deleted successfully'),
        ),
      );

      _loadPackages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting package: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages'),
      ),

      /// ADD BUTTON
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _openAddPage,
              child: const Icon(Icons.add),
            )
          : null,

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                /// PACKAGE LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final p = packages[index];

                      return ListTile(
                        title: Text(p['name']),
                        subtitle:
                            Text('₱${p['total_price']}'),

                        trailing: isAdmin
                            ? Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color:
                                          Colors.orange,
                                    ),
                                    onPressed: () =>
                                        _openUpdatePage(
                                            p),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color:
                                          Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deletePackage(
                                            p['id']),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                ),

                /// PAGINATION CONTROLS
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                          vertical: 10),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.chevron_left),
                        onPressed:
                            _currentPage > 1
                                ? () {
                                    setState(() =>
                                        _currentPage--);
                                    _loadPackages();
                                  }
                                : null,
                      ),
                      Text(
                        'Page $_currentPage',
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.chevron_right),
                        onPressed:
                            packages.length ==
                                    _perPage
                                ? () {
                                    setState(() =>
                                        _currentPage++);
                                    _loadPackages();
                                  }
                                : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}