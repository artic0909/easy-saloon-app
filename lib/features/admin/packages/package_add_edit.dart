import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';
import 'controllers/admin_package_controller.dart';
import 'models/package_model.dart';


class PackageAddEditScreen extends StatefulWidget {
  final PackageModel? package;

  const PackageAddEditScreen({super.key, this.package});

  @override
  State<PackageAddEditScreen> createState() => _PackageAddEditScreenState();
}

class _PackageAddEditScreenState extends State<PackageAddEditScreen> {
  final AdminPackageController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _detailsController;
  late TextEditingController _originalPriceController;
  late TextEditingController _salePriceController;

  bool _isActive = true;
  List<int> _selectedServiceIds = [];
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name ?? '');
    _detailsController = TextEditingController(text: widget.package?.details ?? '');
    _originalPriceController = TextEditingController(text: widget.package?.originalPrice.toString() ?? '');
    _salePriceController = TextEditingController(text: widget.package?.salePrice.toString() ?? '');
    
    if (widget.package != null) {
      _isActive = widget.package!.isActive == 1;
      _selectedServiceIds = widget.package!.items.map((i) => i.serviceId).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _originalPriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _updateOriginalPrice() {
    double total = 0;
    for (var service in controller.allServices) {
      if (service.id != null && _selectedServiceIds.contains(service.id)) {
        total += service.salePrice;
      }
    }
    _originalPriceController.text = total.toString();
  }

  void _showServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        "Select Services",
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoadingServices.value) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }

                        // Group services by category
                        final groupedServices = <String, List<dynamic>>{};
                        for (var service in controller.allServices) {
                          final categoryName = service.category?.name ?? 'Uncategorized';
                          if (!groupedServices.containsKey(categoryName)) {
                            groupedServices[categoryName] = [];
                          }
                          groupedServices[categoryName]!.add(service);
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: groupedServices.length,
                          itemBuilder: (context, index) {
                            final categoryName = groupedServices.keys.elementAt(index);
                            final services = groupedServices[categoryName]!;

                            return Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                iconColor: AppColors.primary,
                                collapsedIconColor: Colors.white54,
                                title: Text(
                                  categoryName,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                children: services.map((service) {
                                  final isSelected = _selectedServiceIds.contains(service.id);
                                  return CheckboxListTile(
                                    title: Text(service.name, style: const TextStyle(color: Colors.white)),
                                    subtitle: Text("₹${service.salePrice}", style: const TextStyle(color: Colors.white54)),
                                    activeColor: AppColors.primary,
                                    checkColor: Colors.black,
                                    value: isSelected,
                                    onChanged: (bool? checked) {
                                      setModalState(() {
                                        if (service.id != null) {
                                          if (checked == true) {
                                            _selectedServiceIds.add(service.id!);
                                          } else {
                                            _selectedServiceIds.remove(service.id!);
                                          }
                                        }
                                      });
                                      _updateOriginalPrice();
                                      setState(() {}); // Update parent UI
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          onPressed: () => Get.back(),
                          child: const Text("Done", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )
                  ],
                );
              }
            );
          },
        );
      },
    );
  }

  void _savePackage() {
    if (_formKey.currentState!.validate()) {
      if (_selectedServiceIds.isEmpty) {
        Get.snackbar("Error", "Please select at least one service.");
        return;
      }
      controller.savePackage(
        id: widget.package?.id,
        name: _nameController.text.trim(),
        details: _detailsController.text.trim(),
        originalPrice: double.tryParse(_originalPriceController.text) ?? 0.0,
        salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
        serviceIds: _selectedServiceIds,
        newImage: _selectedImage,
        existingImage: widget.package?.image,
        isActive: _isActive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.package == null ? "Add Package" : "Edit Package",
          style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isSavingPackage.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Package Name", _nameController, isRequired: true),
                SizedBox(height: 16.h),
                _buildTextField("Details / Description", _detailsController, maxLines: 3, isRequired: true),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Original Price", _originalPriceController, isNumber: true)),
                    SizedBox(width: 16.w),
                    Expanded(child: _buildTextField("Sale Price", _salePriceController, isNumber: true, isRequired: true)),
                  ],
                ),
                SizedBox(height: 16.h),
                
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Is Active", style: TextStyle(color: Colors.white)),
                  activeColor: AppColors.primary,
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                SizedBox(height: 16.h),

                InkWell(
                  onTap: _showServicesBottomSheet,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Services (${_selectedServiceIds.length} selected)",
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                Text("Package Image", style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 150.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.hardEdge,
                            child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                          )
                        : widget.package?.image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.hardEdge,
                                child: Image.network(widget.package!.image!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 40),
                                  SizedBox(height: 8.h),
                                  const Text("Tap to select image", style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                  ),
                ),
                SizedBox(height: 32.h),

                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _savePackage,
                    child: const Text("Save Package", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: isRequired ? (value) => value!.isEmpty ? 'This field is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
