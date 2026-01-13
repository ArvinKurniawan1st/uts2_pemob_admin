import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String name;
  final String email;
  final String role;

  User({required this.id, required this.name, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CLIENT',
    );
  }
}

class Product {
  final int id;
  final String name;
  final double pricePerKg;
  final int stock;

  Product({required this.id, required this.name, required this.pricePerKg, required this.stock});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      pricePerKg: double.parse(json['price_per_kg'].toString()),
      stock: json['stock'] ?? 0,
    );
  }
}

class Order {
  final int id;
  final int userId;
  final double total;
  final String status;
  final String createdAt;

  Order({required this.id, required this.userId, required this.total, required this.status, required this.createdAt});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://192.168.1.14:3000/api';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login gagal');
    } catch (e) { throw Exception('Gagal menghubungi server: $e'); }
  }

  static Future<List<User>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        List jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((data) => User.fromJson(data)).toList();
      }
      throw Exception('Gagal memuat daftar pengguna: ${response.statusCode}');
    } catch (e) {
      throw Exception('Koneksi terputus: $e');
    }
  }

  static Future<User> getUserById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal memuat data user');
  }

  static Future<void> addUser(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (response.statusCode != 201) throw Exception('Gagal menambah user');
  }

  static Future<void> updateUser(int id, String name, String email, String role) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'role': role,
      }),
    );
    if (response.statusCode != 200) throw Exception('Gagal memperbarui user');
  }

  static Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode != 200) throw Exception('Gagal menghapus user');
  }

  static Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        List jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((data) => Order.fromJson(data)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getOrderItems(int orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$orderId/items'));
      if (response.statusCode == 200) {
        List<dynamic> items = jsonDecode(response.body);
        return items.map((item) {
          return {
            ...item,
            'price': double.tryParse(item['price'].toString()) ?? 0.0,
            'sub_total': double.tryParse(item['sub_total'].toString()) ?? 0.0,
            'shipping_cost': double.tryParse(item['shipping_cost'].toString()) ?? 0.0,
          };
        }).toList();
      }
      throw Exception('Gagal mengambil item');
    } catch (e) { throw Exception('Error: $e'); }
  }

  static Future<void> approveOrder(int id) async {
    final response = await http.put(Uri.parse('$baseUrl/orders/$id/approve'));
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Gagal approve');
    }
  }

  static Future<void> rejectOrder(int id) async {
    final response = await http.put(Uri.parse('$baseUrl/orders/$id/reject'));
    if (response.statusCode != 200) throw Exception('Gagal menolak order');
  }

  static Future<List<Product>> getProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'));
    if (res.statusCode == 200) {
      List jsonResponse = jsonDecode(res.body);
      return jsonResponse.map((data) => Product.fromJson(data)).toList();
    }
    return [];
  }

  static Future<void> addProduct(String name, double price, int stock) async {
    await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'price_per_kg': price, 'stock': stock}),
    );
  }

  static Future<void> updateProduct(int id, String name, double price, int stock) async {
    await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'price_per_kg': price, 'stock': stock}),
    );
  }

  static Future<void> deleteProduct(int id) async {
    await http.delete(Uri.parse('$baseUrl/products/$id'));
  }
}