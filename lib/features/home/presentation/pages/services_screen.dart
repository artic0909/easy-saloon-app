import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _services = [];
  List<dynamic> _categories = [];
  List<dynamic> _allSubcategories = [];
  List<dynamic> _filteredSubcategories = [];
  
  bool _isLoading = true;
  String _searchQuery = "";
  dynamic _selectedCategoryId;
  dynamic _selectedSubCategoryId;
  double _maxPrice = 10000;
  double _currentPriceRange = 10000;
  String _sortBy = "newest";

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null && Get.arguments is Map) {
      _selectedCategoryId = Get.arguments['category_id'];
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
          _allSubcategories = response.data['data']['subcategories'] ?? [];
          double apiMaxPrice = double.tryParse(response.data['data']['max_price'].toString()) ?? 10000;
          _maxPrice = apiMaxPrice > 0 ? apiMaxPrice : 10000;
          if (_currentPriceRange >= 10000) _currentPriceRange = _maxPrice;
          
          if (_selectedCategoryId != null) {
            _updateFilteredSubcategories(_selectedCategoryId);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching filters: $e");
    }
  }

  void _updateFilteredSubcategories(dynamic categoryId) {
    if (categoryId == null) {
      _filteredSubcategories = [];
    } else {
      _filteredSubcategories = _allSubcategories.where((sub) => sub['category_id'] == categoryId).toList();
    }
  }

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> params = {
        'search': _searchQuery,
        'sort': _sortBy,
        'max_price': _currentPriceRange,
      };
      
      if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId;
      if (_selectedSubCategoryId != null) params['subcategory_id'] = _selectedSubCategoryId;

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Our Services",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
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
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                            _selectedCategoryId = null;
                            _selectedSubCategoryId = null;
                            _filteredSubcategories = [];
                            _currentPriceRange = _maxPrice;
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
                  
                  // Category Header
                  _buildFilterHeader("CATEGORIES"),
                  SizedBox(height: 16.h),
                  
                  // Categories List
                  Column(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat['id'];
                      return _buildFilterItem(
                        cat['name'] ?? '',
                        isSelected,
                        () {
                          setModalState(() {
                            if (isSelected) {
                              _selectedCategoryId = null;
                              _selectedSubCategoryId = null;
                              _filteredSubcategories = [];
                            } else {
                              _selectedCategoryId = cat['id'];
                              _selectedSubCategoryId = null;
                              _updateFilteredSubcategories(cat['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  // Sub Category Section (Only if category has subcategories)
                  if (_selectedCategoryId != null && _filteredSubcategories.isNotEmpty) ...[
                    SizedBox(height: 32.h),
                    _buildFilterHeader("SUB CATEGORIES"),
                    SizedBox(height: 16.h),
                    Column(
                      children: _filteredSubcategories.map((sub) {
                        final isSelected = _selectedSubCategoryId == sub['id'];
                        return _buildFilterItem(
                          sub['name'] ?? '',
                          isSelected,
                          () => setModalState(() => _selectedSubCategoryId = isSelected ? null : sub['id']),
                        );
                      }).toList(),
                    ),
                  ],

                  SizedBox(height: 32.h),

                  // Price Range
                  _buildFilterHeader("MAX PRICE"),
                  SizedBox(height: 16.h),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _currentPriceRange.clamp(0, _maxPrice),
                      min: 0,
                      max: _maxPrice > 0 ? _maxPrice : 1,
                      onChanged: (val) => setModalState(() => _currentPriceRange = val),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("₹0", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("₹${_currentPriceRange.toInt()}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                        ),
                        Text("₹${_maxPrice.toInt()}+", style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                      ],
                    ),
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
