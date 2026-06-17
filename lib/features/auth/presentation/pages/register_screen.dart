import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easysaloonapp/core/widgets/salon_loader.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0; // 0: phone, 1: otp, 2: password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, String> _fieldErrors = {};
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _authService = Get.find<AuthService>();

  void _handleSendOtp() async {
    setState(() => _fieldErrors = {}); 
    if (_phoneController.text.isEmpty) {
      setState(() => _fieldErrors['phone'] = 'Phone is required');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.sendOtp(_phoneController.text);
    setState(() => _isLoading = false);
    if (result['success']) {
      setState(() => _currentStep = 1);
    } else {
      _showErrorSnackbar(result['message'] ?? 'Failed to send OTP');
    }
  }

  void _handleVerifyOtp() async {
    setState(() => _fieldErrors = {}); 
    if (_otpController.text.isEmpty) {
      setState(() => _fieldErrors['otp'] = 'OTP is required');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.verifyOtp(_phoneController.text, _otpController.text);
    setState(() => _isLoading = false);
    if (result['success']) {
      setState(() => _currentStep = 2);
    } else {
      _showErrorSnackbar(result['message'] ?? 'Invalid OTP');
    }
  }

  void _handleRegister() async {
    setState(() => _fieldErrors = {}); 
    
    if (_passwordController.text.length < 8) {
      setState(() => _fieldErrors['password'] = 'Min 8 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _fieldErrors['password_confirmation'] = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.register(
      phone: _phoneController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccessDialog(result['role'] ?? 'user');
    } else {
      if (result['errors'] != null) {
        setState(() {
          final errors = result['errors'] as Map<String, dynamic>;
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

  void _showSuccessDialog(String role) {
    // Show the dialog immediately
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const SalonLoader(
            size: 140,
            message: "Account Created Successfully\nRedirecting to your luxury space",
          ),
        ),
      ),
    );

    // Perform location request and redirection in the background
    Future.delayed(const Duration(seconds: 3), () async {
      await _requestLocationPermission();
      
      if (role == 'admin') {
        Get.offAllNamed('/admin-dashboard');
      } else if (role == 'staff') {
        Get.offAllNamed('/staff-dashboard');
      } else {
        Get.offAllNamed('/home');
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      // Permission request failed or manifest missing permissions, 
      // but we shouldn't block the user from entering the app.
      debugPrint("Location permission error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/register.avif'),
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
                            'create_account'.tr,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'join_us'.tr.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 30.h),
                          if (_currentStep == 0) ...[
                            _buildTextField(
                              controller: _phoneController,
                              label: 'phone_number'.tr.toUpperCase(),
                              hint: '+91 98765 43210',
                              errorKey: 'phone',
                            ),
                            SizedBox(height: 24.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleSendOtp,
                                child: _isLoading 
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                                      )
                                    : const Text('SEND OTP →'),
                              ),
                            ),
                          ],
                          if (_currentStep == 1) ...[
                            Text(
                              'Enter the OTP sent to ${_phoneController.text}',
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            _buildTextField(
                              controller: _otpController,
                              label: 'OTP',
                              hint: '123456',
                              errorKey: 'otp',
                            ),
                            SizedBox(height: 24.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleVerifyOtp,
                                child: _isLoading 
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                                      )
                                    : const Text('VERIFY OTP →'),
                              ),
                            ),
                          ],
                          if (_currentStep == 2) ...[
                            _buildTextField(
                              controller: _passwordController,
                              label: 'password'.tr.toUpperCase(),
                              hint: '********',
                              errorKey: 'password',
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            SizedBox(height: 16.h),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'confirm_password'.tr.toUpperCase(),
                              hint: '********',
                              errorKey: 'password_confirmation',
                              isPassword: true,
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),

                            SizedBox(height: 24.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleRegister,
                                child: _isLoading 
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                                      )
                                    : Text('${'create_account'.tr.toUpperCase()} →'),
                              ),
                            ),
                          ],
                          SizedBox(height: 20.h),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: RichText(
                              text: TextSpan(
                                text: "${'already_have_account'.tr} ",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                                children: [
                                  TextSpan(
                                    text: 'login_here'.tr.toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
