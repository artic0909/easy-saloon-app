import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_drawer.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_bottom_nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'total_customers': 0,
    'total_bookings': 0,
    'monthly_revenue': 0,
    'total_transactions': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/admin/dashboard');
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _stats = response.data['data'] ?? _stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

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
      body: RefreshIndicator(
        onRefresh: _fetchDashboardStats,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Playfair Display',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildGlassStatCard(
                        _stats['total_customers'].toString(),
                        "Total Customers",
                        Icons.people_outline,
                        Colors.blue,
                      ),
                      _buildGlassStatCard(
                        _stats['total_bookings'].toString(),
                        "Total Bookings",
                        Icons.event_note,
                        Colors.orange,
                      ),
                      _buildGlassStatCard(
                        "₹${_stats['monthly_revenue']}",
                        "Monthly Revenue",
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                      _buildGlassStatCard(
                        _stats['total_transactions'].toString(),
                        "Total Transactions",
                        Icons.receipt_long,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
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

  Widget _buildGlassStatCard(String value, String label, IconData icon, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}