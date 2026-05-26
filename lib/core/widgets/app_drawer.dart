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
    final currentRoute = Get.currentRoute;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Obx(() {
            final userData = authService.userData;
            final userName = userData['name'] ?? 'User';
            final photoUrl = userData['photo'];

            return Container(
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
                    backgroundImage: photoUrl != null
                        ? NetworkImage("https://test.sumatrasales.com/storage/$photoUrl")
                        : null,
                    child: photoUrl == null
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          )
                        : null,
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
            );
          }),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                _buildDrawerItem(Icons.person_outline, "My Profile", () {
                  Get.back();
                  Get.toNamed('/profile');
                }, isActive: currentRoute == '/profile'),
                // _buildDrawerItem(Icons.notifications_outlined, "Notifications", () {
                //   Get.back();
                //   Get.toNamed('/notifications');
                // }, isActive: currentRoute == '/notifications'),

                // _buildDrawerItem(Icons.grid_view_outlined, "Categories", () {
                //   Get.back();
                //   Get.toNamed('/categories');
                // }),
                _buildDrawerItem(Icons.content_cut, "Services", () {
                  Get.back();
                  Get.toNamed('/categories');
                }, isActive: currentRoute == '/categories'),
                _buildDrawerItem(Icons.card_giftcard, "Packages", () {
                  Get.back();
                  Get.toNamed('/packages');
                }, isActive: currentRoute == '/packages'),
                _buildDrawerItem(Icons.account_balance_wallet, "My Wallet", () {
                  Get.back();
                  Get.toNamed('/wallet');
                }, isActive: currentRoute == '/wallet'),
                _buildDrawerItem(Icons.auto_awesome, "Make own Package", () {
                  Get.back();
                  Get.toNamed('/custom-package');
                }, isActive: currentRoute == '/custom-package'),
                _buildDrawerItem(Icons.event_available, "My Bookings", () {
                  Get.back();
                  Get.toNamed('/my-bookings');
                }, isActive: currentRoute == '/my-bookings'),
                _buildDrawerItem(Icons.confirmation_number_outlined, "Coupons", () {
                  Get.back();
                  Get.toNamed('/coupons');
                }, isActive: currentRoute == '/coupons'),
                const Divider(color: Colors.white10),
                _buildDrawerItem(Icons.gavel, "Legal", () => Get.back()),
                // _buildDrawerItem(Icons.help_outline, "Help", () => Get.back()),
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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isActive = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? AppColors.primary.withValues(alpha: 0.15) : null,
        leading: Icon(icon, color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.8), size: 22),
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
