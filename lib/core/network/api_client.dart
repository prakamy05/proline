import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // 🚀 FIXED: Set baseUrl to the domain root ONLY. Let repositories explicitly manage their endpoint version layers.
  static const String baseUrl = "https://prolinebackend-production.up.railway.app"; 
  final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));
  final _secureStorage = const FlutterSecureStorage();

  ApiClient() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: "auth_token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }
}