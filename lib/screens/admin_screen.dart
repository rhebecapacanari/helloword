import 'package:flutter/material.dart';
import '../services/admin_service.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});


  @override
  State<AdminScreen> createState() => _AdminScreenState();
}


class _AdminScreenState extends State<AdminScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }


  Future<void> _loadPendingUsers() async {
    setState(() => _isLoading = true);
    try {
      _pendingUsers = await _adminService.getPendingUsers();
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprovação de Usuários')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingUsers.isEmpty
              ? const Center(child: Text('Nenhum usuário pendente'))
              : ListView.builder(
                itemCount: _pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = _pendingUsers[index];
                  return ListTile(
                    title: Text(user['name']),
                    subtitle: Text('${user['email']} - ${user['type']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await _adminService.approveUser(user['id'] as int);
                            await _loadPendingUsers();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await _adminService.rejectUser(user['id'] as int);
                            await _loadPendingUsers();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}



