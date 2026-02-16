import 'package:flutter/material.dart';
// import 'add_customer_page.dart';

class Dashboard extends StatelessWidget {
  final Function(Widget) openPage;

  const Dashboard({super.key, required this.openPage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Dashboard Screen", style: TextStyle(fontSize: 28)),
          const SizedBox(height: 30),
          // ElevatedButton.icon(
          //   onPressed: () => openPage(const AddCustomerPage()),
          //   icon: const Icon(Icons.person_add),
          //   label: const Text("Add Customer"),
          // ),
        ],
      ),
    );
  }
}