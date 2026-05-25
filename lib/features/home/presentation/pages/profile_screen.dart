import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'package:easysaloonapp/core/network/api_service.dart';
import 'package:easysaloonapp/core/widgets/app_bottom_nav.dart';
import 'package:easysaloonapp/core/widgets/app_drawer.dart';
import 'package:easysaloonapp/features/auth/data/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService authService = Get.find<AuthService>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _addressFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _activeSegment = 0; // 0: Profile Settings, 1: Saved Addresses
  bool _isLoading = false;
  bool _isFetchingAddresses = true;
  bool _isPrimaryAddress = false;
  int? _editingAddressId;
  File? _profileImage;
  List<dynamic> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _landmarkController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final userData = authService.userData;
    _nameController.text = userData['name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
  }

  Future<void> _fetchAddresses() async {
    if (!mounted) return;
    setState(() => _isFetchingAddresses = true);
    debugPrint("=== DEBUG: Fetching Addresses ===");
    debugPrint("=== DEBUG: Current User Data: ${authService.userData}");
    try {
      final response = await _apiService.dio.get('/profile/addresses');
      debugPrint("=== DEBUG: Addresses Response Status: ${response.statusCode}");
      debugPrint("=== DEBUG: Addresses Response Data: ${response.data}");
      
      if (response.data['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _addresses = response.data['data'] ?? [];
          _isFetchingAddresses = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isFetchingAddresses = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingAddresses = false);
      debugPrint("=== DEBUG: Error fetching addresses: $e");
      if (e is DioException) {
        debugPrint("=== DEBUG: Dio Error Response: ${e.response?.data}");
        debugPrint("=== DEBUG: Dio Error Status Code: ${e.response?.statusCode}");
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      Get.snackbar(
        "Error",
        "Failed to pick image",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _showImagePickerOptions() {
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
              "Select Image Source",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Playfair Display',
              ),
            ),
            SizedBox(height: 24.h),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary, size: 24.sp),
              title: Text("Camera", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary, size: 24.sp),
              title: Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> dataMap = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      if (_profileImage != null) {
        dataMap['photo'] = await MultipartFile.fromFile(
          _profileImage!.path,
          filename: _profileImage!.path.split('/').last,
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _apiService.dio.post('/profile/update', data: formData);

      if (response.data['status'] == 'success') {
        await authService.refreshProfile();
        setState(() {
          _profileImage = null; // Clear picked image file after save
        });
        Get.snackbar(
          "Success",
          "Profile updated successfully!",
          backgroundColor: AppColors.surface,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          response.data['message'] ?? "Failed to update profile",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      Get.snackbar(
        "Error",
        "Failed to update profile info",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddressFormSheet(dynamic address) {
    final bool isEdit = address != null;
    _editingAddressId = isEdit ? address['id'] : null;

    _titleController.text = isEdit ? (address['title'] ?? '') : '';
    _landmarkController.text = isEdit ? (address['landmark'] ?? '') : '';
    _fullAddressController.text = isEdit ? (address['full_address'] ?? '') : '';
    _cityController.text = isEdit ? (address['city']?['name'] ?? '') : '';
    _stateController.text = isEdit ? (address['state']?['name'] ?? '') : '';
    _countryController.text = isEdit ? (address['country']?['name'] ?? '') : '';
    _isPrimaryAddress = isEdit ? (address['is_primary'] == 1 ||
                                  address['is_primary'] == true ||
                                  address['is_primary']?.toString() == '1' ||
                                  address['is_primary']?.toString() == 'true') : false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 24.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              child: Form(
                key: _addressFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? "Edit Address" : "Add New Address",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Playfair Display',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    _buildTextField(
                      controller: _titleController,
                      label: "ADDRESS TITLE (E.G. HOME, WORK)",
                      hint: "e.g. Home, Work",
                      validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                    ),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _landmarkController,
                      label: "LANDMARK (OPTIONAL)",
                      hint: "e.g. Near Central Park",
                    ),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _fullAddressController,
                      label: "FULL ADDRESS",
                      hint: "e.g. 123 Luxury Street, Apartment 4B",
                      validator: (val) => val == null || val.isEmpty ? "Full address is required" : null,
                    ),
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _cityController,
                      label: "CITY",
                      hint: "e.g. New Delhi",
                      validator: (val) => val == null || val.isEmpty ? "City is required" : null,
                    ),
                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: "STATE",
                            hint: "e.g. Delhi",
                            validator: (val) => val == null || val.isEmpty ? "State is required" : null,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _countryController,
                            label: "COUNTRY",
                            hint: "e.g. India",
                            validator: (val) => val == null || val.isEmpty ? "Country is required" : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    Row(
                      children: [
                        Checkbox(
                          value: _isPrimaryAddress,
                          activeColor: AppColors.primary,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white30, width: 2),
                          onChanged: (val) {
                            setModalState(() {
                              _isPrimaryAddress = val ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _isPrimaryAddress = !_isPrimaryAddress;
                            });
                          },
                          child: Text(
                            "Set as primary address",
                            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _saveAddress(setModalState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                isEdit ? "Update Address" : "Save Address",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15.sp),
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          );
        }
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _saveAddress(void Function(void Function()) setModalState) async {
    if (!_addressFormKey.currentState!.validate()) return;

    setModalState(() => _isLoading = true);
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.dio.post('/profile/addresses/save', data: {
        if (_editingAddressId != null) 'address_id': _editingAddressId,
        'title': _titleController.text,
        'full_address': _fullAddressController.text,
        'landmark': _landmarkController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'is_primary': _isPrimaryAddress,
      });

      if (response.data['status'] == 'success') {
        Get.back();
        Get.snackbar(
          "Success",
          response.data['message'] ?? "Address saved successfully",
          backgroundColor: AppColors.surface,
          colorText: Colors.white,
        );
        _fetchAddresses();
      } else {
        Get.snackbar(
          "Error",
          response.data['message'] ?? "Failed to save address",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error saving address: $e");
      Get.snackbar(
        "Error",
        "Failed to connect to the server",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setModalState(() => _isLoading = false);
        setState(() => _isLoading = false);
      }
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
          "My Profile",
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20.sp,
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
          SizedBox(height: 12.h),
          _buildSegmentSelector(),
          SizedBox(height: 16.h),
          Expanded(
            child: Obx(() {
              // Read userData to trigger rebuild if updated in AuthServices
              final _ = authService.userData.length;
              
              if (_activeSegment == 0) {
                return _buildProfileSettingsForm();
              } else {
                return _buildSavedAddressesSection();
              }
            }),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4, // Profile/Drawer
        onTap: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 0) {
            Get.offAllNamed('/home');
          } else if (index == 1) {
            Get.offNamed('/my-bookings');
          } else if (index == 2) {
            Get.offNamed('/packages');
          } else if (index == 3) {
            Get.offNamed('/services');
          }
        },
      ),
    );
  }

  Widget _buildSegmentSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSegment = 0),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _activeSegment == 0 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Profile Settings",
                    style: TextStyle(
                      color: _activeSegment == 0 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSegment = 1),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _activeSegment == 1 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Saved Addresses",
                    style: TextStyle(
                      color: _activeSegment == 1 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSettingsForm() {
    final userData = authService.userData;
    final photoUrl = userData['photo'];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: AppColors.surface,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!) as ImageProvider
                        : (photoUrl != null
                            ? NetworkImage("https://test.sumatrasales.com/storage/$photoUrl") as ImageProvider
                            : null),
                    child: _profileImage == null && photoUrl == null
                        ? Text(
                            (userData['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(color: Colors.white, fontSize: 36.sp, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.black, size: 20.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Update Profile Photo",
              style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            SizedBox(height: 32.h),

            _buildTextField(
              controller: _nameController,
              label: "FULL NAME",
              hint: "Enter your full name",
              validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
            ),
            SizedBox(height: 20.h),

            _buildTextField(
              controller: _emailController,
              label: "EMAIL ADDRESS",
              hint: "Enter your email address",
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) return "Email is required";
                if (!GetUtils.isEmail(val)) return "Invalid email address";
                return null;
              },
            ),
            SizedBox(height: 20.h),

            _buildTextField(
              controller: _phoneController,
              label: "PHONE NUMBER",
              hint: "Enter your phone number",
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 40.h),

            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15.sp),
                      ),
              ),
            ),
            SizedBox(height: 24.h),
            TextButton(
              onPressed: _showChangePasswordSheet,
              child: Text(
                "Change Password",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressesSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delivery & Service Locations",
                style: TextStyle(color: Colors.white54, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                onTap: () => _showAddressFormSheet(null),
                child: Row(
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 18.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Add New",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isFetchingAddresses
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _addresses.isEmpty
                  ? _buildEmptyAddressesState()
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, __) => SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return _buildAddressCard(address);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(dynamic address) {
    final bool isPrimary = address['is_primary'] == 1 ||
                           address['is_primary'] == true ||
                           address['is_primary']?.toString() == '1' ||
                           address['is_primary']?.toString() == 'true';
    final String title = address['title'] ?? 'Address';
    final String fullAddress = address['full_address'] ?? '';
    final String cityName = address['city']?['name'] ?? '';
    final String stateName = address['state']?['name'] ?? '';
    final String countryName = address['country']?['name'] ?? '';
    
    IconData titleIcon = Icons.location_on;
    if (title.toLowerCase() == 'home') {
      titleIcon = Icons.home;
    } else if (title.toLowerCase() == 'work' || title.toLowerCase() == 'office') {
      titleIcon = Icons.work;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(titleIcon, color: AppColors.primary, size: 22.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    if (isPrimary) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "PRIMARY",
                          style: TextStyle(color: AppColors.primary, fontSize: 8.sp, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                    ]
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  fullAddress,
                  style: TextStyle(color: Colors.white54, fontSize: 13.sp, height: 1.4),
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: [
                    if (cityName.isNotEmpty) _buildLocationBadge(cityName),
                    if (stateName.isNotEmpty) _buildLocationBadge(stateName),
                    if (countryName.isNotEmpty) _buildLocationBadge(countryName),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddressFormSheet(address),
                      icon: Icon(Icons.edit_outlined, size: 14.sp, color: AppColors.primary),
                      label: Text("Edit", style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEmptyAddressesState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 50.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: Colors.white10),
            SizedBox(height: 16.h),
            Text(
              "No addresses saved yet",
              style: TextStyle(color: Colors.white38, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => _showAddressFormSheet(null),
              child: Text(
                "Add your first address",
                style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordSheet() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: 24.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Change Password",
                        style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  _buildPasswordField("Current Password", _currentPasswordController, obscureCurrent, () => setModalState(() => obscureCurrent = !obscureCurrent)),
                  SizedBox(height: 16.h),
                  _buildPasswordField("New Password", _newPasswordController, obscureNew, () => setModalState(() => obscureNew = !obscureNew)),
                  SizedBox(height: 16.h),
                  _buildPasswordField("Confirm New Password", _confirmPasswordController, obscureConfirm, () => setModalState(() => obscureConfirm = !obscureConfirm)),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
                          Get.snackbar("Error", "Please fill in all password fields.", backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }
                        if (_currentPasswordController.text == _newPasswordController.text) {
                          Get.snackbar("Error", "New password cannot be the same as your current password.", backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }
                        if (_newPasswordController.text != _confirmPasswordController.text) {
                          Get.snackbar("Error", "Confirm password does not match with the new password.", backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }
                        if (_newPasswordController.text.length < 8) {
                          Get.snackbar("Error", "New password must be at least 8 characters long.", backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }

                        setModalState(() => isLoading = true);
                        try {
                          final response = await _apiService.dio.post('/profile/change-password', data: {
                            'current_password': _currentPasswordController.text,
                            'new_password': _newPasswordController.text,
                          });
                          
                          if (response.data['status'] == 'success') {
                            Get.back();
                            Get.snackbar("Success", response.data['message'], backgroundColor: AppColors.surface, colorText: Colors.white);
                          } else {
                            Get.snackbar("Error", response.data['message'], backgroundColor: Colors.redAccent, colorText: Colors.white);
                          }
                        } catch (e) {
                          Get.snackbar("Error", "Failed to change password", backgroundColor: Colors.redAccent, colorText: Colors.white);
                        } finally {
                          if (mounted) setModalState(() => isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text("Update Password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscureText, VoidCallback toggleObscure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white38, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter $label",
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              suffixIcon: IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: toggleObscure,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
