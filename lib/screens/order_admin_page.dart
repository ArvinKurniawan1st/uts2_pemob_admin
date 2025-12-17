import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_admin.dart';

class OrderAdminPage extends StatefulWidget {
  const OrderAdminPage({super.key});

  @override
  State<OrderAdminPage> createState() => _OrderAdminPageState();
}

class _OrderAdminPageState extends State<OrderAdminPage> {
  late Future<List<dynamic>> orders;

  @override
  void initState() {
    super.initState();
    orders = ApiService.getOrders();
  }

  void refresh() {
    setState(() {
      orders = ApiService.getOrders();
    });
  }

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginAdmin()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: orders,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final order = data[i];
              return Card(
                child: ListTile(
                  title: Text('Order #${order['id']}'),
                  subtitle: Text(
                      'Total: Rp ${order['total']} | Status: ${order['status']}'),
                  trailing: order['status'] == 'PENDING'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await ApiService.approveOrder(order['id']);
                          refresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await ApiService.rejectOrder(order['id']);
                          refresh();
                        },
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
