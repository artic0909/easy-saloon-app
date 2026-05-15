import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/staff_drawer.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  Map<String, dynamic> _stats = {
    'total_bookings': '0',
    'pending_bookings': '0',
    'completed_bookings': '0',
    'todays_bookings': '0',
  };
  List<dynamic> _todayBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/staff/dashboard');
      if (response.data['status'] == 'success') {
        setState(() {
          _stats = Map<String, dynamic>.from(response.data['data']['stats']);
          _todayBookings = response.data['data']['today_bookings'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching staff dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardContent(),
      _buildPlaceholder("Staff Bookings"),
      _buildPlaceholder("Complete Services"),
      _buildPlaceholder("Earnings Report"),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const StaffDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentIndex == 0 ? "Staff Dashboard" : _getPageTitle(),
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            onPressed: _fetchDashboardData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppColors.primary,
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 1: return "My Bookings";
      case 2: return "Completed";
      case 3: return "Reports";
      default: return "Dashboard";
    }
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          SizedBox(height: 24.h),
          
          // Stats Grid - Increased childAspectRatio to fix overflow
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 16.w,
            childAspectRatio: 1.1, // Fixed from 1.4 to provide more vertical space
            children: [
              _buildGlassStatCard(_stats['total_bookings'].toString(), "Total Bookings", Icons.inventory_2_outlined, Colors.orange),
              _buildGlassStatCard(_stats['pending_bookings'].toString(), "Pending Tasks", Icons.access_time, Colors.blue),
              _buildGlassStatCard(_stats['completed_bookings'].toString(), "Completed", Icons.check_circle_outline, Colors.green),
              _buildGlassStatCard(_stats['todays_bookings'].toString(), "Today's Schedule", Icons.calendar_today_outlined, Colors.amber),
            ],
          ),
          
          SizedBox(height: 32.h),
          Text(
            "Today's Schedule",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
          ),
          SizedBox(height: 16.h),
          _buildTodayBookings(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final authService = Get.find<AuthService>();
    final name = authService.userData['name'] ?? 'Staff';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back,",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        Text(
          name,
          style: TextStyle(color: AppColors.primary, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
        ),
      ],
    );
  }

  Widget _buildGlassStatCard(String value, String label, IconData icon, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20.sp),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(color: Colors.white60, fontSize: 11.sp, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayBookings() {
    if (_todayBookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(40.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_month, color: Colors.white10, size: 48),
            SizedBox(height: 12.h),
            Text("No bookings for today", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(_todayBookings.length, (index) => _buildAppointmentItem(_todayBookings[index], index == _todayBookings.length - 1)),
      ),
    );
  }

  Widget _buildAppointmentItem(dynamic booking, bool isLast) {
    final clientName = booking['user']?['name'] ?? 'Guest';
    final services = (booking['items'] as List?)?.map((item) => item['service']?['name'] ?? '').join(', ') ?? 'Service';
    final time = booking['time_slot'] ?? 'TBD';
    final status = booking['status'] ?? 'pending';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                Text("$services • $time", style: TextStyle(color: Colors.white38, fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 9.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'confirmed': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex >= 4 ? 0 : _currentIndex,
      onTap: (index) {
        if (index == 4) {
          _scaffoldKey.currentState?.openDrawer();
        } else {
           setState(() => _currentIndex = index);
        }
      },
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white24,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10.sp,
      unselectedFontSize: 10.sp,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), activeIcon: Icon(Icons.event_note), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Complete'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), activeIcon: Icon(Icons.bar_chart), label: 'Report'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          SizedBox(height: 16.h),
          Text(title, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontFamily: 'Playfair Display')),
          Text("Module Under Development", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
