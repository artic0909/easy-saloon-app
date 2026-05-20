import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';

class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({super.key});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  dynamic _package;
  
  // Booking selections
  String _serviceLocation = 'home';
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = 'Morning';
  List<String> _selectedEquipments = [];

  @override
  void initState() {
    super.initState();
    _fetchPackageDetails();
  }

  Future<void> _fetchPackageDetails() async {
    final id = Get.arguments['id'];
    try {
      final response = await _apiService.dio.get('/packages/$id');
      if (response.data['status'] == 'success') {
        setState(() {
          _package = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Failed to load package details", 
          backgroundColor: Colors.red.withOpacity(0.7), colorText: Colors.white);
    }
  }

  void _handleBooking() {
    Get.toNamed('/checkout', arguments: {
      'type': 'package',
      'itemData': _package,
      'bookingDetails': {
        'location': _serviceLocation,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'slot': _selectedSlot,
        'equipment': _selectedEquipments,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_package == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text("Package not found", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescriptionSection(),
                  SizedBox(height: 20.h),
                  _buildIncludedServicesSection(),
                  SizedBox(height: 30.h),
                  _buildBookingWidget(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40.r)),
          child: Image.network(
            _package['image'] ?? 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?q=80&w=600&auto=format&fit=crop',
            width: double.infinity,
            height: 320.h,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 320.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40.r)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
        Positioned(
          top: 50.h,
          left: 20.w,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        Positioned(
          bottom: 30.h,
          left: 30.w,
          right: 30.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "PACKAGE",
                  style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                _package['name'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Playfair Display',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Package Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Playfair Display',
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          (_package['details'] ?? _package['description'] ?? 'No details provided.').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
          style: TextStyle(color: Colors.white60, fontSize: 14.sp, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildIncludedServicesSection() {
    final List<dynamic> items = _package['items'] ?? [];
    
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Included Services",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
          ),
          SizedBox(height: 12.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 20.h),
            itemBuilder: (context, index) {
              final service = items[index]['service'];
              if (service == null) return const SizedBox.shrink();
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      service['image'] ?? 'https://images.unsplash.com/photo-1560869713-7d0a294308b3?q=80&w=100&auto=format&fit=crop',
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service['name'] ?? '', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        Text("Individual Price: ₹${service['sale_price']}", style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingWidget() {
    return Container(
      padding: EdgeInsets.all(25.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1512),
        borderRadius: BorderRadius.circular(40.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PACKAGE PRICE", style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  SizedBox(height: 4.h),
                  Text("₹${_package['sale_price'] ?? _package['price']}", style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w900)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("TOTAL ITEMS", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  SizedBox(height: 4.h),
                  Text("${(_package['items'] as List).length} Services", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Divider(color: Colors.white.withOpacity(0.05)),
          ),

          Text("CHOOSE SERVICE LOCATION", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildChoiceButton("At Home", Icons.home_outlined, _serviceLocation == 'home', () => setState(() => _serviceLocation = 'home'))),
              SizedBox(width: 15.w),
              Expanded(child: _buildChoiceButton("At Salon", Icons.storefront_outlined, _serviceLocation == 'salon', () => setState(() => _serviceLocation = 'salon'))),
            ],
          ),

          // Equipment Selection
          _buildPackageEquipmentSection(),

          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SELECT DATE & SLOT", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            onPrimary: Colors.black,
                            surface: Color(0xFF1A1512),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary, size: 10.sp),
                      SizedBox(width: 6.w),
                      Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _buildDateButton("TODAY", _isSameDay(_selectedDate, DateTime.now()), () => setState(() => _selectedDate = DateTime.now()))),
              SizedBox(width: 10.w),
              Expanded(child: _buildDateButton("TOMORROW", _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1))), () => setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1))))),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _buildDateButton("MORNING", _selectedSlot == 'Morning', () => setState(() => _selectedSlot = 'Morning'))),
              SizedBox(width: 8.w),
              Expanded(child: _buildDateButton("AFTERNOON", _selectedSlot == 'Afternoon', () => setState(() => _selectedSlot = 'Afternoon'))),
              SizedBox(width: 8.w),
              Expanded(child: _buildDateButton("EVENING", _selectedSlot == 'Evening', () => setState(() => _selectedSlot = 'Evening'))),
            ],
          ),

          SizedBox(height: 40.h),
          
          SizedBox(
            width: double.infinity,
            height: 55.h,
            child: ElevatedButton(
              onPressed: _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                elevation: 0,
              ),
              child: Text(
                "Book Package Now",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white38, size: 24.sp),
            SizedBox(height: 8.h),
            Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageEquipmentSection() {
    final List<dynamic> items = _package['items'] ?? [];
    final itemsWithEquipment = items.where((item) => 
      item['service'] != null && 
      item['service']['equipment'] != null && 
      (item['service']['equipment'] as List).isNotEmpty
    ).toList();

    if (itemsWithEquipment.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        Text("REQUIRED EQUIPMENTS (OPTIONAL)", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ...itemsWithEquipment.map((item) {
          final service = item['service'];
          final List<dynamic> equipment = service['equipment'];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              Text("| ${service['name']?.toString().toUpperCase()}", style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: equipment.map((eq) {
                  final isSelected = _selectedEquipments.contains(eq['name']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedEquipments.remove(eq['name']);
                        } else {
                          _selectedEquipments.add(eq['name']);
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        eq['name'],
                        style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
