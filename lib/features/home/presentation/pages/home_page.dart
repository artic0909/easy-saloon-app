import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/features/home/presentation/widgets/scratch_card_modal.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();

  List<dynamic> _banners = [];
  List<dynamic> _coupons = [];
  List<dynamic> _categories = [];
  List<dynamic> _filteredCategories = [];

  late PageController _pageController;
  Timer? _timer;
  int _activePage = 0;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchAllData();
    _checkScratchCardStatus();
    _searchController.addListener(_filterCategories);
  }

  Future<void> _checkScratchCardStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await _apiService.dio.get('/user/scratch-card-status');
      if (response.data['success'] == true) {
        final showCard = response.data['show_scratch_card'] ?? false;
        final totalBookings = response.data['total_confirmed_bookings'] ?? 0;

        if (showCard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) =>
                      ScratchCardModal(totalConfirmedBookings: totalBookings),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching scratch card status: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAllData() async {
    await Future.wait([_fetchBanners(), _fetchCoupons(), _fetchCategories()]);
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await _apiService.dio.get('/banners');
      if (response.data['status'] == 'success') {
        setState(() {
          _banners = response.data['data'];
        });
        if (_banners.isNotEmpty) _startAutoScroll();
      }
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    }
  }

  Future<void> _fetchCoupons() async {
    try {
      final response = await _apiService.dio.get('/coupons');
      if (response.data['status'] == 'success') {
        setState(() {
          _coupons = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching coupons: $e");
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _apiService.dio.get('/categories');
      if (response.data['status'] == 'success') {
        setState(() {
          _categories = response.data['data'];
          _filteredCategories = _categories;
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories =
          _categories.where((cat) {
            return cat['name'].toString().toLowerCase().contains(query);
          }).toList();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _banners.isNotEmpty) {
        if (_activePage < _banners.length - 1) {
          _activePage++;
        } else {
          _activePage = 0;
        }
        _pageController.animateToPage(
          _activePage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No Expiry';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      _buildPlaceholderContent('my_bookings'.tr),
      _buildPlaceholderContent('packages'.tr),
      _buildPlaceholderContent('services'.tr),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(),
        body: pages[_currentIndex],
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 4) {
              _scaffoldKey.currentState?.openDrawer();
            } else if (index == 3) {
              Get.toNamed('/categories');
            } else if (index == 2) {
              Get.toNamed('/packages');
            } else if (index == 1) {
              Get.toNamed('/my-bookings');
            } else {
              setState(() => _currentIndex = index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontFamily: 'Playfair Display',
            ),
          ),
          Text(
            'coming_soon'.tr,
            style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context),
              SizedBox(height: 32.h),
              if (_coupons.isNotEmpty) ...[
                _buildSectionHeader('exclusive_offers'.tr),
                SizedBox(height: 16.h),
                _buildCouponList(),
                SizedBox(height: 40.h),
              ],
              _buildSearchBar(),
              SizedBox(height: 32.h),
              _buildCategoryHeader(),
              SizedBox(height: 20.h),
              _buildCategoryContent(),
              SizedBox(height: 60.h),
            ],
          ),
        ),
        // Floating Notification Icon
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 20,
          child: GestureDetector(
            onTap: () => Get.toNamed('/notifications'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'search_services'.tr,
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponList() {
    return SizedBox(
      height: 140.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: _coupons.length,
        separatorBuilder: (_, __) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          return Container(
            width: 300.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.stars,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${coupon['discount_value']}${coupon['discount_type'] == 'percentage' ? '%' : ' OFF'}",
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            coupon['title'] ?? 'Discount Coupon',
                            style: TextStyle(
                              color: AppColors.textOnPrimary.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (coupon['expiry_date'] != null) ...[
                            SizedBox(height: 4.h),
                            Text(
                              "Expires: ${_formatDate(coupon['expiry_date'])}",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          coupon['code'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'services'.tr,
            style: TextStyle(
              fontSize: 22.sp,
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.grid_view,
                  color: _isGridView ? AppColors.primary : Colors.white24,
                ),
                onPressed: () => setState(() => _isGridView = true),
              ),
              IconButton(
                icon: Icon(
                  Icons.list,
                  color: !_isGridView ? AppColors.primary : Colors.white24,
                ),
                onPressed: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    if (_filteredCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40.h),
          child: Text(
            'no_categories_found'.tr,
            style: TextStyle(color: Colors.white38, fontSize: 14.sp),
          ),
        ),
      );
    }

    return _isGridView ? _buildCategoryGrid() : _buildCategoryList();
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final cat = _filteredCategories[index];
          return _buildCategoryCard(cat);
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: _filteredCategories.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final cat = _filteredCategories[index];
        return _buildCategoryListItem(cat);
      },
    );
  }

  Widget _buildCategoryCard(dynamic cat) {
    return GestureDetector(
      onTap:
          () => Get.toNamed('/services', arguments: {'category_id': cat['id']}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(
              cat['image'] ??
                  'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?q=80&w=400&auto=format&fit=crop',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          child: Text(
            cat['name'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(dynamic cat) {
    return GestureDetector(
      onTap:
          () => Get.toNamed('/services', arguments: {'category_id': cat['id']}),
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(11),
              ),
              child: Image.network(
                cat['image'] ??
                    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?q=80&w=200&auto=format&fit=crop',
                width: 80.h,
                height: 80.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                cat['name'] ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
            SizedBox(width: 16.w),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    if (_banners.isEmpty) {
      return Container(
        height: 450.h,
        width: double.infinity,
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return SizedBox(
      height: 450.h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _activePage = page;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(banner['image']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60.h,
                    left: 24.w,
                    right: 24.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStyledTitle(banner['title'] ?? ''),
                        if (banner['subtitle'] != null &&
                            banner['subtitle'].toString().isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            banner['subtitle'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 30.h,
            left: 24.w,
            child: Row(
              children: List.generate(
                _banners.length,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: _activePage == index ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color:
                        _activePage == index
                            ? AppColors.primary
                            : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTitle(String title) {
    final processedTitle = title.replaceAll('|', '\n');
    final regex = RegExp(r'\*(.*?)\*');
    final matches = regex.allMatches(processedTitle);

    if (matches.isEmpty) {
      return Text(
        processedTitle,
        style: TextStyle(
          fontSize: 32.sp,
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.1,
        ),
      );
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: processedTitle.substring(lastMatchEnd, match.start),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(color: AppColors.primary),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < processedTitle.length) {
      spans.add(
        TextSpan(
          text: processedTitle.substring(lastMatchEnd),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 32.sp,
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22.sp,
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
