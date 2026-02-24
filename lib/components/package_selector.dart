import 'package:flutter/material.dart';

class PackageSelector extends StatelessWidget {
  final List<Map<String, dynamic>> packages;
  final List<Map<String, dynamic>> selectedPackages;
  final Function(Map<String, dynamic>) onToggle;

  const PackageSelector({
    super.key,
    required this.packages,
    required this.selectedPackages,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: packages.map((p) {
          final selected =
              selectedPackages.any((x) => x['id'] == p['id']);
          return ChoiceChip(
            selected: selected,
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '₱${p['total_price']}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            onSelected: (_) => onToggle(p),
          );
        }).toList(),
      ),
    );
  }
}