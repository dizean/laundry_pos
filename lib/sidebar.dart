import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade700,
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            "My App",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _buildItem(Icons.dashboard, "Dashboard", 0),
          _buildItem(Icons.receipt_long, "Orders", 1),
          _buildItem(Icons.settings, "Settings", 2),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      tileColor: isSelected ? Colors.indigo.shade400 : null,
      onTap: () => onItemSelected(index),
    );
  }
}