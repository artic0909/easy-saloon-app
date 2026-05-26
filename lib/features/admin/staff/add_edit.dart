import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:dio/dio.dart' as dio_pkg;

class AdminAddEditStaffScreen extends StatefulWidget {
  const AdminAddEditStaffScreen({super.key});

  @override
  State<AdminAddEditStaffScreen> createState() => _AdminAddEditStaffScreenState();
}

class _AdminAddEditStaffScreenState extends State<AdminAddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  dynamic _staff;
  bool get _isEditing => _staff != null;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _staff = Get.arguments;
    if (_isEditing) {
      _nameController.text = _staff['name']?.toString() ?? '';
      _emailController.text = _staff['email']?.toString() ?? '';
      _phoneController.text = _staff['phone']?.toString() ?? '';
      _designationController.text = _staff['designation']?.toString() ?? '';
      _experienceController.text = _staff['experience_years']?.toString() ?? '0';
      _bioController.text = _staff['bio']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'designation': _designationController.text.trim(),
      'experience_years': int.tryParse(_experienceController.text.trim()) ?? 0,
      'bio': _bioController.text.trim(),
    };

    if (_passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    }

    if (_isEditing) {
      data['_method'] = 'PUT';
    }

    try {
      final response = _isEditing
          ? await _apiService.dio.post('/admin/staffs/${_staff['id']}', data: data)
          : await _apiService.dio.post('/admin/staffs', data: data);

      if (response.data['status'] == 'success') {
        Get.back();
        Get.snackbar(
          "Success",
          _isEditing ? "Staff updated successfully" : "Staff added successfully",
          backgroundColor: const Color(0xFF2E7D32),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      String message = "Failed to save staff information.";
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
          _isEditing ? "Edit Staff" : "Add Staff",
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
                    _buildSectionHeader("Personal Details"),
                    SizedBox(height: 16.h),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person,
                      validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Email is required";
                        if (!GetUtils.isEmail(val)) return "Enter a valid email address";
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty ? "Phone number is required" : null,
                    ),
                    SizedBox(height: 16.h),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (val) {
                        if (!_isEditing && (val == null || val.isEmpty)) return "Password is required for new staff";
                        if (val != null && val.isNotEmpty && val.length < 8) return "Password must be at least 8 characters";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: _isEditing ? "New Password (Optional)" : "Password",
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: AppColors.primary)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: Colors.redAccent)),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    _buildSectionHeader("Professional Details"),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _designationController,
                      label: "Designation (e.g. Senior Stylist)",
                      icon: Icons.work,
                      textCapitalization: TextCapitalization.words,
                      validator: (val) => val == null || val.isEmpty ? "Designation is required" : null,
                    ),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _experienceController,
                      label: "Experience (Years)",
                      icon: Icons.timeline,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || val.isEmpty ? "Experience is required" : null,
                    ),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _bioController,
                      label: "Short Bio",
                      icon: Icons.description,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveStaff,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        ),
                        child: Text(
                          _isEditing ? "Update Staff Member" : "Add Staff Member",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
