import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  late Razorpay _razorpay;
  
  // Data passed from previous screens
  late String type; // 'service', 'package', 'custom'
  late dynamic itemData;
  late Map<String, dynamic> bookingDetails;
  
  bool _isLoading = true;
  List<dynamic> _addresses = [];
  int? _selectedAddressId;
  String _paymentMethod = 'online'; // 'cod' or 'online'
  
  dynamic _bookingResponse;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    type = args['type'];
    itemData = args['itemData'];
    bookingDetails = args['bookingDetails'];
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    _fetchAddresses();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    if (bookingDetails['location'] != 'home') {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _apiService.dio.get('/addresses');
      if (response.data['status'] == 'success') {
        setState(() {
          _addresses = response.data['data'];
          if (_addresses.isNotEmpty) {
            _selectedAddressId = _addresses[0]['id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalPrice {
    if (type == 'custom') {
      double total = 0;
      for (var s in itemData) {
        total += double.tryParse(s['sale_price'].toString()) ?? 0;
      }
      return total;
    }
    return double.tryParse(itemData['sale_price'].toString()) ?? 0;
  }

  Future<void> _processBooking() async {
    if (bookingDetails['location'] == 'home' && _selectedAddressId == null) {
      Get.snackbar("Error", "Please select an address for home service", backgroundColor: Colors.red.withOpacity(0.7));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String endpoint = '';
      Map<String, dynamic> payload = {
        'type': bookingDetails['location'],
        'date': bookingDetails['date'],
        'slot': bookingDetails['slot'],
        'equipment': bookingDetails['equipment'],
        'address_id': _selectedAddressId,
        'payment_method': _paymentMethod,
      };

      if (type == 'service') {
        endpoint = '/bookings/service';
        payload['service_id'] = itemData['id'];
      } else if (type == 'package') {
        endpoint = '/bookings/package';
        payload['package_id'] = itemData['id'];
      } else {
        endpoint = '/bookings/custom-package';
        payload['service_ids'] = (itemData as List).map((s) => s['id']).toList();
      }

      final response = await _apiService.dio.post(endpoint, data: payload);

      if (response.data['status'] == 'success') {
        _bookingResponse = response.data;
        if (_paymentMethod == 'online') {
          _startRazorpayPayment();
        } else {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Booking failed", backgroundColor: Colors.red.withOpacity(0.7));
    }
  }

  Future<void> _startRazorpayPayment() async {
    try {
      final bookingId = _bookingResponse['data']['id'];
      final bookingType = _bookingResponse['booking_type'] ?? (type == 'custom' ? 'custom' : 'regular');

      final orderResponse = await _apiService.dio.post('/payments/create-order', data: {
        'booking_id': bookingId,
        'booking_type': bookingType,
      });

      if (orderResponse.data['status'] == 'success') {
        final authService = Get.find<AuthService>();
        final userData = authService.userData;

        var options = {
          'key': orderResponse.data['razorpay_key'],
          'amount': orderResponse.data['amount'],
          'name': 'Easy Saloon',
          'order_id': orderResponse.data['order_id'],
          'description': 'Booking Payment',
          'prefill': {
            'contact': userData['phone'] ?? '',
            'email': userData['email'] ?? '',
            'name': userData['name'] ?? ''
          },
          'theme': {'color': '#D4AF37'}
        };
        _razorpay.open(options);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Payment Error", "Failed to initialize payment", backgroundColor: Colors.red.withOpacity(0.7));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final bookingId = _bookingResponse['data']['id'];
      final bookingType = _bookingResponse['booking_type'] ?? (type == 'custom' ? 'custom' : 'regular');

      await _apiService.dio.post('/payments/verify', data: {
        'booking_id': bookingId,
        'booking_type': bookingType,
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      });

      _showSuccessDialog();
    } catch (e) {
      Get.snackbar("Verification Failed", "Please contact support", backgroundColor: Colors.red.withOpacity(0.7));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    Get.snackbar("Payment Failed", response.message ?? "User cancelled", backgroundColor: Colors.red.withOpacity(0.7));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _showSuccessDialog() {
    Get.defaultDialog(
      title: "Booking Confirmed!",
      middleText: "Your luxury session is scheduled. Check your email for details.",
      backgroundColor: AppColors.surface,
      titleStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      middleTextStyle: const TextStyle(color: Colors.white70),
      confirm: ElevatedButton(
        onPressed: () => Get.offAllNamed('/home'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        child: const Text("Done", style: TextStyle(color: Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Checkout", style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(),
                  SizedBox(height: 30.h),
                  if (bookingDetails['location'] == 'home') _buildAddressSection(),
                  SizedBox(height: 30.h),
                  _buildPaymentMethodSection(),
                  SizedBox(height: 40.h),
                  _buildPriceBreakdown(),
                  SizedBox(height: 40.h),
                  _buildPayButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BOOKING SUMMARY", style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Type", style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
              Text(type.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Location", style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
              Text(bookingDetails['location'].toUpperCase(), style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date & Time", style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
              Text("${bookingDetails['date']} (${bookingDetails['slot']})", style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SELECT ADDRESS", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 15.h),
        if (_addresses.isEmpty)
          Center(
            child: Column(
              children: [
                Text("No addresses found", style: TextStyle(color: Colors.white24, fontSize: 12.sp)),
                TextButton(onPressed: () {}, child: const Text("Add New Address", style: TextStyle(color: AppColors.primary))),
              ],
            ),
          )
        else
          ..._addresses.map((addr) => _buildAddressItem(addr)).toList(),
      ],
    );
  }

  Widget _buildAddressItem(dynamic addr) {
    bool isSelected = _selectedAddressId == addr['id'];
    return InkWell(
      onTap: () => setState(() => _selectedAddressId = addr['id']),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: isSelected ? AppColors.primary : Colors.white24),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(addr['title']?.toString().toUpperCase() ?? 'HOME', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  Text("${addr['full_address']}, ${addr['city']?['name']}", style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PAYMENT METHOD", style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 15.h),
        Row(
          children: [
            Expanded(child: _buildPaymentMethodItem('online', "Pay Online", Icons.payment_outlined)),
            SizedBox(width: 15.w),
            Expanded(child: _buildPaymentMethodItem('cod', "Pay at Salon/Home", Icons.payments_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem(String id, String title, IconData icon) {
    bool isSelected = _paymentMethod == id;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white38, size: 24.sp),
            SizedBox(height: 8.h),
            Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Subtotal", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
            Text("₹$_totalPrice", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Taxes & Fees", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
            Text("₹0", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ],
        ),
        const Divider(color: Colors.white10, height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total Payable", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            Text("₹$_totalPrice", style: TextStyle(color: AppColors.primary, fontSize: 18.sp, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton(
        onPressed: _processBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          elevation: 0,
        ),
        child: Text(
          _paymentMethod == 'online' ? "PAY & CONFIRM" : "CONFIRM BOOKING",
          style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }
}
