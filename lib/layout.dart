import 'package:flutter/material.dart';
import 'package:laundry_pos/pages/customer/customer.dart';
import 'package:laundry_pos/pages/order/order.dart';
import 'package:laundry_pos/pages/package/package.dart';
import 'package:laundry_pos/pages/product/product.dart';
import 'package:laundry_pos/pages/service/service.dart';
import 'package:laundry_pos/pages/staff/staff.dart';
import 'sidebar.dart';
import 'pages/main.dart';

class MainLayout extends StatefulWidget {
  final String? userRole; // 'admin' or 'staff'

  const MainLayout({super.key, required this.userRole});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  OrderView orderView = OrderView.menu;
  Widget? _externalPage;

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _externalPage = null;
    });
  }

  void _openExternalPage(Widget page) {
    setState(() {
      _externalPage = page;
    });
  }

  Widget _buildPage() {
    if (_externalPage != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_externalPage.runtimeType),
          child: _externalPage!,
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return Dashboard(openPage: (page) => _openExternalPage(page));
      case 1:
        return OrderScreen(
          openPage: (page) => _openExternalPage(page),
          view: orderView,
          onPackageTap: () => setState(() => orderView = OrderView.package),
          onCustomTap: () => setState(() => orderView = OrderView.custom),
          onBack: () => setState(() => orderView = OrderView.menu),
        );
      case 2:
        return CustomerManagementPage(
          openPage: (page) => _openExternalPage(page),
        );
      case 3:
        return PackageManagementPage(
          openPage: (page) => _openExternalPage(page),
        );
      case 4:
        return ProductManagementPage(
          openPage: (page) => _openExternalPage(page),
        );
      case 5:
        return ServiceManagementPage(
          openPage: (page) => _openExternalPage(page),
        );
      case 6:
        if (widget.userRole != "admin") {
          return const Center(child: Text("Access Denied"));
        }
        return StaffManagementPage(openPage: (page) => _openExternalPage(page));
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);

    return WillPopScope(
      onWillPop: () async {
        if (_externalPage != null) {
          setState(() => _externalPage = null);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: desktop ? null : AppBar(title: const Text("POS App")),
        drawer: desktop
            ? null
            : Drawer(
                child: Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    _onItemTapped(index);
                    Navigator.pop(context);
                  },
                  userRole: widget.userRole,
                ),
              ),
        body: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 250,
                child: Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemTapped,
                  userRole: widget.userRole, // <-- fixed here
                ),
              ),
            Expanded(child: _buildPage()),
          ],
        ),
      ),
    );
  }
}