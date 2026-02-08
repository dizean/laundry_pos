import 'package:flutter/material.dart';
import 'package:laundry_pos/service/staff.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();

  List<Map<String, dynamic>> _allStaff = [];
  List<Map<String, dynamic>> _staffList = [];
  bool _loading = true;

  int _currentPage = 1;
  final int _perPage = 10;
  int _totalStaff = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff({int page = 1}) async {
    setState(() => _loading = true);
    try {
      if (_allStaff.isEmpty) {
        final raw = await _staffService.getAllStaff();
        _allStaff = raw.map((s) {
          return {
            'id': s['id'].toString(),
            'email': s['email'] ?? '',
            'role': s['role'] ?? 'staff',
          };
        }).toList();
        _totalStaff = _allStaff.length;
      }

      // Pagination
      final from = (page - 1) * _perPage;
      final to = (from + _perPage).clamp(0, _allStaff.length);
      _staffList = _allStaff.sublist(from, to);
      _currentPage = page;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading staff: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? staff}) {
    if (staff != null) {
      _editingId = staff['id'];
      _emailController.text = staff['email'];
    } else {
      _editingId = null;
      _emailController.clear();
      _passwordController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(staff == null ? 'Add Staff' : 'Edit Staff'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              if (_editingId == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password required';
                    if (value.length < 6) return 'At least 6 chars';
                    return null;
                  },
                ),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              try {
                if (_editingId != null) {
                  await _staffService.updateStaff(
                    id: _editingId!,
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim().isEmpty
                        ? null
                        : _passwordController.text.trim(),
                  );
                } else {
                  await _staffService.createStaff(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                }

                Navigator.pop(context);
                _allStaff.clear(); // clear cache
                _loadStaff(page: _currentPage);
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(staff == null ? 'Add' : 'Save'),
          )
        ],
      ),
    );
  }

  Future<void> _deleteStaff(String id) async {
    try {
      await _staffService.deleteStaff(id);
      _allStaff.clear(); // clear cache
      _loadStaff(page: _currentPage);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting staff: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalStaff / _perPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditDialog()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: DataTable(
                          columnSpacing: 30,
                          columns: const [
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _staffList.map((staff) {
                            return DataRow(
                              cells: [
                                DataCell(Text(staff['email'] ?? '')),
                                DataCell(Text(staff['role'] ?? 'staff')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddEditDialog(staff: staff),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteStaff(staff['id']),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Pagination controls
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 1
                            ? () => _loadStaff(page: _currentPage - 1)
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Text('Page $_currentPage of $totalPages'),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _currentPage < totalPages
                            ? () => _loadStaff(page: _currentPage + 1)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
