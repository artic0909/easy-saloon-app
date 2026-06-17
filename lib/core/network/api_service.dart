import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easysaloonapp/core/localization/language_service.dart';

class ApiService {
  static const String baseUrl = 'https://test.sumatrasales.com/api';
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add interceptor for tokens
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          options.headers['Accept-Language'] =
              LanguageService.to.currentLanguage.value;
          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
