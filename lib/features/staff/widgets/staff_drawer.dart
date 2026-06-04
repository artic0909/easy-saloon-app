import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class StaffDrawer extends StatelessWidget {
  const StaffDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final userName = authService.userData['name'] ?? 'Staff';

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
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Staff Member",
                  style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                _buildDrawerItem(
                  Icons.lock_open, 
                  "Open Bookings", 
                  () {
                    Get.back();
                    Get.toNamed('/staff-bookings-upcoming');
                  },
                ),
                _buildDrawerItem(
                  Icons.today, 
                  "My Today's Bookings", 
                  () {
                    Get.back();
                    Get.toNamed('/staff-bookings-today');
                  },
                ),
                _buildDrawerItem(
                  Icons.pending_actions, 
                  "Pending Bookings", 
                  () {
                    Get.back();
                    Get.toNamed('/staff-bookings-pending');
                  },
                ),
                _buildDrawerItem(
                  Icons.cancel_outlined, 
                  "Canceled Bookings", 
                  () {
                    Get.back();
                    Get.toNamed('/staff-bookings-cancel');
                  },
                ),
                _buildDrawerItem(
                  Icons.check_circle_outline, 
                  "Complete Bookings", 
                  () {
                    Get.back();
                    Get.toNamed('/staff-bookings-complete');
                  },
                ),
                const Divider(color: Colors.white10),
                _buildDrawerItem(Icons.settings_outlined, "Settings", () {
                  Get.back();
                  Get.toNamed('/staff-settings');
                }),
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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      onTap: onTap,
    );
  }
}
