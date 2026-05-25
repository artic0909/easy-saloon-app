import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      final authService = Get.find<AuthService>();
      if (authService.isLoggedIn) {
        final role = authService.userData['role'];
        if (role == 'admin') {
          Get.offAllNamed('/admin-dashboard');
        } else if (role == 'staff') {
          Get.offAllNamed('/staff-dashboard');
        } else {
          Get.offAllNamed('/home');
        }
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.content_cut,
                  size: 60.sp,
                  color: AppColors.textOnPrimary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'EASY SALOON',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'DEFINED BY LUXURY, DRIVEN BY STYLE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.sp,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
