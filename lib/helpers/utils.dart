// lib/helpers/utils.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
export 'session.dart';
export 'functions.dart';
String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String formatCurrency(num value) {
  return '₱${value.toStringAsFixed(2)}';
}
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
enum TransactionStatus { all, pending, ongoing, done }

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.ongoing:
        return 'Ongoing';
      case TransactionStatus.done:
        return 'Done';
      case TransactionStatus.all:
        return 'All';
    }
  }

  String? get value {
    switch (this) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.ongoing:
        return 'ongoing';
      case TransactionStatus.done:
        return 'done';
      case TransactionStatus.all:
        return null;
    }
  }

  /// Optional: Convert string from database to enum
  static TransactionStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return TransactionStatus.pending;
      case 'ongoing':
        return TransactionStatus.ongoing;
      case 'done':
        return TransactionStatus.done;
      default:
        return TransactionStatus.all;
    }
  }
}