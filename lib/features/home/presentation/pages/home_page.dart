import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 450.h,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1562322140-8baeececf3df?q=80&w=1000&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 450.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 40.h,
          left: 24.w,
          right: 24.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.1),
                  children: const [
                    TextSpan(text: "Bringing "),
                    TextSpan(text: "Salon Expertise ", style: TextStyle(color: AppColors.primary)),
                    TextSpan(text: "to Your Doorstep"),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "While Changing the Lives of Service Professionals",
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  _buildHeroButton("Download App", Colors.white.withOpacity(0.1), Colors.white),
                  SizedBox(width: 12.w),
                  _buildHeroButton("Register as Partner", AppColors.primary, AppColors.textOnPrimary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroButton(String text, Color bg, Color textCol) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: bg == Colors.white.withOpacity(0.1) ? Border.all(color: Colors.white24) : null,
      ),
      child: Text(
        text,
        style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 12.sp),
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
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_outlined), label: 'Offers'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
