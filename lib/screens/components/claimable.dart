import 'package:flutter/material.dart';
import 'package:laundry_pos/helpers/utils.dart';

class ClaimableDateTile extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const ClaimableDateTile({
    super.key,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text(
        'Claimable Date',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        date == null ? 'Tap to select date' : formatDate(date!),
        style: const TextStyle(fontSize: 20),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }
}