import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/network/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final AuthService _authService = Get.find<AuthService>();
  final ApiService _apiService = ApiService();

  List<dynamic> _banners = [];
  late PageController _pageController;
  Timer? _timer;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchBanners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _fetchBanners() async {
    try {
      final response = await _apiService.dio.get('/banners');
      if (response.data['status'] == 'success') {
        setState(() {
          _banners = response.data['data'];
        });
        if (_banners.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      _buildPlaceholderContent("My Bookings"),
      _buildPlaceholderContent("Packages"),
      _buildPlaceholderContent("Services"),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: pages[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 24.sp, fontFamily: 'Playfair Display'),
          ),
          Text(
            "Coming Soon",
            style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context),
          SizedBox(height: 32.h),
          _buildSectionHeader("Explore by Category"),
          SizedBox(height: 16.h),
          _buildCategoryList(),
          SizedBox(height: 40.h),
          _buildSectionHeader("Services we offer"),
          _buildSubHeader("CURATED LUXURY EXPERIENCES FOR YOUR WELLBEING"),
          SizedBox(height: 20.h),
          _buildServicesGrid(),
          SizedBox(height: 40.h),
          _buildSectionHeader("Media Coverages"),
          SizedBox(height: 20.h),
          _buildMediaCoverages(),
          SizedBox(height: 60.h),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    if (_banners.isEmpty) {
      return Container(
        height: 450.h,
        width: double.infinity,
        color: AppColors.surface,
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                  // Background Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(banner['image']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient Overlay
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
                  // Content
                  Positioned(
                    bottom: 60.h,
                    left: 24.w,
                    right: 24.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStyledTitle(banner['title'] ?? ''),
                        if (banner['subtitle'] != null && banner['subtitle'].toString().isNotEmpty) ...[
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
          // Page Indicators
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
                    color: _activePage == index ? AppColors.primary : Colors.white24,
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
    // Replace | with \n for line breaks
    final processedTitle = title.replaceAll('|', '\n');
    
    // Regex to find text between *asterisks*
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
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: processedTitle.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Colors.white),
        ));
      }
      
      // Add the matched text (between asterisks) in gold color
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(color: AppColors.primary),
      ));
      
      lastMatchEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastMatchEnd < processedTitle.length) {
      spans.add(TextSpan(
        text: processedTitle.substring(lastMatchEnd),
        style: const TextStyle(color: Colors.white),
      ));
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

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          letterSpacing: 1.2,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = ["Hair Care", "Makeup", "Facial & Spa", "Men's Grooming"];
    return SizedBox(
      height: 120.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?q=80&w=200&auto=format&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
              ),
              SizedBox(height: 8.h),
              Text(categories[index], style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = ["hair cutting", "Premium Haircut", "Hair Coloring"];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1560869713-7d0a294308b3?q=80&w=400&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: Text(
                services[index],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaCoverages() {
    return SizedBox(
      height: 200.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          return Container(
            width: 280.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 20, height: 12, color: Colors.red),
                    SizedBox(width: 8.w),
                    Text("The Times of India", style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "How Easy Saloon is redefining the grooming industry",
                  maxLines: 2,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?q=80&w=400&auto=format&fit=crop',
                    height: 80.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
