import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_drawer.dart';
import 'controllers/admin_package_controller.dart';
import 'models/package_model.dart';
import 'package_add_edit.dart';

class PackageListScreen extends StatelessWidget {
  PackageListScreen({super.key});

  final AdminPackageController controller = Get.put(AdminPackageController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Manage Packages",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            onPressed: () => Get.to(() => const PackageAddEditScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingPackages.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
                SizedBox(height: 16.h),
                Text(
                  "No packages found",
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const PackageAddEditScreen()),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text("Add Package", style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(24.w),
          itemCount: controller.packages.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final package = controller.packages[index];
            return _buildPackageCard(context, package);
          },
        );
      }),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 3, // Packages
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.offAllNamed('/admin-dashboard');
          } else if (index == 1) {
            Get.toNamed('/admin-bookings-open');
          } else if (index == 2) {
            Get.toNamed('/admin-manage-services');
          } else if (index == 3) {
            Get.toNamed('/admin-manage-packages');
          }
        },
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, PackageModel package) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (package.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                package.image!,
                height: 140.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140.h,
                  color: Colors.white10,
                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        package.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: package.isActive == 1 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        package.isActive == 1 ? "Active" : "Inactive",
                        style: TextStyle(
                          color: package.isActive == 1 ? Colors.green : Colors.red,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (package.originalPrice > package.salePrice)
                      Text(
                        "₹${package.originalPrice}",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12.sp,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (package.originalPrice > package.salePrice)
                      SizedBox(width: 8.w),
                    Text(
                      "₹${package.salePrice}",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "Includes ${package.items.length} services",
                  style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => Get.to(() => PackageAddEditScreen(package: package)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, package),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Package", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete ${package.name}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.deletePackage(package.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
