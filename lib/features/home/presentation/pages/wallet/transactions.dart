import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  State<WalletTransactionsScreen> createState() => _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.dio.get('/wallet');
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _transactions = response.data['data']['transactions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          "All Transactions",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchTransactions,
              child: _transactions.isEmpty
                  ? Center(
                      child: Text("No transactions yet", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(24.w),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 24.h),
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(_transactions[index]);
                      },
                    ),
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
