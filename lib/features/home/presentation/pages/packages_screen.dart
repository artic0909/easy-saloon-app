import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/packages');
      if (response.data['status'] == 'success') {
        setState(() {
          _packages = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching packages: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Service Packages",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _packages.isEmpty
              ? _buildEmptyState()
              : _buildPackagesList(),
    );
  }

  Widget _buildPackagesList() {
    return ListView.separated(
      padding: EdgeInsets.all(24.w),
      itemCount: _packages.length,
      separatorBuilder: (_, __) => SizedBox(height: 24.h),
      itemBuilder: (context, index) {
        final package = _packages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(dynamic package) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: Stack(
              children: [
                Image.network(
                  package['image'] ?? 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?q=80&w=600&auto=format&fit=crop',
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 180.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "₹${package['price']}",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package['name'] ?? '',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
                ),
                SizedBox(height: 8.h),
                Text(
                  package['description'] ?? 'Exclusive service bundle',
                  style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16.h),
                const Divider(color: Colors.white10),
                SizedBox(height: 12.h),
                Text(
                  "INCLUDED SERVICES:",
                  style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                SizedBox(height: 8.h),
                _buildIncludedServices(package['items'] ?? []),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 45.h,
                  child: ElevatedButton(
                    onPressed: () {}, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Book Package", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedServices(List<dynamic> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...items.take(3).map((item) {
          final serviceName = (item['service'] != null) ? item['service']['name'] ?? 'Service' : 'Service';
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              serviceName,
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
            ),
          );
        }),
        if (items.length > 3)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              "+${items.length - 3} more",
              style: TextStyle(color: AppColors.primary, fontSize: 10.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white10),
          SizedBox(height: 16.h),
          Text("No packages available", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
        ],
      ),
    );
  }
}
