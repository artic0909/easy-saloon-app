import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_drawer.dart';
import 'package:easysaloonapp/features/admin/widgets/admin_bottom_nav.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCancelBookingsPage extends StatefulWidget {
  const AdminCancelBookingsPage({super.key});

  @override
  State<AdminCancelBookingsPage> createState() => _AdminCancelBookingsPageState();
}

class _AdminCancelBookingsPageState extends State<AdminCancelBookingsPage> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/admin/cancelled-bookings', queryParameters: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      });
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          final rawData = response.data['data'] ?? [];
          _bookings = (rawData as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Failed to load cancelled bookings",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  String _formatBookingDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar("Error", "Could not launch dialer", backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not launch dialer", backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Cancelled Bookings",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
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
            child: RefreshIndicator(
              onRefresh: _fetchBookings,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _bookings.isEmpty
                      ? _buildEmptyState()
                      : _buildBookingsList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1, // Bookings
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.toNamed('/admin-dashboard');
          } else if (index == 2) {
            Get.toNamed('/admin-manage-services');
          } else if (index == 3) {
            Get.toNamed('/admin-manage-packages');
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (val) {
          setState(() => _searchQuery = val);
          _fetchBookings();
        },
        decoration: InputDecoration(
          hintText: "Search cancelled bookings...",
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: const Icon(Icons.search, color: Colors.white30),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final bookingNumber = booking['booking_number'] ?? '';
    final dateStr = _formatBookingDate(booking['booking_date']?.toString());
    final slotStr = booking['time_slot']?.toString() ?? '';
    final serviceType = booking['service_type']?.toString() == 'home' ? 'Home Service' : 'Salon Visit';
    final payableAmount = double.tryParse(booking['payable_amount']?.toString() ?? booking['total_price']?.toString() ?? '0') ?? 0.0;
    
    final bookingType = booking['booking_type'] ?? 'regular';
    final itemsCount = bookingType == 'custom' 
        ? (booking['services'] as List?)?.length ?? 0
        : (booking['items'] as List?)?.length ?? 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#$bookingNumber",
                style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  "CANCELLED",
                  style: TextStyle(color: Colors.redAccent, fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['user']?['name'] ?? 'Guest Client',
                    style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "$itemsCount items • ₹${payableAmount.toStringAsFixed(0)} • $serviceType",
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
                onPressed: () async {
                  await Get.toNamed('/admin-booking-details', arguments: booking);
                  _fetchBookings();
                },
              ),
            ],
          ),

          if (booking['staff'] != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14.r,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.badge, size: 14.w, color: AppColors.primary),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Assigned Staff", style: TextStyle(color: Colors.white38, fontSize: 9.sp)),
                        Text(booking['staff']['name'] ?? '', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (booking['staff']['phone'] != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.phone_in_talk, color: AppColors.primary, size: 18.w),
                      onPressed: () => _callPhone(booking['staff']['phone'].toString()),
                    ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white30, size: 14.w),
              SizedBox(width: 6.w),
              Text(dateStr, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
              SizedBox(width: 16.w),
              Icon(Icons.access_time, color: Colors.white30, size: 14.w),
              SizedBox(width: 6.w),
              Text(slotStr, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(32.w),
        children: [
          Icon(Icons.event_busy, size: 64.w, color: Colors.white24),
          SizedBox(height: 16.h),
          Text(
            "No Cancelled Bookings",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "There are no cancelled bookings to display.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
