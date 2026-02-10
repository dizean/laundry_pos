import 'package:flutter/material.dart';
import 'package:laundry_pos/styles.dart';

class SelectedPackagesCard extends StatelessWidget {
  final List<Map<String, dynamic>> selectedPackages;
  final Function(String packageId, int newQuantity) onUpdateQuantity;

  const SelectedPackagesCard({
    super.key,
    required this.selectedPackages,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Selected Packages',
                style: AppTextStyles.sectionTitle,
              ),
            ),
          ),
          const Divider(),

          if (selectedPackages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No packages selected'),
            ),

          ...selectedPackages.map(
            (p) => ListTile(
              title: Text(
                p['name'],
                style: AppTextStyles.itemTitle,
              ),
              subtitle: Text(
                '₱${p['price']} each',
                style: AppTextStyles.priceText,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: p['quantity'] > 1
                        ? () => onUpdateQuantity(
                              p['id'],
                              p['quantity'] - 1,
                            )
                        : null,
                  ),
                  Text(
                    p['quantity'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => onUpdateQuantity(
                      p['id'],
                      p['quantity'] + 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}