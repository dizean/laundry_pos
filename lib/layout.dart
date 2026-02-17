import 'package:flutter/material.dart';
import 'package:laundry_pos/pages/customer/customer.dart';
import 'package:laundry_pos/pages/order/order.dart';
import 'package:laundry_pos/pages/package/package.dart';
import 'sidebar.dart';
import 'pages/main.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

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
      // Animate the external page
      return AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: KeyedSubtree(
    key: ValueKey(_externalPage.runtimeType),
    child: _externalPage!,
  ),
);
    }

    // Sidebar pages
    switch (_selectedIndex) {
      case 0:
        return Dashboard(
            openPage: (page) => _openExternalPage(page));
      case 1:
        return OrderScreen(
            openPage: (page) => _openExternalPage(page),
            view: orderView,
            onPackageTap: () => setState(() => orderView = OrderView.package),
            onCustomTap: () => setState(() => orderView = OrderView.custom),
            onBack: () => setState(() => orderView = OrderView.menu));
      case 2:
        return CustomerManagementPage(
            openPage: (page) => _openExternalPage(page));
      case 3:
        return PackageManagementPage(
            openPage: (page) => _openExternalPage(page));
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
          return false; // prevent default pop
        }
        return true;
      },
      child: Scaffold(
        appBar: desktop
            ? null
            : AppBar(title: const Text("POS App")),
        drawer: desktop
            ? null
            : Drawer(
                child: Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    _onItemTapped(index);
                    Navigator.pop(context);
                  },
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
                ),
              ),
            Expanded(child: _buildPage()),
          ],
        ),
      ),
    );
  }
}