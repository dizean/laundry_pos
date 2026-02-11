import 'package:flutter/material.dart';
import 'login.dart';
import 'management/staff.dart';
import 'management/customer.dart';
import 'management/service.dart';
import 'management/product.dart';
import 'management/package.dart';
import 'order/order.dart';
import 'package:laundry_pos/helpers/session.dart';
import 'package:laundry_pos/service/main.dart'; 
import 'management/transactions.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  OrderView orderView = OrderView.menu;

  final CustomerService _customerService = CustomerService();
  final PackageService _packageService = PackageService();
  final OrderService _orderService = OrderService(); // added order service
  final ServiceService _serviceService = ServiceService();
  final ProductService _productService = ProductService();
  bool get isAdmin => userSession.role == 'admin';
  bool get isStaff => userSession.role == 'staff';
  String get email => userSession.email ?? '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> logout() async {
    userSession.email = null;
    userSession.role = null;

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    Widget sidebar = Container(
      width: 240,
      color: Colors.blueGrey.shade50,
      child: ListView(
        children: isAdmin ? _adminMenu() : _staffMenu(),
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          isAdmin
              ? 'Admin POS Dashboard'
              : isStaff
                  ? 'Staff POS Dashboard'
                  : 'POS Dashboard',
        ),
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(email)),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      drawer: !isDesktop
          ? Drawer(
              child: ListView(
                children: isAdmin ? _adminMenu() : _staffMenu(),
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildScreen(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENUS =================
  List<Widget> _adminMenu() => [
        _menu(Icons.dashboard, "Dashboard", 0),
        _menu(Icons.shopping_cart, "Orders", 1),
        _menu(Icons.inventory, "Services", 2),
        _menu(Icons.shopping_bag, "Products", 3),
        _menu(Icons.card_giftcard, "Packages", 4),
        _menu(Icons.people, "Users", 5),
        _menu(Icons.person_add, "Staff", 6),
        _menu(Icons.person, "Customers", 7),
      ];

  List<Widget> _staffMenu() => [
        _menu(Icons.shopping_cart, "Orders", 0),
        _menu(Icons.person, "Customers", 1),
        _menu(Icons.inventory, "Services", 2),
        _menu(Icons.shopping_bag, "Products", 3),
        _menu(Icons.card_giftcard, "Packages", 4),
        _menu(Icons.receipt_long, "Transactions", 5),
      ];

  Widget _menu(IconData icon, String text, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      selected: selectedIndex == index,
      onTap: () {
        setState(() {
          selectedIndex = index;
          if (text == "Orders") orderView = OrderView.menu;
        });
        if (MediaQuery.of(context).size.width < 900) Navigator.pop(context);
      },
    );
  }

  // ================= CONTENT =================
  Widget _buildScreen() {
    if (isAdmin) {
      switch (selectedIndex) {
        case 1: // Orders
          return OrderScreen(
            view: orderView,
            onPackageTap: () => setState(() => orderView = OrderView.package),
            onCustomTap: () => setState(() => orderView = OrderView.custom),
            onBack: () => setState(() => orderView = OrderView.menu),
            customerService: _customerService,
            packageService: _packageService,
            orderService: _orderService, // pass order service
            productService: _productService,
            serviceService: _serviceService
          );
        case 2:
          return const ServiceManagementScreen();
        case 3:
          return const ProductManagementScreen();
        case 4:
          return const PackageScreen();
        case 6:
          return const StaffManagementScreen();
        case 7:
          return  TransactionsScreen(
                  orderService: OrderService(),
                  pageSize: 5,
                );
        default:
          return _title("Admin Dashboard");
      }
    }

    if (isStaff) {
      switch (selectedIndex) {
        case 0: // Orders
          return OrderScreen(
            view: orderView,
            onPackageTap: () => setState(() => orderView = OrderView.package),
            onCustomTap: () => setState(() => orderView = OrderView.custom),
            onBack: () => setState(() => orderView = OrderView.menu),
            customerService: _customerService,
            packageService: _packageService,
            orderService: _orderService, // pass order service
            productService: _productService,
            serviceService: _serviceService
          );
        case 1:
          return const CustomerManagementScreen();
        case 2:
          return const ServiceManagementScreen();
        case 3:
          return const ProductManagementScreen();
        case 4:
          return const PackageScreen();
        case 5:
          return  TransactionsScreen(
                  orderService: OrderService(),
                  pageSize: 10,
                );
        default:
          return _title("Select an option");
      }
    }

    return _title("Role not assigned");
  }

  Widget _title(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }
}
