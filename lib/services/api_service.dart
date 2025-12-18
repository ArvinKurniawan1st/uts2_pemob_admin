import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/orders'));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getOrderItems(int orderId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/items'),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil order items');
    }

    return jsonDecode(res.body);
  }


  static Future<void> approveOrder(int id) async {
    await http.put(Uri.parse('$baseUrl/orders/$id/approve'));
  }

  static Future<void> rejectOrder(int id) async {
    await http.put(Uri.parse('$baseUrl/orders/$id/reject'));
  }
}
