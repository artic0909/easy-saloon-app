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
  
  DateTime? _fromDate;
  DateTime? _toDate;

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

  List<dynamic> get _filteredTransactions {
    return _transactions.where((tx) {
      if (_fromDate == null && _toDate == null) return true;
      DateTime txDate = DateTime.tryParse(tx['created_at']) ?? DateTime.now();
      
      bool afterFrom = true;
      if (_fromDate != null) {
        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        afterFrom = txDate.isAfter(from) || txDate.isAtSameMomentAs(from);
      }
      
      bool beforeTo = true;
      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        beforeTo = txDate.isBefore(to) || txDate.isAtSameMomentAs(to);
      }
      
      return afterFrom && beforeTo;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate 
        ? (_fromDate ?? DateTime.now()) 
        : (_toDate ?? DateTime.now());
        
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Ensure toDate is not before fromDate
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedTxs = _filteredTransactions;
    
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
          : Column(
              children: [
                _buildDateFilters(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _fetchTransactions,
                    child: displayedTxs.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 100.h),
                              Center(
                                child: Text("No transactions found", style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(24.w),
                            itemCount: displayedTxs.length,
                            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 24.h),
                            itemBuilder: (context, index) {
                              return _buildTransactionItem(displayedTxs[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: "From",
              date: _fromDate,
              onTap: () => _selectDate(context, true),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildDateButton(
              label: "To",
              date: _toDate,
              onTap: () => _selectDate(context, false),
            ),
          ),
          if (_fromDate != null || _toDate != null) ...[
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
              },
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDateButton({required String label, required DateTime? date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: date != null ? AppColors.primary : Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                SizedBox(height: 2.h),
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select Date',
                  style: TextStyle(color: date != null ? Colors.white : Colors.white38, fontSize: 12.sp, fontWeight: date != null ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
            Icon(Icons.calendar_today, color: date != null ? AppColors.primary : Colors.white38, size: 16),
          ],
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
