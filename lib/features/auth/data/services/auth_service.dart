import 'package:dio/dio.dart';
import 'package:get/get.dart' as get_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';

class AuthService extends get_pkg.GetxService {
  final ApiService _apiService = ApiService();
  
  final _isLoggedIn = false.obs;
  final _userData = {}.obs;

  bool get isLoggedIn => _isLoggedIn.value;
  Map get userData => _userData.value;

  Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _isLoggedIn.value = true;
      // You might want to fetch profile here to verify token
    }
    return this;
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    try {
      final response = await _apiService.dio.post('/login', data: {
        'login': login,
        'password': password,
      });

      if (response.data['status'] == 'success') {
        final data = response.data['data'];
        final token = data['access_token'];
        final user = data['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        
        _userData.value = user;
        _isLoggedIn.value = true;
        
        return {'success': true, 'role': user['role']};
      }
      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false, 
        'message': e.response?.data['message'] ?? 'Connection error'
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.dio.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      if (response.data['status'] == 'success') {
        return {'success': true};
      }
      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false, 
        'message': e.response?.data['message'] ?? 'Registration failed'
      };
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/logout');
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _isLoggedIn.value = false;
    _userData.value = {};
    get_pkg.Get.offAllNamed('/login');
  }
}
