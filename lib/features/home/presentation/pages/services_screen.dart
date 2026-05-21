import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<dynamic> _services = [];
  List<dynamic> _categories = [];
  
  bool _isLoading = true;
  String _searchQuery = "";
  List<dynamic> _selectedCategoryIds = [];
  String _sortBy = "newest";

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null && Get.arguments is Map) {
      final catId = Get.arguments['category_id'];
      if (catId != null) {
        _selectedCategoryIds = [catId];
      }
    }
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchFilters(),
      _fetchServices(),
    ]);
  }

  Future<void> _fetchFilters() async {
    try {
      final response = await _apiService.dio.get('/services/filters');
      if (response.data['status'] == 'success') {
        setState(() {
          _categories = response.data['data']['categories'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching filters: $e");
    }
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> params = {
        'search': _searchQuery,
        'sort': _sortBy,
      };
      
      if (_selectedCategoryIds.isNotEmpty) {
        params['category_id'] = _selectedCategoryIds.join(',');
      }

      final response = await _apiService.dio.get('/services', queryParameters: params);
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _services = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error fetching services: $e");
    }
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
          "Our Services",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _services.isEmpty
                    ? _buildEmptyState()
                    : _buildServicesList(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.offAllNamed('/home');
          } else if (index == 1) {
            Get.offNamed('/my-bookings');
          } else if (index == 2) {
            Get.offNamed('/packages');
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            _searchQuery = val;
            _fetchServices();
          },
          decoration: InputDecoration(
            hintText: "Search for a service...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      itemCount: _services.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(dynamic service) {
    return InkWell(
      onTap: () => Get.toNamed('/service-detail', arguments: {'id': service['id']}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: Image.network(
                service['image'] ?? 'https://images.unsplash.com/photo-1560869713-7d0a294308b3?q=80&w=200&auto=format&fit=crop',
                width: 100.w,
                height: 100.w,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? '',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      service['short_description'] ?? 'Premium salon service',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${service['sale_price']}",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Book Now",
                            style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.content_cut, size: 64, color: Colors.white10),
          SizedBox(height: 16.h),
          Text("No services found", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.all(24.w),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filters",
                        style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIds = [];
                            _sortBy = "newest";
                          });
                          _fetchServices();
                          Get.back();
                        },
                        child: Text(
                          "RESET",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  
                  _buildFilterHeader("CATEGORIES"),
                  SizedBox(height: 16.h),
                  
                  Column(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategoryIds.map((id) => id.toString()).contains(cat['id'].toString());
                      return _buildFilterItem(
                        cat['name'] ?? '',
                        isSelected,
                        () {
                          setModalState(() {
                            if (isSelected) {
                              _selectedCategoryIds.removeWhere((id) => id.toString() == cat['id'].toString());
                            } else {
                              _selectedCategoryIds.add(cat['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 40.h),

                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); 
                        _fetchServices();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
        }
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFilterHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white38,
        fontSize: 11.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFilterItem(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.white24, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
