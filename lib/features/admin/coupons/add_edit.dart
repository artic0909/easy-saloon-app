import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio_pkg;

class AdminAddEditCouponScreen extends StatefulWidget {
  const AdminAddEditCouponScreen({super.key});

  @override
  State<AdminAddEditCouponScreen> createState() => _AdminAddEditCouponScreenState();
}

class _AdminAddEditCouponScreenState extends State<AdminAddEditCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  dynamic _coupon;
  bool get _isEditing => _coupon != null;

  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderAmountController = TextEditingController();
  
  String _discountType = 'percentage';
  DateTime? _expiryDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _coupon = Get.arguments;
    if (_isEditing) {
      _codeController.text = _coupon['code']?.toString() ?? '';
      _titleController.text = _coupon['title']?.toString() ?? '';
      _discountValueController.text = _coupon['discount_value']?.toString() ?? '';
      _minOrderAmountController.text = _coupon['min_order_amount']?.toString() ?? '';
      _discountType = _coupon['discount_type']?.toString() == 'fixed' ? 'fixed' : 'percentage';
      _isActive = _coupon['is_active'] == 1 || _coupon['is_active'] == true;
      
      if (_coupon['expiry_date'] != null) {
        try {
          _expiryDate = DateTime.parse(_coupon['expiry_date'].toString());
        } catch (e) {
          // ignore parsing error
        }
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _discountValueController.dispose();
    _minOrderAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
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
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'code': _codeController.text.trim().toUpperCase(),
      'title': _titleController.text.trim(),
      'discount_type': _discountType,
      'discount_value': double.tryParse(_discountValueController.text.trim()) ?? 0,
      'min_order_amount': double.tryParse(_minOrderAmountController.text.trim()) ?? 0,
      'is_active': _isActive ? 1 : 0,
    };

    if (_expiryDate != null) {
      data['expiry_date'] = DateFormat('yyyy-MM-dd').format(_expiryDate!);
    } else {
      data['expiry_date'] = null;
    }

    if (_isEditing) {
      data['_method'] = 'PUT';
    }

    try {
      final response = _isEditing
          ? await _apiService.dio.post('/admin/coupons/${_coupon['id']}', data: data)
          : await _apiService.dio.post('/admin/coupons', data: data);

      if (response.data['status'] == 'success') {
        Get.back();
        Get.snackbar(
          "Success",
          _isEditing ? "Offer updated successfully" : "Offer created successfully",
          backgroundColor: const Color(0xFF2E7D32),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      String message = "Failed to save offer. Please check your inputs.";
      if (e is dio_pkg.DioException && e.response?.data != null) {
        message = e.response!.data['message'] ?? message;
      }
      Get.snackbar(
        "Error",
        message,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _isEditing ? "Edit Offer" : "Create Offer",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Offer Details"),
                    SizedBox(height: 16.h),
                    
                    // Code
                    _buildTextField(
                      controller: _codeController,
                      label: "Coupon Code (e.g. SUMMER50)",
                      icon: Icons.vpn_key,
                      validator: (val) => val == null || val.isEmpty ? "Code is required" : null,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    SizedBox(height: 16.h),
                    
                    // Title
                    _buildTextField(
                      controller: _titleController,
                      label: "Offer Title",
                      icon: Icons.title,
                      validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                    ),
                    SizedBox(height: 24.h),
                    
                    _buildSectionHeader("Discount Settings"),
                    SizedBox(height: 16.h),

                    // Discount Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _discountType,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Discount Type", Icons.local_offer),
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _discountType = val);
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Discount Value
                    _buildTextField(
                      controller: _discountValueController,
                      label: _discountType == 'percentage' ? "Discount Percentage (%)" : "Discount Amount (₹)",
                      icon: _discountType == 'percentage' ? Icons.percent : Icons.currency_rupee,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Value is required";
                        if (double.tryParse(val) == null) return "Enter a valid number";
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionHeader("Requirements & Limits"),
                    SizedBox(height: 16.h),

                    // Min Order Amount
                    _buildTextField(
                      controller: _minOrderAmountController,
                      label: "Minimum Order Amount (₹)",
                      icon: Icons.shopping_cart,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 16.h),

                    // Expiry Date
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Expiry Date", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _expiryDate == null ? "No Expiry" : DateFormat('dd MMM yyyy').format(_expiryDate!),
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                            if (_expiryDate != null)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                                onPressed: () => setState(() => _expiryDate = null),
                              )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Status Toggle
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(_isActive ? Icons.check_circle : Icons.cancel, 
                                  color: _isActive ? Colors.green : Colors.white30),
                              SizedBox(width: 12.w),
                              Text("Active Status", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        ),
                        child: Text(
                          _isEditing ? "Update Offer" : "Create Offer",
                          style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(label, icon),
    );
  }
}
