import 'package:flutter/material.dart';
import 'package:laundry_pos/service/main.dart';

class StaffManagementPage extends StatefulWidget {
  final Function(Widget) openPage;
  const StaffManagementPage({super.key, required this.openPage});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _staffService = StaffService();

  List<Map<String, dynamic>> _staffs = [];
  bool _loading = true;

  int _currentPage = 1;
  int _perPage = 10;

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
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final staffs = await _staffService.getPaginatedStaffs(
        limit: _perPage,
        offset: (page - 1) * _perPage,
      );

      if (!mounted) return;

      setState(() {
        _staffs = staffs;
        _currentPage = page;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: $e')),
      );
    } finally {
      if (!mounted) return;
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
                _staffs.clear(); // clear cache
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
      _staffs
      .clear(); // clear cache
      _loadStaff(page: _currentPage);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting staff: $e')));
    }
  }

  @override
  @override
Widget build(BuildContext context) {
  final hasNextPage = _staffs.length == _perPage;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Staff Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddEditDialog(),
        ),
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: DataTable(
                        columnSpacing: 30,
                        columns: const [
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _staffs.map((staff) {
                          return DataRow(
                            cells: [
                              DataCell(Text(staff['email'] ?? '')),
                              DataCell(Text(staff['role'] ?? 'staff')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showAddEditDialog(staff: staff),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteStaff(staff['id']),
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

              // ✅ FIXED PAGINATION DISPLAY
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _currentPage > 1
                          ? () =>
                              _loadStaff(page: _currentPage - 1)
                          : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 16),
                    Text('Page $_currentPage'),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: hasNextPage
                          ? () =>
                              _loadStaff(page: _currentPage + 1)
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
