import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    try {
      final response = await _apiService.dio.get('/coupons');
      if (response.data['status'] == 'success') {
        setState(() {
          _coupons = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching coupons: $e");
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      "Success", 
      "Code Copied: $code",
      backgroundColor: AppColors.primary,
      colorText: AppColors.textOnPrimary,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.copy_all, color: AppColors.textOnPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Available Coupons",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _coupons.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: EdgeInsets.all(24.w),
              itemCount: _coupons.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return _buildCouponCard(coupon);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.white10),
          SizedBox(height: 16.h),
          Text("No active coupons available", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildCouponCard(dynamic coupon) {
    return GestureDetector(
      onTap: () => _copyToClipboard(coupon['code']),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Discount Tag
              Container(
                width: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${coupon['discount_value']}${coupon['discount_type'] == 'percentage' ? '%' : ' OFF'}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "OFF",
                      style: TextStyle(color: AppColors.primary.withValues(alpha: 0.6), fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
              // Vertical Dashed Line
              Container(
                width: 1,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              // Coupon Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'] ?? 'Luxury Discount',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Code: ${coupon['code']}",
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
                      ),
                      if (coupon['expiry_date'] != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          "Expires: ${coupon['expiry_date']}",
                          style: TextStyle(color: Colors.white38, fontSize: 10.sp),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Copy Icon
              Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.copy_all, color: AppColors.primary.withValues(alpha: 0.5), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
