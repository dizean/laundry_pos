double calculateTotal(List<Map<String, dynamic>> items, {bool isRush = false, double rushFee = 50}) {
  final baseTotal = items.fold(
    0.0,
    (sum, item) => sum + (item['price'] as num).toDouble() * (item['quantity'] as int),
  );
  return baseTotal + (isRush ? rushFee : 0);
}

double calculateBalance(double total, double cashGiven) {
  final balance = total - cashGiven;
  return balance < 0 ? 0 : balance;
}