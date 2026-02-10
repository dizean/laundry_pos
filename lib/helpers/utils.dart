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
