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

  // Palet warna biru elegan
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color deepBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFF42A5F5);
  final Color accentBlue = const Color(0xFF2196F3);
  final Color softBlue = const Color(0xFF64B5F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Dashboard Admin", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [deepBlue, primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          ],
        ),
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
          return Center(child: CircularProgressIndicator(color: primaryBlue));
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
          color: primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ringkasan Bisnis",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: deepBlue,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statCard("Total Client", clientCount.toString(), [const Color(0xFF5E35B1), const Color(0xFF4527A0)], Icons.people),
                    const SizedBox(width: 12),
                    _statCard("Total Order", orders.length.toString(), [const Color(0xFF1E88E5), const Color(0xFF1565C0)], Icons.shopping_cart),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filter Pendapatan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: deepBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: lightBlue.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _revenueFilter,
                          style: TextStyle(color: deepBlue, fontWeight: FontWeight.w500),
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
                    [const Color(0xFF00897B), const Color(0xFF00695C)],
                    Icons.monetization_on,
                    fullWidth: true
                ),

                const SizedBox(height: 32),
                Text(
                  "Status Pesanan (Total)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: deepBlue,
                  ),
                ),
                const SizedBox(height: 16),

                if (orders.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data order")))
                else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                    value: pending == 0 && approved == 0 && rejected == 0 ? 1 : pending.toDouble(),
                                    title: '$pending',
                                    color: const Color(0xFFFF9800),
                                    radius: 55,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                                PieChartSectionData(
                                    value: approved.toDouble(),
                                    title: '$approved',
                                    color: const Color(0xFF0288D1),
                                    radius: 55,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                                PieChartSectionData(
                                    value: rejected.toDouble(),
                                    title: '$rejected',
                                    color: const Color(0xFFE53935),
                                    radius: 55,
                                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendItem("Pending", const Color(0xFFFF9800)),
                            const SizedBox(width: 20),
                            _legendItem("Approved", const Color(0xFF0288D1)),
                            const SizedBox(width: 20),
                            _legendItem("Rejected", const Color(0xFFE53935)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, List<Color> gradientColors, IconData icon, {bool fullWidth = false}) {
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: deepBlue,
          ),
        ),
      ],
    );
  }
}