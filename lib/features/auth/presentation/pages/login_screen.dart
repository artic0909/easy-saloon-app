import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/presentation/pages/register_screen.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';
import 'package:easysaloonapp/core/widgets/salon_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  Map<String, String> _fieldErrors = {};

  void _handleLogin() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final result = await _authService.login(
      _loginController.text, 
      _passwordController.text
    );

    if (result['success']) {
      _showSuccessOverlay();
      
      await Future.delayed(const Duration(seconds: 2));
      
      String role = result['role'];
      if (role == 'admin') {
        Get.offAllNamed('/admin-dashboard');
      } else if (role == 'staff') {
        Get.offAllNamed('/staff-dashboard');
      } else {
        Get.offAllNamed('/home');
      }
    } else {
      setState(() => _isLoading = false);
      if (result['errors'] != null) {
        final errors = result['errors'] as Map<String, dynamic>;
        setState(() {
          _fieldErrors = errors.map((key, value) => MapEntry(key, value[0].toString()));
        });
      }
      _showErrorSnackbar(result['message']);
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "Wait a moment", 
      message,
      backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showSuccessOverlay() {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: const SalonLoader(
            size: 120,
            message: "Authentication Successful\nPreparing your dashboard",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login.avif'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(32.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome Back',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'EXPERIENCE THE LUXURY AGAIN',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 40.h),
                          _buildTextField(
                            controller: _loginController,
                            label: 'EMAIL OR PHONE',
                            hint: 'name@example.com',
                            errorKey: 'login',
                            validator: (v) => v!.isEmpty ? 'Required field' : null,
                          ),
                          SizedBox(height: 20.h),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'PASSWORD',
                            hint: '********',
                            errorKey: 'password',
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) => v!.isEmpty ? 'Password required' : null,
                          ),
                          SizedBox(height: 30.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              child: _isLoading 
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                                    )
                                  : const Text('SIGN IN →'),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                              ),
                              GestureDetector(
                                onTap: () => Get.to(() => const RegisterScreen()),
                                child: Text(
                                  "REGISTER",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: _fieldErrors[errorKey],
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            )
          : null,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
