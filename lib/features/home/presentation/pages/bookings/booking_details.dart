import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:url_launcher/url_launcher.dart';

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final ApiService _apiService = ApiService();
  
  late dynamic _booking;
  bool _isLoading = false;
  int _userRating = 0;
  bool _isRatingSubmitting = false;

  @override
  void initState() {
    super.initState();
    _booking = Get.arguments;
    _userRating = int.tryParse(_booking['rating']?.toString() ?? '0') ?? 0;
  }

  String _formatBookingDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return AppColors.primary;
    }
  }

  List<dynamic> _getItemsList() {
    if (_booking['booking_type'] == 'custom') {
      return _booking['services'] as List<dynamic>? ?? [];
    }
    return _booking['items'] as List<dynamic>? ?? [];
  }

  String _getItemName(dynamic item) {
    if (_booking['booking_type'] == 'custom') {
      return item['name']?.toString() ?? 'Service';
    }
    if (item['item_type'] == 'package' && item['package'] != null) {
      return item['package']['name']?.toString() ?? 'Salon Package';
    } else if (item['item_type'] == 'service' && item['service'] != null) {
      return item['service']['name']?.toString() ?? 'Salon Service';
    }
    return 'Salon Item';
  }

  double _getItemPrice(dynamic item) {
    return double.tryParse(item['price']?.toString() ?? item['sale_price']?.toString() ?? '0') ?? 0.0;
  }

  double _getSubtotal() {
    return double.tryParse(_booking['total_price']?.toString() ?? '0') ?? 0.0;
  }

  double _getDiscount() {
    return double.tryParse(_booking['discount_amount']?.toString() ?? '0') ?? 0.0;
  }

  double _getPayableAmount() {
    return double.tryParse(_booking['payable_amount']?.toString() ?? _booking['total_price']?.toString() ?? '0') ?? 0.0;
  }

  Future<void> _cancelBooking() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Cancel Appointment?", style: TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
        content: const Text("Do you really want to cancel this booking?", style: TextStyle(color: Colors.white70)),
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
        final id = _booking['id'];
        final bookingType = _booking['booking_type'] ?? 'regular';

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
          // Set local booking state to cancelled to reflect instantly
          setState(() {
            _booking['status'] = 'cancelled';
            _isLoading = false;
          });
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

  Future<void> _submitRating(int ratingValue) async {
    setState(() => _isRatingSubmitting = true);
    try {
      final id = _booking['id'];
      final bookingType = _booking['booking_type'] ?? 'regular';

      final response = await _apiService.dio.post(
        '/my-bookings/$id/rate',
        data: {
          'rating': ratingValue,
          'booking_type': bookingType,
        },
      );

      if (response.data['status'] == 'success') {
        Get.snackbar(
          "Thank you", 
          "Your rating has been submitted successfully!",
          backgroundColor: const Color(0xFF2E7D32),
          colorText: Colors.white,
        );
        setState(() {
          _userRating = ratingValue;
          _booking['rating'] = ratingValue;
          _isRatingSubmitting = false;
        });
      }
    } catch (e) {
      setState(() => _isRatingSubmitting = false);
      String message = "Failed to submit rating";
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
    final bookingNumber = _booking['booking_number'] ?? '';
    final status = _booking['status']?.toString() ?? 'pending';
    final dateStr = _formatBookingDate(_booking['booking_date']?.toString());
    final slotStr = _booking['time_slot']?.toString() ?? '';
    final serviceType = _booking['service_type']?.toString() == 'home' ? 'Home Visit' : 'Salon Appointment';
    final address = _booking['address'];
    final staff = _booking['staff'];
    final couponCode = _booking['coupon_code'];
    final isPaid = _booking['is_paid'] == true || _booking['is_paid'] == 1 || _booking['is_paid'] == '1';
    final paymentType = _booking['pay_type']?.toString().toUpperCase() ?? _booking['payment_type']?.toString().toUpperCase() ?? 'ONLINE';
    final otpCode = _booking['otp']?.toString();
    final isOtpVerified = _booking['verify'] == true || _booking['verify'] == 1 || _booking['verify'] == '1';

    final canCancel = ['pending', 'confirmed'].contains(status.toLowerCase());
    final isCompleted = status.toLowerCase() == 'completed';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Appointment Details",
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card with Booking No & Status
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              child: Text(
                                "BOOKING #$bookingNumber",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Text(
                              serviceType,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, color: AppColors.primary, size: 20.w),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "APPOINTMENT DATE",
                                    style: TextStyle(color: Colors.white30, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.primary, size: 20.w),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TIME SLOT",
                                    style: TextStyle(color: Colors.white30, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  Text(
                                    slotStr,
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Security OTP & Status pills
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.08), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("BOOKING STATUS", style: TextStyle(color: Colors.white38, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4.h),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (otpCode != null && otpCode.isNotEmpty) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: isOtpVerified ? const Color(0xFF2E7D32).withValues(alpha: 0.12) : AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isOtpVerified ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.08), 
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOtpVerified ? "SECURITY VERIFIED" : "SECURITY OTP", 
                                  style: TextStyle(
                                    color: isOtpVerified ? const Color(0xFF81C784) : Colors.white38, 
                                    fontSize: 8.sp, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      otpCode,
                                      style: TextStyle(
                                        color: isOtpVerified ? const Color(0xFF81C784) : AppColors.primary,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Icon(
                                      isOtpVerified ? Icons.verified_user : Icons.lock_outline,
                                      color: isOtpVerified ? const Color(0xFF81C784) : AppColors.primary,
                                      size: 14.w,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Payment Details Section
                  Text(
                    "PAYMENT DETAILS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.08), width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("METHOD", style: TextStyle(color: Colors.white38, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4.h),
                              Text(paymentType, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("STATUS", style: TextStyle(color: Colors.white38, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4.h),
                              Text(
                                isPaid ? "PAID" : "UNPAID", 
                                style: TextStyle(
                                  color: isPaid ? const Color(0xFF81C784) : const Color(0xFFE5D1A2), 
                                  fontSize: 13.sp, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (couponCode != null && couponCode.toString().isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_offer, color: const Color(0xFF81C784), size: 12.w),
                                SizedBox(width: 4.w),
                                Text(
                                  couponCode.toString().toUpperCase(),
                                  style: TextStyle(color: const Color(0xFF81C784), fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Included Services List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "INCLUDED SERVICES",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "${_getItemsList().length} Items",
                        style: TextStyle(color: Colors.white30, fontSize: 11.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getItemsList().length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final item = _getItemsList()[index];
                      final name = _getItemName(item);
                      final price = _getItemPrice(item);
                      final isPackage = _booking['booking_type'] != 'custom' && item['item_type'] == 'package';
                      
                      return Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    isPackage ? "Curated Bundle" : "Professional Service",
                                    style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              price > 0 ? "₹${price.toStringAsFixed(0)}" : "Free",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Address Box (If Home Booking)
                  if (serviceType.contains('Home') && address != null) ...[
                    Text(
                      "SERVICE ADDRESS",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary, size: 24.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address['title']?.toString().toUpperCase() ?? 'HOME ADDRESS',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  address['full_address']?.toString() ?? '',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.87), fontSize: 12.sp, height: 1.4),
                                ),
                                if (address['landmark'] != null && address['landmark'].toString().isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Landmark: ${address['landmark']}",
                                    style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                                  ),
                                ],
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Container(
                                      width: 4.w,
                                      height: 4.h,
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "${address['city']?['name'] ?? ''}, ${address['state']?['name'] ?? ''}",
                                      style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Staff Assigned Professional
                  if (staff != null) ...[
                    Text(
                      "ASSIGNED STYLIST",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    InkWell(
                      onTap: staff['phone'] != null
                          ? () => _callStylist(staff['phone'].toString())
                          : null,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08), width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20.r,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: staff['photo'] != null
                                  ? NetworkImage("https://test.sumatrasales.com/storage/${staff['photo']}")
                                  : null,
                              child: staff['photo'] == null
                                  ? Icon(Icons.person, color: AppColors.primary, size: 24.w)
                                  : null,
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff['name']?.toString() ?? '',
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Luxury Styling Specialist",
                                    style: TextStyle(color: Colors.white30, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            if (staff['phone'] != null)
                              Icon(Icons.phone_in_talk, color: AppColors.primary, size: 22.w),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Rating Section (Completed Bookings)
                  if (isCompleted) ...[
                    Text(
                      "RATE YOUR EXPERIENCE",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "How was your salon experience?",
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12.h),
                          _isRatingSubmitting
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    final starValue = index + 1;
                                    return IconButton(
                                      icon: Icon(
                                        starValue <= _userRating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 32.w,
                                      ),
                                      onPressed: () => _submitRating(starValue),
                                    );
                                  }),
                                ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Price Breakdown Summary Card
                  Text(
                    "BILL DETAILS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal", style: TextStyle(color: Colors.white54)),
                            Text("₹${_getSubtotal().toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (_getDiscount() > 0) ...[
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Coupon Discount", style: TextStyle(color: Color(0xFF81C784))),
                              Text("- ₹${_getDiscount().toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Taxes & Fees", style: TextStyle(color: Colors.white54)),
                            Text("₹0.00", style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        const Divider(color: Colors.white10),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Payable",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "₹${_getPayableAmount().toStringAsFixed(2)}",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // Bottom Cancellation button
                  if (canCancel) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        ),
                        onPressed: _cancelBooking,
                        child: Text(
                          "Cancel Appointment",
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ],
              ),
            ),
    );
  }
}
