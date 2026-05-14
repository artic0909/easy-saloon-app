import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final userName = authService.userData['name'] ?? 'User';

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 60.h, left: 24.w, right: 24.w, bottom: 24.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Hey, $userName",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Welcome back to luxury",
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                _buildDrawerItem(Icons.person_outline, "My Profile"),
                _buildDrawerItem(Icons.grid_view, "Categories"),
                _buildDrawerItem(Icons.spa_outlined, "Services"),
                _buildDrawerItem(Icons.inventory_2_outlined, "Packages"),
                _buildDrawerItem(Icons.auto_awesome_outlined, "Make own Package"),
                _buildDrawerItem(Icons.calendar_today_outlined, "My Bookings"),
                const Divider(color: Colors.white10),
                _buildDrawerItem(Icons.gavel_outlined, "Legal"),
                _buildDrawerItem(Icons.help_outline, "Help"),
                SizedBox(height: 20.h),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                  onTap: () => authService.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      onTap: () => Get.back(),
    );
  }
}
