import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easysaloonapp/core/network/api_service.dart';

class AuthService extends GetxService {
  final ApiService _apiService = ApiService();
  
  final RxBool _isLoggedIn = false.obs;
  final RxMap<String, dynamic> _userData = <String, dynamic>{}.obs;

  bool get isLoggedIn => _isLoggedIn.value;
  Map<String, dynamic> get userData => _userData;

  Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userJson = prefs.getString('user_data');
    
    if (token != null) {
      _isLoggedIn.value = true;
      if (userJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(userJson);
          _userData.assignAll(decoded);
        } catch (e) {
          // Fallback if JSON is malformed
        }
      }
      
      // Silently refresh profile in background
      _refreshProfile();
    }
    return this;
  }

  Future<void> _refreshProfile() async {
    try {
      final response = await _apiService.dio.get('/profile');
      if (response.data['status'] == 'success') {
        final Map<String, dynamic> user = response.data['data'];
        _userData.assignAll(user);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        logout(); 
      }
    }
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
        final user = Map<String, dynamic>.from(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('user_data', jsonEncode(user));
        
        _userData.assignAll(user);
        _isLoggedIn.value = true;
        
        return {'success': true, 'role': user['role']};
      }
      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      String message = 'Connection error';
      Map<String, dynamic>? errors;
      
      if (e.response?.data != null) {
        message = e.response?.data['message'] ?? message;
        errors = e.response?.data['errors'];
      }
      
      return {
        'success': false, 
        'message': message,
        'errors': errors,
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
        final data = response.data['data'];
        if (data != null && data['access_token'] != null) {
          final token = data['access_token'];
          final user = Map<String, dynamic>.from(data['user']);
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setString('user_data', jsonEncode(user));
          
          _userData.assignAll(user);
          _isLoggedIn.value = true;
          return {'success': true, 'auto_logged_in': true, 'role': user['role']};
        }
        return {'success': true, 'auto_logged_in': false};
      }
      return {'success': false, 'message': response.data['message']};
    } on DioException catch (e) {
      String message = 'Registration failed';
      Map<String, dynamic>? errors;

      if (e.response?.data != null) {
        message = e.response?.data['message'] ?? message;
        errors = e.response?.data['errors'];
      }

      return {
        'success': false, 
        'message': message,
        'errors': errors,
      };
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/logout');
    } catch (_) {}
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
    _isLoggedIn.value = false;
    _userData.clear();
    Get.offAllNamed('/login');
  }
}
