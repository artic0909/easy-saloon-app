import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:url_launcher/url_launcher.dart';

class AdminBookingDetailsPage extends StatefulWidget {
  const AdminBookingDetailsPage({super.key});

  @override
  State<AdminBookingDetailsPage> createState() => _AdminBookingDetailsPageState();
}

class _AdminBookingDetailsPageState extends State<AdminBookingDetailsPage> {
  final ApiService _apiService = ApiService();
  
  late dynamic _bookingParam;
  dynamic _booking;
  List<dynamic> _staffMembers = [];
  
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  bool _isAssigningStaff = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _bookingParam = Get.arguments;
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final id = _bookingParam['id'];
      final bookingType = _bookingParam['booking_type'] ?? 'regular';
      final path = bookingType == 'custom' 
          ? '/admin/custom-bookings/$id' 
          : '/admin/bookings/$id';

      final response = await _apiService.dio.get(path);
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _booking = response.data['data']['booking'];
          _booking['booking_type'] = bookingType;
          _staffMembers = response.data['data']['staffMembers'] ?? [];
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
      case 'confirmed': return Colors.green;
      case 'on_the_way': return Colors.indigoAccent;
      case 'started': return Colors.amber;
      case 'pending': return Colors.orange;
      default: return AppColors.primary;
    }
  }

  List<dynamic> _getItemsList() {
    if (_booking == null) return [];
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
        title: Text("Update Status", style: const TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
        content: Text("Are you sure you want to change status to $nextStatus?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Get.back(result: true),
            child: const Text("Confirm", style: TextStyle(color: Colors.black)),
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
            ? '/admin/custom-bookings/$id/status'
            : '/admin/bookings/$id/status';

        final response = await _apiService.dio.post(path, data: {'status': nextStatus});
        if (response.data['status'] == 'success') {
          Get.snackbar("Success", "Booking updated to $nextStatus", backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
          _fetchBookingDetails();
        }
      } catch (e) {
        String message = "Failed to update booking status";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar("Error", message, backgroundColor: const Color(0xFFC62828), colorText: Colors.white);
      } finally {
        if (mounted) setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _assignStaff(int staffId) async {
    if (!mounted) return;
    setState(() => _isAssigningStaff = true);
    try {
      final id = _booking['id'];
      final bookingType = _booking['booking_type'] ?? 'regular';
      final path = bookingType == 'custom'
          ? '/admin/custom-bookings/$id/assign-staff'
          : '/admin/bookings/$id/assign-staff';

      final response = await _apiService.dio.post(path, data: {'staff_id': staffId});
      if (response.data['status'] == 'success') {
        Get.snackbar("Success", "Staff assigned successfully", backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
        _fetchBookingDetails();
      }
    } catch (e) {
      String message = "Failed to assign staff";
      if (e is dio_pkg.DioException && e.response?.data != null) {
        message = e.response!.data['message'] ?? message;
      }
      Get.snackbar("Error", message, backgroundColor: const Color(0xFFC62828), colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isAssigningStaff = false);
    }
  }

  Future<void> _deleteBooking() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Booking", style: TextStyle(color: Colors.redAccent, fontFamily: 'Playfair Display')),
        content: const Text("Are you sure you want to permanently delete this booking? This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Get.back(result: true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isDeleting = true);
      try {
        final id = _booking['id'];
        final bookingType = _booking['booking_type'] ?? 'regular';
        final path = bookingType == 'custom'
            ? '/admin/custom-bookings/$id'
            : '/admin/bookings/$id';

        final response = await _apiService.dio.delete(path);
        if (response.data['status'] == 'success') {
          Get.snackbar("Success", "Booking deleted", backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
          Get.back(); // Go back to the list
        }
      } catch (e) {
        String message = "Failed to delete booking";
        if (e is dio_pkg.DioException && e.response?.data != null) {
          message = e.response!.data['message'] ?? message;
        }
        Get.snackbar("Error", message, backgroundColor: const Color(0xFFC62828), colorText: Colors.white);
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _callClient(String phone) async {
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

  void _showAssignStaffDialog() {
    int? selectedStaffId;
    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text("Assign Staff", style: TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
            content: DropdownButtonFormField<int>(
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              ),
              hint: const Text("Select Staff Member", style: TextStyle(color: Colors.white38)),
              value: selectedStaffId,
              items: _staffMembers.map((staff) {
                return DropdownMenuItem<int>(
                  value: staff['id'],
                  child: Text(staff['name'] ?? 'Unknown Staff'),
                );
              }).toList(),
              onChanged: (val) {
                setDialogState(() => selectedStaffId = val);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: selectedStaffId == null ? null : () {
                  Get.back();
                  _assignStaff(selectedStaffId!);
                },
                child: const Text("Assign", style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showUpdateStatusDialog() {
    String? selectedStatus = _booking['status']?.toString().toLowerCase();
    final statuses = [
      'pending', 'confirmed', 'accepted', 'on_the_way', 'started', 'completed', 'cancelled'
    ];
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text("Update Status", style: TextStyle(color: Colors.white, fontFamily: 'Playfair Display')),
            content: DropdownButtonFormField<String>(
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              ),
              value: statuses.contains(selectedStatus) ? selectedStatus : null,
              items: statuses.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                setDialogState(() => selectedStatus = val);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: selectedStatus == null ? null : () {
                  Get.back();
                  _updateStatus(selectedStatus!);
                },
                child: const Text("Update", style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _booking == null) {
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
    final assignedStaff = _booking['staff'];
    final isPaid = _booking['is_paid'] == true || _booking['is_paid'] == 1 || _booking['is_paid'] == '1';
    final paymentType = _booking['pay_type']?.toString().toUpperCase() ?? _booking['payment_type']?.toString().toUpperCase() ?? 'ONLINE';

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
          "Manage Booking",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isDeleting 
                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
                : const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _isDeleting ? null : _deleteBooking,
          ),
        ],
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
                          "BOOKING #$bookingNumber",
                          style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: _getStatusColor(status), fontSize: 9.sp, fontWeight: FontWeight.bold),
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
                  if (_booking['otp'] != null) ...[
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.amber, size: 20.w),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SECURITY OTP", style: TextStyle(color: Colors.amber.withValues(alpha: 0.7), fontSize: 8.sp, fontWeight: FontWeight.bold)),
                              Text(_booking['otp'].toString(), style: TextStyle(color: Colors.amber, fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Admin Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: _showUpdateStatusDialog,
                    icon: Icon(Icons.edit_note, color: Colors.black, size: 18.w),
                    label: Text("Status", style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: _showAssignStaffDialog,
                    icon: Icon(Icons.badge, color: AppColors.primary, size: 18.w),
                    label: Text(assignedStaff != null ? "Reassign" : "Assign", style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

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

            // Assigned Staff Card
            Text("ASSIGNED STAFF", style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                    backgroundColor: assignedStaff != null ? AppColors.primary.withValues(alpha: 0.2) : Colors.white10,
                    child: Icon(Icons.badge, color: assignedStaff != null ? AppColors.primary : Colors.white38, size: 24.w),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(assignedStaff?['name']?.toString() ?? 'Unassigned', style: TextStyle(color: assignedStaff != null ? Colors.white : Colors.white38, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        if (assignedStaff?['phone'] != null)
                          Text(assignedStaff?['phone']?.toString() ?? '', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                      ],
                    ),
                  ),
                  if (assignedStaff?['phone'] != null)
                    IconButton(
                      onPressed: () => _callClient(assignedStaff!['phone'].toString()),
                      icon: Icon(Icons.phone_in_talk, color: AppColors.primary, size: 22.w),
                    ),
                ],
              ),
            ),
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
