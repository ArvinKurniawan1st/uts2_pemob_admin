import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class OrderAdminPage extends StatefulWidget {
  const OrderAdminPage({super.key});

  @override
  State<OrderAdminPage> createState() => _OrderAdminPageState();
}

class _OrderAdminPageState extends State<OrderAdminPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  Future<List<dynamic>> _fetchData() {
    return Future.wait([
      ApiService.getOrders(),
      ApiService.getUsers(),
    ]);
  }

  void refresh() => setState(() {});

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Icons.hourglass_empty;
      case 'APPROVED': return Icons.check_circle;
      case 'REJECTED': return Icons.cancel;
      default: return Icons.info;
    }
  }

  void showOrderItems(BuildContext context, int orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final items = await ApiService.getOrderItems(orderId);
      if (!context.mounted) return;
      Navigator.pop(context);

      final double shippingCost = items.isNotEmpty
          ? double.tryParse(items[0]['shipping_cost'].toString()) ?? 0.0
          : 0.0;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Detail Order #$orderId', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Flexible(
                  child: items.isEmpty
                      ? const Padding(padding: EdgeInsets.all(32), child: Text("Tidak ada item"))
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final double price = double.tryParse(item['price'].toString()) ?? 0.0;
                      final double subtotal = double.tryParse(item['sub_total'].toString()) ?? 0.0;
                      final int qty = int.tryParse(item['quantity'].toString()) ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? 'Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$qty x ${currencyFormatter.format(price)}'),
                                Text(currencyFormatter.format(subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // --- BAGIAN SHIPPING COST ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ongkos Kirim:", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      Text(currencyFormatter.format(shippingCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder(
        future: _fetchData(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final List<Order> allOrders = snapshot.data?[0] ?? [];
          final List<User> allUsers = snapshot.data?[1] ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: allOrders.length,
            itemBuilder: (context, index) {
              final order = allOrders[index];
              final statusColor = getStatusColor(order.status);
              final user = allUsers.firstWhere((u) => u.id == order.userId, orElse: () => User(id: 0, name: 'Unknown', email: '', role: ''));

              String dateStr = "Waktu tidak tersedia";
              try {
                if (order.createdAt.isNotEmpty) {
                  DateTime serverDate = DateTime.parse(order.createdAt).toLocal();
                  dateStr = dateFormatter.format(serverDate);
                }
              } catch (e) {
                print("Error format tanggal: $e");
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.blue.shade100, blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor, width: 1.5)),
                            child: Text(order.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #${order.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(currencyFormatter.format(order.total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showOrderItems(context, order.id),
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text("Item"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white),
                              ),
                              if (order.status == 'PENDING') ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      await ApiService.approveOrder(order.id);
                                      refresh();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Approve: $e")));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      await ApiService.rejectOrder(order.id);
                                      refresh();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal Reject: $e")));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ]
                            ],
                          )
                        ],
                      ),
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