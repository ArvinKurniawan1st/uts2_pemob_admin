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

  void showOrderItems(BuildContext context, int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('Fetching items for order: $orderId'); // Debug
      final items = await ApiService.getOrderItems(orderId);
      print('Items received: $items'); // Debug

      Navigator.pop(context); // Tutup loading

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Detail Order #$orderId'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: items.isEmpty
                ? const Center(child: Text('Tidak ada item dalam order ini'))
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                print('Item $i: $item'); // Debug

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Quantity: ${item['quantity'] ?? 0}'),
                            Text(
                              'Rp ${item['price'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Subtotal: Rp ${(item['price'] ?? 0) * (item['quantity'] ?? 0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error fetching items: $e'); // Debug
      Navigator.pop(context); // Tutup loading

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Order'),
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) {
              final order = data[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text('Order #${order['id']}'),
                  subtitle: Text(
                    'Total: Rp ${order['total']} | Status: ${order['status']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Lihat Item
                      IconButton(
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Lihat Item',
                        onPressed: () {
                          showOrderItems(context, order['id']);
                        },
                      ),
                      // Tombol Approve dan Reject (hanya untuk PENDING)
                      if (order['status'] == 'PENDING') ...[
                        IconButton(
                          iconSize: 20,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: () async {
                            await ApiService.approveOrder(order['id']);
                            refresh();
                          },
                        ),
                        IconButton(
                          iconSize: 20,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () async {
                            await ApiService.rejectOrder(order['id']);
                            refresh();
                          },
                        ),
                      ],
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