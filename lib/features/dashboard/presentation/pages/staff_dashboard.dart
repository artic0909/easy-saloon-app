import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: () => authService.logout(),
            icon: const Icon(Icons.logout, color: AppColors.primary),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard("Today's Appointments", "12", Icons.calendar_today),
            SizedBox(height: 16.h),
            _buildStatCard("Completed", "8", Icons.check_circle_outline),
            SizedBox(height: 32.h),
            Text("Upcoming Services", style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: AppColors.primary),
                  title: Text("Client ${index + 1}", style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Hair Cutting - 10:00 AM", style: TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: AppColors.primary, size: 32.sp),
        ],
      ),
    );
  }
}
