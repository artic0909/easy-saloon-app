import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:url_launcher/url_launcher.dart';

class StaffBookingDetailsPage extends StatefulWidget {
  const StaffBookingDetailsPage({super.key});

  @override
  State<StaffBookingDetailsPage> createState() => _StaffBookingDetailsPageState();
}

class _StaffBookingDetailsPageState extends State<StaffBookingDetailsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _otpController = TextEditingController();
  
  late dynamic _booking;
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();
    _booking = Get.arguments;
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final id = _booking['id'];
      final bookingType = _booking['booking_type'] ?? 'regular';
      final path = bookingType == 'custom' 
          ? '/staff/custom-bookings/$id' 
          : '/staff/bookings/$id';

      final response = await _apiService.dio.get(path);
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _booking = response.data['data'];
          _booking['booking_type'] = bookingType;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error fetching booking details: $e");
    }
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
      case 'completed': return const Color(0xFF2E7D32);
      case 'cancelled': return const Color(0xFFC62828);
      case 'accepted': return Colors.blue;
      case 'on_the_way': return Colors.indigoAccent;
      case 'started': return Colors.amber;
      default: return AppColors.primary;
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

  Future<void> _updateStatus(String nextStatus) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("$nextStatus Booking?", style: const TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
        content: Text("Are you sure you want to change status to $nextStatus?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Get.back(result: true),
            child: const Text("Yes", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = true);
      try {
        final id = _booking['id'];
        final bookingType = _booking['booking_type'] ?? 'regular';
        final path = bookingType == 'custom'
            ? '/staff/custom-bookings/$id/status'
            : '/staff/bookings/$id/status';

        final response = await _apiService.dio.post(path, data: {'status': nextStatus});
        if (response.data['status'] == 'success') {
          Get.snackbar(
            "Success",
            "Booking updated to $nextStatus",
            backgroundColor: const Color(0xFF2E7D32),
            colorText: Colors.white,
          );
          _fetchBookingDetails();
        }
      } catch (e) {
        String message = "Failed to update booking status";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar(
          "Error",
          message,
          backgroundColor: const Color(0xFFC62828),
          colorText: Colors.white,
        );
      } finally {
        if (mounted) setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otpStr = _otpController.text.trim();
    if (otpStr.length < 4) {
      Get.snackbar("Error", "Please enter a valid 4-digit OTP",
          backgroundColor: const Color(0xFFC62828), colorText: Colors.white);
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifyingOtp = true);
    try {
      final id = _booking['id'];
      final bookingType = _booking['booking_type'] ?? 'regular';
      final path = bookingType == 'custom'
          ? '/staff/custom-bookings/$id/verify-otp'
          : '/staff/bookings/$id/verify-otp';

      final response = await _apiService.dio.post(path, data: {'otp': otpStr});
      if (response.data['status'] == 'success') {
        Get.snackbar(
          "OTP Verified",
          "Service security code verified successfully!",
          backgroundColor: const Color(0xFF2E7D32),
          colorText: Colors.white,
        );
        _otpController.clear();
        _fetchBookingDetails();
      }
    } catch (e) {
      String message = "Failed to verify OTP";
      if (e is dio_pkg.DioException && e.response?.data != null) {
        message = e.response!.data['message'] ?? message;
      }
      Get.snackbar(
        "Verification Failed",
        message,
        backgroundColor: const Color(0xFFC62828),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar("Error", "Could not launch dialer",
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not launch dialer",
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> _navigateMap(String fullAddress) async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fullAddress)}");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar("Error", "Could not open map launcher", 
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Could not open map launcher", 
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final bookingNumber = _booking['booking_number'] ?? '';
    final status = _booking['status']?.toString() ?? 'pending';
    final dateStr = _formatBookingDate(_booking['booking_date']?.toString());
    final slotStr = _booking['time_slot']?.toString() ?? '';
    final serviceType = _booking['service_type']?.toString() == 'home' ? 'Home Visit' : 'Salon Appointment';
    final address = _booking['address'];
    final client = _booking['user'];
    final isPaid = _booking['is_paid'] == true || _booking['is_paid'] == 1 || _booking['is_paid'] == '1';
    final paymentType = _booking['pay_type']?.toString().toUpperCase() ?? _booking['payment_type']?.toString().toUpperCase() ?? 'ONLINE';
    final isOtpVerified = _booking['verify'] == true || _booking['verify'] == 1 || _booking['verify'] == '1';
    final assignedStaffId = _booking['staff_id'];

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
          "Staff Task Details",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                          "TASK #$bookingNumber",
                          style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      Text(
                        serviceType,
                        style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold),
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
                            Text("APPOINTMENT DATE", style: TextStyle(color: Colors.white30, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                            Text(dateStr, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
                            Text("TIME SLOT", style: TextStyle(color: Colors.white30, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                            Text(slotStr, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Client Info Card
            if (client != null) ...[
              Text("CLIENT INFORMATION", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 10.h),
              Container(
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
                      child: Icon(Icons.person, color: AppColors.primary, size: 24.w),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client['name']?.toString() ?? 'Guest Client', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          if (client['phone'] != null)
                            Text(client['phone']?.toString() ?? '', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                        ],
                      ),
                    ),
                    if (client['phone'] != null)
                      IconButton(
                        onPressed: () => _callClient(client['phone'].toString()),
                        icon: Icon(Icons.phone_in_talk, color: AppColors.primary, size: 22.w),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Action Stepper Section
            Text("TASK STATUS ACTIONS", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.2)),
              ),
              child: _isUpdatingStatus
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("CURRENT STATUS:", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                            Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        
                        // Action buttons
                        if (assignedStaffId == null) ...[
                          // Available booking
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _updateStatus('Accepted'),
                              child: Text("Accept Booking", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled') ...[
                          // Dynamic workflow based on status
                          if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'confirmed') ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () => _updateStatus('Accepted'),
                                child: Text("Accept Task", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                onPressed: () => _updateStatus('On the way'),
                                child: Text("Start Travel (On the Way)", style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          if (status.toLowerCase() == 'accepted')
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                onPressed: () => _updateStatus('On the way'),
                                child: Text("Start Travel (On the Way)", style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (status.toLowerCase() == 'on_the_way') ...[
                            if (!isOtpVerified && _booking['otp'] != null) ...[
                              Text("SECURITY OTP VERIFICATION REQUIRED", style: TextStyle(color: Colors.redAccent, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: "Enter 4-digit OTP",
                                        hintStyle: const TextStyle(color: Colors.white30),
                                        filled: true,
                                        fillColor: AppColors.background,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  SizedBox(
                                    height: 48.h,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                      onPressed: _isVerifyingOtp ? null : _verifyOtp,
                                      child: _isVerifyingOtp 
                                          ? const CircularProgressIndicator(color: Colors.black)
                                          : Text("Verify OTP", style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                                  onPressed: () {
                                    Get.snackbar("OTP Required", "Please verify the customer's OTP to start the service.",
                                        backgroundColor: Colors.amber.withValues(alpha: 0.9), colorText: Colors.black);
                                  },
                                  child: Text("Start Service (Requires OTP)", style: TextStyle(color: Colors.white30, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ] else ...[
                              if (_booking['otp'] != null)
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12.r)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, color: Colors.green),
                                      SizedBox(width: 8.w),
                                      Text("OTP Verified Successfully", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                  onPressed: () => _updateStatus('Started'),
                                  child: Text("Start Service", style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ],
                          if (status.toLowerCase() == 'started') ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                                onPressed: () => _updateStatus('Completed'),
                                child: Text("Complete Service", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          
                          SizedBox(height: 12.h),
                          // Reject / Cancel button
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              minimumSize: Size(double.infinity, 40.h),
                            ),
                            onPressed: () => _updateStatus('Rejected'),
                            child: Text("Reject / Cancel Booking", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                          ),
                        ] else ...[
                          Text("This task has been resolved.", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                        ],
                      ],
                    ),
            ),
            if (status.toLowerCase() == 'completed') ...[
              SizedBox(height: 24.h),
              Text("CUSTOMER RATING", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _booking['rating'] != null ? "Service Rated" : "Not Rated Yet",
                            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _booking['rating'] != null ? "Customer provided a rating for this service" : "Customer hasn't rated this visit yet",
                            style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    if (_booking['rating'] != null) ...[
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              final r = int.tryParse(_booking['rating'].toString()) ?? 0;
                              return Icon(
                                index < r ? Icons.star : Icons.star_border,
                                color: index < r ? Colors.amber : Colors.white24,
                                size: 16.w,
                              );
                            }),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "${_booking['rating']}.0",
                            style: TextStyle(color: Colors.amber, fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: List.generate(5, (index) => Icon(Icons.star_border, color: Colors.white24, size: 16.w)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),

            // Service Address (If Home Booking)
            if (serviceType.contains('Home') && address != null) ...[
              Text("SERVICE ADDRESS", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                          Text(address['full_address']?.toString() ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.87), fontSize: 12.sp, height: 1.4)),
                          if (address['landmark'] != null && address['landmark'].toString().isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text("Landmark: ${address['landmark']}", style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                          ],
                          SizedBox(height: 12.h),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.background, side: const BorderSide(color: AppColors.primary, width: 1)),
                            onPressed: () => _navigateMap(address['full_address']?.toString() ?? ''),
                            icon: Icon(Icons.navigation, color: AppColors.primary, size: 16.w),
                            label: Text("Navigate on Map", style: TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Included Services
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("INCLUDED SERVICES", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text("${_getItemsList().length} Items", style: TextStyle(color: Colors.white30, fontSize: 11.sp)),
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
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2.h),
                            Text(isPackage ? "Curated Bundle" : "Professional Service", style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text(
                        price > 0 ? "₹${price.toStringAsFixed(0)}" : "Free",
                        style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 24.h),

            // Bill Details
            Text("BILL DETAILS", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                      Text("₹0.00", style: TextStyle(color: Colors.white30)),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  const Divider(color: Colors.white10),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Payable", style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                      Text("₹${_getPayableAmount().toStringAsFixed(2)}", style: TextStyle(color: AppColors.primary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Payment Method", style: TextStyle(color: Colors.white54)),
                      Text(paymentType, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Payment Status", style: TextStyle(color: Colors.white54)),
                      Text(isPaid ? "PAID" : "UNPAID", style: TextStyle(color: isPaid ? Colors.green : Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
