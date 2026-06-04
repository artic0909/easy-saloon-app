import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_drawer.dart';
import 'package:dio/dio.dart' as dio_pkg;

class AdminManageStaffScreen extends StatefulWidget {
  const AdminManageStaffScreen({super.key});

  @override
  State<AdminManageStaffScreen> createState() => _AdminManageStaffScreenState();
}

class _AdminManageStaffScreenState extends State<AdminManageStaffScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<dynamic> _staffList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchStaffs();
  }

  Future<void> _fetchStaffs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/admin/staffs', queryParameters: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      });
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _staffList = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Failed to load staff list",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> _deleteStaff(dynamic staff) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Staff", style: TextStyle(color: Colors.redAccent, fontFamily: 'Playfair Display')),
        content: Text("Are you sure you want to remove ${staff['name']}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Get.back(result: true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        barrierDismissible: false,
      );
      
      try {
        final response = await _apiService.dio.post('/admin/staffs/${staff['id']}', data: {'_method': 'DELETE'});
        Get.back(); // close loading
        
        if (response.data['status'] == 'success') {
          Get.snackbar("Success", "Staff removed successfully", backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
          _fetchStaffs();
        }
      } catch (e) {
        Get.back(); // close loading
        String message = "Failed to remove staff";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar("Error", message, backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
      }
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
        title: Text(
          "Manage Staffs",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            onPressed: () async {
              await Get.toNamed('/admin-add-edit-staff');
              _fetchStaffs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStaffs,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _staffList.isEmpty
                      ? _buildEmptyState()
                      : _buildStaffsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Get.toNamed('/admin-add-edit-staff');
          _fetchStaffs();
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (val) {
          setState(() => _searchQuery = val);
          _fetchStaffs();
        },
        decoration: InputDecoration(
          hintText: "Search staffs by name, email, phone...",
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white30),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h).copyWith(bottom: 80.h),
      itemCount: _staffList.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final staff = _staffList[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(dynamic staff) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        staff['name']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                        style: TextStyle(color: AppColors.primary, fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff['name'] ?? 'Staff Name',
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            staff['designation'] ?? 'Stylist',
                            style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.white38, size: 14.w),
              SizedBox(width: 6.w),
              Expanded(child: Text(staff['email'] ?? 'No email', style: TextStyle(color: Colors.white70, fontSize: 12.sp))),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.phone_outlined, color: Colors.white38, size: 14.w),
              SizedBox(width: 6.w),
              Text(staff['phone'] ?? 'No phone', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
              SizedBox(width: 16.w),
              Icon(Icons.work_history_outlined, color: Colors.white38, size: 14.w),
              SizedBox(width: 6.w),
              Text("${staff['experience_years'] ?? 0} Yrs", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 14.w),
              SizedBox(width: 4.w),
              Text(
                "${double.tryParse(staff['staff_rating']?.toString() ?? '0')?.toStringAsFixed(1) ?? '0.0'} (${staff['staff_rating_count'] ?? 0} reviews)",
                style: TextStyle(color: Colors.amber, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                    icon: Icon(Icons.edit, color: Colors.blueAccent, size: 20.w),
                    onPressed: () async {
                      await Get.toNamed('/admin-add-edit-staff', arguments: staff);
                      _fetchStaffs();
                    },
                    tooltip: "Edit Staff",
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20.w),
                    onPressed: () => _deleteStaff(staff),
                    tooltip: "Remove Staff",
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(32.w),
        children: [
          Icon(Icons.badge_outlined, size: 64.w, color: Colors.white24),
          SizedBox(height: 16.h),
          Text(
            "No Staff Found",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "Click the + button to add a new staff member.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
