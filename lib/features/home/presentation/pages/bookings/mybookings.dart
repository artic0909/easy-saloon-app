import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:url_launcher/url_launcher.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<dynamic> _allBookings = [];
  List<dynamic> _filteredBookings = [];
  String _selectedFilter = 'all'; // 'all', 'upcoming', 'past'

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.dio.get('/my-bookings');
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _allBookings = response.data['data'] ?? [];
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar(
        "Error", 
        "Failed to load bookings",
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredBookings = _allBookings;
      } else if (_selectedFilter == 'upcoming') {
        _filteredBookings = _allBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase() ?? '';
          return ['pending', 'confirmed', 'accepted', 'on_the_way', 'started'].contains(status);
        }).toList();
      } else if (_selectedFilter == 'past') {
        _filteredBookings = _allBookings.where((booking) {
          final status = booking['status']?.toString().toLowerCase() ?? '';
          return ['completed', 'cancelled'].contains(status);
        }).toList();
      }
    });
  }

  String _getBookingTitle(dynamic booking) {
    if (booking['booking_type'] == 'custom') {
      return "Custom Package";
    }
    final items = booking['items'] as List<dynamic>? ?? [];
    if (items.isNotEmpty) {
      final mainItem = items.firstWhere(
        (item) => item['item_type'] == 'package',
        orElse: () => items.firstWhere(
          (item) => item['item_type'] == 'service',
          orElse: () => items.first,
        ),
      );
      if (mainItem['item_type'] == 'package' && mainItem['package'] != null) {
        return mainItem['package']['name']?.toString() ?? 'Salon Package';
      } else if (mainItem['item_type'] == 'service' && mainItem['service'] != null) {
        return mainItem['service']['name']?.toString() ?? 'Salon Service';
      }
    }
    return "Salon Appointment";
  }

  int _getServiceCount(dynamic booking) {
    if (booking['booking_type'] == 'custom') {
      final serviceIds = booking['service_ids'] as List<dynamic>? ?? [];
      return serviceIds.length;
    }
    final items = booking['items'] as List<dynamic>? ?? [];
    return items.length;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF2E7D32); // Emerald green
      case 'cancelled':
        return const Color(0xFFC62828); // Premium red
      default:
        return AppColors.primary; // Gold for pending, confirmed, accepted, etc.
    }
  }

  Future<void> _cancelBooking(dynamic booking) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Cancel Booking?", style: TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
        content: const Text("Are you sure you want to cancel this appointment?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("No, Keep it", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Get.back(result: true),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final id = booking['id'];
        final bookingType = booking['booking_type'] ?? 'regular';
        
        final response = await _apiService.dio.post(
          '/my-bookings/$id/cancel',
          data: {'booking_type': bookingType},
        );

        if (response.data['status'] == 'success') {
          Get.snackbar(
            "Success", 
            "Booking cancelled successfully",
            backgroundColor: const Color(0xFF2E7D32),
            colorText: Colors.white,
          );
          _fetchBookings();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        String message = "Failed to cancel booking";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar(
          "Error", 
          message,
          backgroundColor: const Color(0xFFC62828),
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _callStylist(String phone) async {
    final uri = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar("Error", "Could not trigger phone call", 
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not trigger phone call", 
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
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
          "My Bookings",
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22.sp,
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
          _buildFilterPills(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : _buildBookingsList(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.offAllNamed('/home');
          } else if (index == 2) {
            Get.offNamed('/packages');
          } else if (index == 3) {
            Get.offNamed('/categories');
          }
        },
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Row(
        children: [
          _buildFilterPill('all', 'All'),
          SizedBox(width: 8.w),
          _buildFilterPill('upcoming', 'Upcoming'),
          SizedBox(width: 8.w),
          _buildFilterPill('past', 'Past'),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
          _applyFilter();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      itemCount: _filteredBookings.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final booking = _filteredBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final title = _getBookingTitle(booking);
    final serviceCount = _getServiceCount(booking);
    final dateStr = _formatBookingDate(booking['booking_date']?.toString());
    final status = booking['status']?.toString() ?? 'pending';
    final payableAmount = double.tryParse(booking['payable_amount']?.toString() ?? booking['total_price']?.toString() ?? '0') ?? 0.0;
    final bookingNumber = booking['booking_number'] ?? '';
    final isPaid = booking['is_paid'] == true || booking['is_paid'] == 1 || booking['is_paid'] == '1';
    final payType = booking['pay_type']?.toString().toUpperCase() ?? booking['payment_type']?.toString().toUpperCase() ?? 'ONLINE';
    final serviceType = booking['service_type']?.toString() == 'home' ? 'Home Service' : 'Salon Visit';
    final hasRating = booking['rating'] != null && double.parse(booking['rating'].toString()) > 0;
    final staff = booking['staff'];

    final canCancel = ['pending', 'confirmed'].contains(status.toLowerCase());

    return InkWell(
      onTap: () async {
        // Navigate to details and refresh list on back
        await Get.toNamed('/booking-details', arguments: booking);
        _fetchBookings();
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Booking Number & Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#$bookingNumber",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  serviceType,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Main Info: Title, Stars, Count
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (serviceCount > 1) ...[
                            SizedBox(width: 4.w),
                            Text(
                              "+${serviceCount - 1} more",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ]
                        ],
                      ),
                      if (hasRating) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: List.generate(
                            int.parse(booking['rating'].toString()),
                            (i) => Icon(Icons.star, color: Colors.amber, size: 14.w),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Price
                Text(
                  "₹${payableAmount.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Date & Time slots
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: Colors.white30, size: 14.w),
                SizedBox(width: 6.w),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.access_time_outlined, color: Colors.white30, size: 14.w),
                SizedBox(width: 6.w),
                Text(
                  booking['time_slot']?.toString() ?? '',
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Middle status badges
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.25), width: 1),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFF2E7D32).withValues(alpha: 0.12) : const Color(0xFFC5A35C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isPaid ? "PAID" : "UNPAID",
                    style: TextStyle(
                      color: isPaid ? const Color(0xFF81C784) : const Color(0xFFE5D1A2),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  payType,
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Staff / Stylist Card embedded
            if (staff != null) ...[
              SizedBox(height: 16.h),
              InkWell(
                onTap: staff['phone'] != null
                    ? () => _callStylist(staff['phone'].toString())
                    : null,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: staff['photo'] != null
                            ? NetworkImage("https://test.sumatrasales.com/storage/${staff['photo']}")
                            : null,
                        child: staff['photo'] == null
                            ? Icon(Icons.person, color: AppColors.primary, size: 18.w)
                            : null,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ASSIGNED PROFESSIONAL",
                              style: TextStyle(color: Colors.white30, fontSize: 8.sp, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              staff['name']?.toString() ?? '',
                              style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (staff['phone'] != null)
                        Icon(Icons.phone_in_talk, color: AppColors.primary, size: 20.w),
                    ],
                  ),
                ),
              ),
            ],

            // Cancellation Actions
            if (canCancel) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _cancelBooking(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE57373),
                      side: const BorderSide(color: Color(0xFFC62828), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    ),
                    child: Text(
                      "Cancel Booking",
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 72.w, color: Colors.white12),
            SizedBox(height: 16.h),
            Text(
              "No Bookings Found",
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 20.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "You don't have any bookings in this section.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12.sp),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 160.w,
              height: 44.h,
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                ),
                child: Text(
                  "Book Now",
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
