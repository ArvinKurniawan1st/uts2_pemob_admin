import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserAdminPage extends StatefulWidget {
  const UserAdminPage({super.key});

  @override
  State<UserAdminPage> createState() => _UserAdminPageState();
}

class _UserAdminPageState extends State<UserAdminPage> {
  void _refreshData() => setState(() {});

  void _showUserForm({User? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    String selectedRole = user?.role ?? 'CLIENT';
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit User' : 'Tambah User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Role'),
                items: ['CLIENT', 'ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => selectedRole = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isEdit) {
                  await ApiService.updateUser(user.id, nameCtrl.text, emailCtrl.text, selectedRole);
                } else {
                  await ApiService.addUser(nameCtrl.text, emailCtrl.text, passCtrl.text, selectedRole);
                }
                Navigator.pop(context);
                _refreshData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus User"),
        content: Text("Yakin ingin menghapus ${user.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ApiService.deleteUser(user.id);
                Navigator.pop(context);
                _refreshData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: FutureBuilder<List<User>>(
        future: ApiService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              final isAdmin = u.role == 'ADMIN';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                    child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? Colors.red : Colors.blue),
                  ),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(u.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showUserForm(user: u)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(u)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}