import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final userName = authService.userData['name'] ?? 'Admin';

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 20.h, left: 24.w, right: 24.w, bottom: 24.h),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
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
                    "Administrator",
                    style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [
                  _buildDrawerItem(Icons.dashboard, "Dashboard", '/admin-dashboard', () {
                    Get.back();
                    Get.toNamed('/admin-dashboard');
                  }),
                  
                  _buildSectionTitle("Bookings"),
                  _buildDrawerItem(Icons.book_online, "Open Bookings", '/admin-bookings-open', () {
                    Get.back();
                    Get.toNamed('/admin-bookings-open');
                  }),
                  _buildDrawerItem(Icons.local_taxi, "On the Way Bookings", '/admin-bookings-ontheway', () {
                    Get.back();
                    Get.toNamed('/admin-bookings-ontheway');
                  }),
                  _buildDrawerItem(Icons.task_alt, "Complete Bookings", '/admin-bookings-complete', () {
                    Get.back();
                    Get.toNamed('/admin-bookings-complete');
                  }),
                  _buildDrawerItem(Icons.event_busy, "Cancel Bookings", '/admin-bookings-cancel', () {
                    Get.back();
                    Get.toNamed('/admin-bookings-cancel');
                  }),

                  _buildSectionTitle("Management"),
                  _buildDrawerItem(Icons.content_cut, "Manage Services", '/admin-manage-services', () {
                    Get.back();
                    Get.toNamed('/admin-manage-services');
                  }),
                  _buildDrawerItem(Icons.inventory_2, "Manage Packages", '/admin-manage-packages', () {
                    Get.back();
                    Get.toNamed('/admin-manage-packages');
                  }),
                  _buildDrawerItem(Icons.local_offer, "Manage Offers", '/admin-manage-offers', () {
                    Get.back();
                    Get.toNamed('/admin-manage-offers');
                  }),

                  _buildSectionTitle("Staff"),
                  _buildDrawerItem(Icons.badge, "Manage Staffs", '/admin-manage-staffs', () {
                    Get.back();
                    Get.toNamed('/admin-manage-staffs');
                  }),

                  const Divider(color: Colors.white10),
                  _buildDrawerItem(Icons.manage_accounts, "Account Settings", '/admin-settings', () {
                    Get.back();
                    Get.toNamed('/admin-settings');
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 16.h, bottom: 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white38,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String routeName, VoidCallback onTap) {
    bool isActive = Get.currentRoute == routeName;
    return Container(
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.primary : Colors.white54, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primary : Colors.white,
            fontSize: 14.sp,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
