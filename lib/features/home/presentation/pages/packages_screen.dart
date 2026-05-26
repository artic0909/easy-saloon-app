import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<dynamic> _packages = [];
  List<dynamic> _filteredPackages = [];
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
          _filteredPackages = _packages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching packages: $e");
    }
  }

  void _filterPackages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPackages = _packages;
      } else {
        final lowQuery = query.toLowerCase();
        _filteredPackages = _packages.where((pkg) {
          final pkgName = (pkg['name'] ?? "").toString().toLowerCase();
          final pkgDetails = (pkg['details'] ?? "").toString().toLowerCase();
          final items = pkg['items'] as List<dynamic>? ?? [];
          final hasService = items.any((item) {
            final serviceName = (item['service']?['name'] ?? "").toString().toLowerCase();
            return serviceName.contains(lowQuery);
          });
          return pkgName.contains(lowQuery) || pkgDetails.contains(lowQuery) || hasService;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "All Packages",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredPackages.isEmpty
                    ? _buildEmptyState()
                    : _buildPackagesList(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.offAllNamed('/home');
          } else if (index == 1) {
            Get.offNamed('/my-bookings');
          } else if (index == 3) {
            Get.offNamed('/categories');
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: _filterPackages,
          decoration: InputDecoration(
            hintText: "Search packages or services...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildPackagesList() {
    return ListView.separated(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.h),
      itemCount: _filteredPackages.length,
      separatorBuilder: (_, __) => SizedBox(height: 24.h),
      itemBuilder: (context, index) {
        final package = _filteredPackages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(dynamic package) {
    final salePrice = package['sale_price'] ?? package['price'] ?? '0';
    final originalPrice = package['original_price'];

    return InkWell(
      onTap: () => Get.toNamed('/package-detail', arguments: {'id': package['id']}),
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (originalPrice != null && originalPrice.toString() != salePrice.toString())
                          Text(
                            "₹$originalPrice",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "₹$salePrice",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                        ),
                      ],
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
                    (package['details'] ?? package['description'] ?? 'Exclusive service bundle').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
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
                      onPressed: () => Get.toNamed('/package-detail', arguments: {'id': package['id']}), 
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
