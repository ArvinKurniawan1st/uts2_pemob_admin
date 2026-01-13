import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'login_admin.dart';
import 'order_admin_page.dart';
import 'product_admin_page.dart';
import 'user_admin_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  int _selectedIndex = 0;
  String _revenueFilter = 'Semua';
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Dashboard Admin", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {})
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const LoginAdmin())
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          const OrderAdminPage(),
          const ProductAdminPage(),
          const UserAdminPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return FutureBuilder(
      future: Future.wait([
        ApiService.getOrders(),
        ApiService.getUsers(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final orders = snapshot.data != null ? snapshot.data![0] as List<Order> : <Order>[];
        final allUsers = snapshot.data != null ? snapshot.data![1] as List<User> : <User>[];

        final clientCount = allUsers.where((u) => u.role == 'CLIENT').length;

        final now = DateTime.now();
        final filteredOrders = orders.where((o) {
          if (o.status != 'APPROVED') return false;
          try {
            DateTime orderDate = DateTime.parse(o.createdAt).toLocal();
            if (_revenueFilter == 'Hari Ini') {
              return orderDate.year == now.year && orderDate.month == now.month && orderDate.day == now.day;
            } else if (_revenueFilter == 'Bulan Ini') {
              return orderDate.year == now.year && orderDate.month == now.month;
            } else if (_revenueFilter == 'Tahun Ini') {
              return orderDate.year == now.year;
            }
          } catch (e) {
            return false;
          }
          return true;
        }).toList();

        final totalRevenue = filteredOrders.fold(0.0, (sum, item) => sum + item.total);

        final pending = orders.where((o) => o.status == 'PENDING').length;
        final approved = orders.where((o) => o.status == 'APPROVED').length;
        final rejected = orders.where((o) => o.status == 'REJECTED').length;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ringkasan Bisnis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statCard("Total Client", clientCount.toString(), Colors.blue, Icons.people),
                    const SizedBox(width: 12),
                    _statCard("Total Order", orders.length.toString(), Colors.orange, Icons.shopping_cart),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Filter Pendapatan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _revenueFilter,
                          onChanged: (String? newValue) {
                            setState(() { _revenueFilter = newValue!; });
                          },
                          items: <String>['Semua', 'Hari Ini', 'Bulan Ini', 'Tahun Ini']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statCard(
                    "Pendapatan (${_revenueFilter})",
                    currencyFormatter.format(totalRevenue),
                    Colors.green,
                    Icons.monetization_on,
                    fullWidth: true
                ),

                const SizedBox(height: 32),
                const Text("Status Pesanan (Total)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),

                if (orders.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data order")))
                else ...[
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                              value: pending == 0 && approved == 0 && rejected == 0 ? 1 : pending.toDouble(),
                              title: '$pending', color: Colors.orange, radius: 50,
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          PieChartSectionData(
                              value: approved.toDouble(), title: '$approved', color: Colors.green, radius: 50,
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          PieChartSectionData(
                              value: rejected.toDouble(), title: '$rejected', color: Colors.red, radius: 50,
                              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem("Pending", Colors.orange),
                      const SizedBox(width: 15),
                      _legendItem("Approved", Colors.green),
                      const SizedBox(width: 15),
                      _legendItem("Rejected", Colors.red),
                    ],
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon, {bool fullWidth = false}) {
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}