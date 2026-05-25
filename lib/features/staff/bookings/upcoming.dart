import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/features/staff/widgets/staff_drawer.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;

class StaffUpcomingBookingsPage extends StatefulWidget {
  final bool embed;
  const StaffUpcomingBookingsPage({super.key, this.embed = false});

  @override
  State<StaffUpcomingBookingsPage> createState() => _StaffUpcomingBookingsPageState();
}

class _StaffUpcomingBookingsPageState extends State<StaffUpcomingBookingsPage> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUpcomingBookings();
  }

  Future<void> _fetchUpcomingBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/staff/bookings', queryParameters: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      });
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          final rawData = response.data['data'];
          if (rawData is Map && rawData.containsKey('data')) {
            _bookings = rawData['data'] ?? [];
          } else {
            _bookings = rawData ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Failed to load open bookings",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> _acceptBooking(dynamic booking) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Accept Booking?", style: TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
        content: const Text("Do you want to accept this task?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Get.back(result: true),
            child: const Text("Accept", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final id = booking['id'];
        final bookingType = booking['booking_type'] ?? 'regular';
        final path = bookingType == 'custom' 
            ? '/staff/custom-bookings/$id/status' 
            : '/staff/bookings/$id/status';

        final response = await _apiService.dio.post(path, data: {'status': 'Accepted'});
        if (response.data['status'] == 'success') {
          Get.snackbar("Success", "Task accepted successfully!",
              backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
          _fetchUpcomingBookings();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        String message = "Failed to accept booking";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar("Error", message,
            backgroundColor: const Color(0xFFC62828), colorText: Colors.white);
      }
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

  @override
  Widget build(BuildContext context) {
    final bodyContent = Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchUpcomingBookings,
            color: AppColors.primary,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _bookings.isEmpty
                    ? _buildEmptyState()
                    : _buildBookingsList(),
          ),
        ),
      ],
    );

    if (widget.embed) {
      return bodyContent;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const StaffDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Open Bookings",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (val) {
          setState(() => _searchQuery = val);
          // Wait a bit and search
          _fetchUpcomingBookings();
        },
        decoration: InputDecoration(
          hintText: "Search tasks...",
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
    
    // Items
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
              Text(
                serviceType,
                style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold),
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
                    "$itemsCount items • ₹${payableAmount.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
                onPressed: () async {
                  await Get.toNamed('/staff-booking-details', arguments: booking);
                  _fetchUpcomingBookings();
                },
              ),
            ],
          ),
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
          SizedBox(height: 16.h),

          // Accept button
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () => _acceptBooking(booking),
              child: Text("Accept Task", style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.bold)),
            ),
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
          Icon(Icons.task_alt, size: 64.w, color: Colors.white24),
          SizedBox(height: 16.h),
          Text(
            "No Open Tasks",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "All tasks are currently assigned or completed.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
