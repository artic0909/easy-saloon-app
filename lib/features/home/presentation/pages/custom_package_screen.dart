import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';

class CustomPackageScreen extends StatefulWidget {
  const CustomPackageScreen({super.key});

  @override
  State<CustomPackageScreen> createState() => _CustomPackageScreenState();
}

class _CustomPackageScreenState extends State<CustomPackageScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _categories = [];
  List<dynamic> _filteredCategories = [];
  final List<dynamic> _selectedServices = [];
  String _searchQuery = "";
  
  // Booking selections
  String _serviceLocation = 'home';
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = 'Morning';
  final List<String> _selectedEquipments = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomPackageData();
  }

  Future<void> _fetchCustomPackageData() async {
    try {
      final response = await _apiService.dio.get('/packages/custom-data');
      if (response.data['status'] == 'success') {
        setState(() {
          _categories = response.data['data'];
          _filteredCategories = _categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Failed to load data", backgroundColor: Colors.red.withOpacity(0.7));
    }
  }

  void _filterServices(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        final lowQuery = query.toLowerCase();
        _filteredCategories = _categories.map((cat) {
          final services = (cat['services'] as List<dynamic>? ?? []).where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            return name.contains(lowQuery);
          }).toList();
          return {
            ...cat,
            'services': services,
          };
        }).where((cat) => (cat['services'] as List).isNotEmpty).toList();
      }
    });
  }

  double get _totalPrice {
    double total = 0;
    for (var service in _selectedServices) {
      total += double.tryParse(service['sale_price'].toString()) ?? 0;
    }
    return total;
  }

  void _toggleService(dynamic service) {
    setState(() {
      if (_selectedServices.any((s) => s['id'] == service['id'])) {
        _selectedServices.removeWhere((s) => s['id'] == service['id']);
        // Also remove its equipment
        if (service['equipment'] != null) {
          for (var eq in service['equipment']) {
            _selectedEquipments.remove(eq['name']);
          }
        }
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _handleBooking() {
    if (_selectedServices.isEmpty) {
      Get.snackbar("Error", "Please select at least one service", backgroundColor: Colors.red.withOpacity(0.7));
      return;
    }

    Get.toNamed('/checkout', arguments: {
      'type': 'custom',
      'itemData': _selectedServices,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Make Your Own Package", style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildSearchField(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      final services = category['services'] as List<dynamic>? ?? [];
                      if (services.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            child: Text(
                              category['name']?.toString().toUpperCase() ?? '',
                              style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                          ),
                          ...services.map((service) => _buildServiceItem(service)).toList(),
                          SizedBox(height: 10.h),
                        ],
                      );
                    },
                  ),
                ),
                _buildSummaryAndBookingBar(),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: _filterServices,
          decoration: InputDecoration(
            hintText: "Search services...",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15.h),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(dynamic service) {
    final bool isSelected = _selectedServices.any((s) => s['id'] == service['id']);
    
    return InkWell(
      onTap: () => _toggleService(service),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(
                service['image'] ?? 'https://images.unsplash.com/photo-1560869713-7d0a294308b3?q=80&w=100&auto=format&fit=crop',
                width: 60.w,
                height: 60.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service['name'] ?? '', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text("₹${service['sale_price']}", style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? AppColors.primary : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryAndBookingBar() {
    if (_selectedServices.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(25.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${_selectedServices.length} SERVICES SELECTED", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text("Total: ₹$_totalPrice", style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showBookingModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                ),
                child: const Text("Continue", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(25.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1512),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                SizedBox(height: 25.h),
                Text("COMPLETE YOUR BOOKING", style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
                SizedBox(height: 25.h),
                
                Text("CHOOSE LOCATION", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _buildModalChoice("Home", Icons.home, _serviceLocation == 'home', () => setModalState(() => _serviceLocation = 'home'))),
                    SizedBox(width: 15.w),
                    Expanded(child: _buildModalChoice("Salon", Icons.storefront, _serviceLocation == 'salon', () => setModalState(() => _serviceLocation = 'salon'))),
                  ],
                ),

                _buildModalEquipmentSection(setModalState),

                SizedBox(height: 25.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("SELECT DATE", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
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
                          setModalState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.primary, size: 10.sp),
                            SizedBox(width: 5.w),
                            Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _buildModalDateBtn("TODAY", _isSameDay(_selectedDate, DateTime.now()), () => setModalState(() => _selectedDate = DateTime.now()))),
                    SizedBox(width: 10.w),
                    Expanded(child: _buildModalDateBtn("TOMORROW", _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1))), () => setModalState(() => _selectedDate = DateTime.now().add(const Duration(days: 1))))),
                  ],
                ),
                
                SizedBox(height: 25.h),
                Text("SELECT SLOT", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _buildModalDateBtn("MORNING", _selectedSlot == 'Morning', () => setModalState(() => _selectedSlot = 'Morning'))),
                    SizedBox(width: 8.w),
                    Expanded(child: _buildModalDateBtn("AFTERNOON", _selectedSlot == 'Afternoon', () => setModalState(() => _selectedSlot = 'Afternoon'))),
                    SizedBox(width: 8.w),
                    Expanded(child: _buildModalDateBtn("EVENING", _selectedSlot == 'Evening', () => setModalState(() => _selectedSlot = 'Evening'))),
                  ],
                ),

                SizedBox(height: 40.h),
                SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleBooking();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                    ),
                    child: Text("Confirm & Book ₹$_totalPrice", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalEquipmentSection(StateSetter setModalState) {
    final servicesWithEquipment = _selectedServices.where((s) => 
      s['equipment'] != null && 
      (s['equipment'] as List).isNotEmpty
    ).toList();

    if (servicesWithEquipment.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 25.h),
        Text("REQUIRED EQUIPMENTS (OPTIONAL)", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        ...servicesWithEquipment.map((service) {
          final List<dynamic> equipment = service['equipment'];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text("| ${service['name']?.toString().toUpperCase()}", style: TextStyle(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: equipment.map((eq) {
                  final isSelected = _selectedEquipments.contains(eq['name']);
                  return InkWell(
                    onTap: () {
                      setModalState(() {
                        if (isSelected) {
                          _selectedEquipments.remove(eq['name']);
                        } else {
                          _selectedEquipments.add(eq['name']);
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10.r),
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

  Widget _buildModalChoice(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white38, size: 20.sp),
            SizedBox(height: 4.h),
            Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildModalDateBtn(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
