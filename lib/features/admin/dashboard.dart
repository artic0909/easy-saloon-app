import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_drawer.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_bottom_nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Playfair Display',
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Welcome to the New Admin Setup",
          style: TextStyle(color: Colors.white54),
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 0, // Dashboard
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
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
}