import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          
          // Form
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'START YOUR JOURNEY WITH US',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 30.h),
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'FULL NAME',
                            hintText: 'John Doe',
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'EMAIL ADDRESS',
                            hintText: 'name@example.com',
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'PASSWORD',
                            hintText: '********',
                            suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'CONFIRM PASSWORD',
                            hintText: '********',
                            suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (val) => setState(() => _agreeToTerms = val!),
                              activeColor: AppColors.primary,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            Expanded(
                              child: Text(
                                "I AGREE TO THE TERMS OF SERVICE",
                                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              Get.snackbar(
                                "Success", 
                                "Account created successfully!",
                                backgroundColor: AppColors.primary.withOpacity(0.8),
                                colorText: Colors.white,
                              );
                            },
                            child: const Text('CREATE ACCOUNT →'),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                              children: [
                                TextSpan(
                                  text: "SIGN IN INSTEAD",
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
        ],
      ),
    );
  }
}
