import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Razorpay _razorpay;

  bool _isLoading = true;
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.dio.get('/wallet');
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _balance = double.tryParse(response.data['data']['wallet']['balance'].toString()) ?? 0.0;
          _transactions = response.data['data']['transactions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load wallet data');
    }
  }

  Future<void> _addMoney(String amountStr) async {
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }

    Get.back(); // Close bottom sheet
    Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.primary)), barrierDismissible: false);

    try {
      final response = await _apiService.dio.post('/wallet/add-money', data: {
        'amount': amount,
      });

      Get.back(); // Close loading dialog

      if (response.data['status'] == 'success') {
        var options = {
          'key': response.data['razorpay_key'],
          'amount': response.data['amount'],
          'name': 'Easy Saloon',
          'description': 'Add money to Wallet',
          'order_id': response.data['order_id'],
          'prefill': {
            'contact': '',
            'email': ''
          },
          'notes': {
             'type': 'wallet_recharge',
             'amount': amount.toString()
          }
        };

        _razorpay.open(options);
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Could not initiate payment');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to initiate payment');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.primary)), barrierDismissible: false);
    
    // Extract the original amount requested from some state or if we assume the amount controller has it
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    try {
      final verifyResponse = await _apiService.dio.post('/wallet/verify-payment', data: {
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
        'amount': amount,
      });

      Get.back(); // Close loading
      
      if (verifyResponse.data['status'] == 'success') {
        Get.snackbar('Success', 'Money added to wallet successfully!', backgroundColor: Colors.green, colorText: Colors.white);
        _amountController.clear();
        _fetchWalletData(); // Refresh data
      } else {
        Get.snackbar('Error', verifyResponse.data['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Payment verification failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar('Payment Failed', response.message ?? 'Unknown error occurred', backgroundColor: Colors.redAccent, colorText: Colors.white);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar('External Wallet', 'Selected wallet: ${response.walletName}');
  }

  void _showAddMoneySheet() {
    _amountController.clear();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add Money to Wallet",
              style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
            ),
            SizedBox(height: 24.h),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  prefixStyle: TextStyle(color: AppColors.primary, fontSize: 24.sp, fontWeight: FontWeight.bold),
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 24.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAmountChip('500'),
                _buildAmountChip('1000'),
                _buildAmountChip('2000'),
                _buildAmountChip('5000'),
              ],
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => _addMoney(_amountController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Proceed to Pay", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAmountChip(String amount) {
    return GestureDetector(
      onTap: () {
        _amountController.text = amount;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text("₹$amount", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
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
          "My Wallet",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWalletCard(),
                    SizedBox(height: 32.h),
                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Available Balance",
                style: TextStyle(color: Colors.black54, fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.account_balance_wallet, color: Colors.black.withValues(alpha: 0.6)),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "₹ ${_balance.toStringAsFixed(2)}",
            style: TextStyle(color: Colors.black, fontSize: 36.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: _showAddMoneySheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Money", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Transactions",
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
              ),
              if (_transactions.length > 5)
                GestureDetector(
                  onTap: () => Get.toNamed('/wallet-transactions'),
                  child: Text(
                    "View All",
                    style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Text("No transactions yet", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length > 5 ? 5 : _transactions.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 24.h),
              itemBuilder: (context, index) {
                return _buildTransactionItem(_transactions[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    bool isCredit = tx['type'] == 'wallet_recharge';
    DateTime date = DateTime.tryParse(tx['created_at']) ?? DateTime.now();
    String formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green : Colors.redAccent,
            size: 20,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx['description'] ?? (isCredit ? 'Wallet Recharge' : 'Payment for Booking'),
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.white38, fontSize: 11.sp),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          "${isCredit ? '+' : '-'} ₹${tx['amount']}",
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.redAccent,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
