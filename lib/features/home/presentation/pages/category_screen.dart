import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _categories = [];
  List<dynamic> _filteredCategories = [];
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/categories');
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _categories = response.data['data'] ?? [];
          _filteredCategories = _categories;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error fetching categories: $e");
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories.where((cat) {
        final name = (cat['name'] ?? "").toString().toLowerCase();
        return name.contains(query);
      }).toList();
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
          "Categories",
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildCategoryHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoryContent(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4, // Since Categories is part of More / Drawer
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.offAllNamed('/home');
          } else if (index == 1) {
            Get.offNamed('/my-bookings');
          } else if (index == 2) {
            Get.offNamed('/packages');
          } else if (index == 3) {
            Get.offNamed('/services');
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
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search categories...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Available Categories",
            style: TextStyle(
              fontSize: 18.sp,
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
    return _isGridView ? _buildCategoryGrid() : _buildCategoryList();
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
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
    );
  }

  Widget _buildCategoryList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
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
      onTap: () => Get.toNamed('/services', arguments: {'category_id': cat['id']}),
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
      onTap: () => Get.toNamed('/services', arguments: {'category_id': cat['id']}),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view_outlined, size: 64, color: Colors.white10),
          SizedBox(height: 16.h),
          Text(
            "No categories found",
            style: TextStyle(color: Colors.white38, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
