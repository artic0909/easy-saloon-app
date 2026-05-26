import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_drawer.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<dynamic> _coupons = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/admin/coupons', queryParameters: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      });
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _coupons = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Failed to load offers",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> _deleteCoupon(dynamic coupon) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Offer", style: TextStyle(color: Colors.redAccent, fontFamily: 'Playfair Display')),
        content: Text("Are you sure you want to delete ${coupon['code']}?", style: const TextStyle(color: Colors.white70)),
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
        final response = await _apiService.dio.post('/admin/coupons/${coupon['id']}', data: {'_method': 'DELETE'});
        Get.back(); // close loading
        
        if (response.data['status'] == 'success') {
          Get.snackbar("Success", "Offer deleted successfully", backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
          _fetchCoupons();
        }
      } catch (e) {
        Get.back(); // close loading
        String message = "Failed to delete offer";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar("Error", message, backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No expiry';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
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
          "Manage Offers",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () async {
              await Get.toNamed('/admin-add-edit-offer');
              _fetchCoupons();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCoupons,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _coupons.isEmpty
                      ? _buildEmptyState()
                      : _buildCouponsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Get.toNamed('/admin-add-edit-offer');
          _fetchCoupons();
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
          _fetchCoupons();
        },
        decoration: InputDecoration(
          hintText: "Search offers...",
          hintStyle: const TextStyle(color: Colors.white30),
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

  Widget _buildCouponsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h).copyWith(bottom: 80.h),
      itemCount: _coupons.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final coupon = _coupons[index];
        return _buildCouponCard(coupon);
      },
    );
  }

  Widget _buildCouponCard(dynamic coupon) {
    final discountStr = coupon['discount_type'] == 'percentage'
        ? "${coupon['discount_value']}% OFF"
        : "₹${coupon['discount_value']} OFF";
    
    final isActive = coupon['is_active'] == 1 || coupon['is_active'] == true;

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
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  coupon['code'].toString().toUpperCase(),
                  style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  isActive ? "ACTIVE" : "INACTIVE",
                  style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            coupon['title'] ?? 'Special Offer',
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.local_offer, color: AppColors.primary, size: 14.w),
              SizedBox(width: 6.w),
              Text(discountStr, style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.bold)),
              SizedBox(width: 16.w),
              Icon(Icons.event, color: Colors.white30, size: 14.w),
              SizedBox(width: 6.w),
              Text(_formatDate(coupon['expiry_date']), style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
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
                  await Get.toNamed('/admin-add-edit-offer', arguments: coupon);
                  _fetchCoupons();
                },
                tooltip: "Edit Offer",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20.w),
                onPressed: () => _deleteCoupon(coupon),
                tooltip: "Delete Offer",
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
          Icon(Icons.local_offer_outlined, size: 64.w, color: Colors.white24),
          SizedBox(height: 16.h),
          Text(
            "No Offers Found",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "Click the + button to create a new coupon.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
