import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      // 🚀 FIXED: Explicitly declare the /v1/ prefix right here so it maps with the root domain perfectly
      final response = await _client.dio.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Invalid credentials or server connection error: $e");
    }
  }

  Future<Map<String, dynamic>> executeSignup({
    required bool isStaff,
    required String gymName,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      // 🚀 FIXED: Explicitly declare the /v1/ prefix right here
      final response = await _client.dio.post('/v1/auth/signup', data: {
        'is_staff': isStaff,
        'gym_name': isStaff ? "" : gymName,
        'name': ownerName,
        'phone': phone,
        'email': email,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Registration transaction failed: $e");
    }
  }
}