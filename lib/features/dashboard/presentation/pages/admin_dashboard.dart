import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: () => authService.logout(),
            icon: const Icon(Icons.logout, color: AppColors.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildMiniStat("Total Users", "1,240")),
                SizedBox(width: 16.w),
                Expanded(child: _buildMiniStat("Revenue", "\$12.4k")),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildMiniStat("Staff Active", "24")),
                SizedBox(width: 16.w),
                Expanded(child: _buildMiniStat("Bookings", "450")),
              ],
            ),
            SizedBox(height: 32.h),
            Text("Business Overview", style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16.h),
            Container(
              height: 200.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: const Center(
                child: Icon(Icons.bar_chart, color: AppColors.primary, size: 100),
              ),
            ),
            SizedBox(height: 32.h),
            Text("Recent Activities", style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16.h),
            ...List.generate(3, (index) => _buildActivityItem(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(color: AppColors.primary, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.grey),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "New booking confirmed by User ${index + 1}",
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),
          Text("2m ago", style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
        ],
      ),
    );
  }
}
