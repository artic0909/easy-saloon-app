import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/admin_service_controller.dart';
import '../models/service_model.dart';

class ServiceAddEditScreen extends StatefulWidget {
  final int categoryId;
  final ServiceModel? service;

  const ServiceAddEditScreen({Key? key, required this.categoryId, this.service}) : super(key: key);

  @override
  _ServiceAddEditScreenState createState() => _ServiceAddEditScreenState();
}

class _ServiceAddEditScreenState extends State<ServiceAddEditScreen> {
  final AdminServiceController controller = Get.find<AdminServiceController>();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  
  List<XFile> _newImages = [];
  List<String> _existingImages = [];
  
  List<TextEditingController> _whatIncludedControllers = [];
  List<int> _selectedEquipment = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _originalPriceController.text = widget.service!.originalPrice.toString();
      _salePriceController.text = widget.service!.salePrice.toString();
      _durationController.text = widget.service!.durationMinutes.toString();
      _detailsController.text = widget.service!.details ?? '';
      _existingImages = widget.service!.images ?? [];
      
      if (widget.service!.whatIncluded != null) {
        for (var item in widget.service!.whatIncluded!) {
          _whatIncludedControllers.add(TextEditingController(text: item));
        }
      }
      
      if (widget.service!.equipment != null) {
        _selectedEquipment = widget.service!.equipment!.map((e) => e.id!).toList();
      }
    }
  }

  void _addWhatIncludedField() {
    setState(() {
      _whatIncludedControllers.add(TextEditingController());
    });
  }

  void _removeWhatIncludedField(int index) {
    setState(() {
      _whatIncludedControllers.removeAt(index);
    });
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _saveService() {
    if (_formKey.currentState!.validate()) {
      controller.saveService(
        id: widget.service?.id,
        name: _nameController.text,
        categoryId: widget.categoryId,
        originalPrice: double.parse(_originalPriceController.text),
        salePrice: double.parse(_salePriceController.text),
        durationMinutes: int.parse(_durationController.text),
        details: _detailsController.text,
        whatIncluded: _whatIncludedControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
        equipment: _selectedEquipment,
        newImages: _newImages,
        existingImages: _existingImages,
      );
    }
  }

  void _showEquipmentMultiSelect() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Select Equipment'),
              content: Container(
                width: double.maxFinite,
                child: Obx(() {
                  if (controller.isLoadingEquipments.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (controller.equipments.isEmpty) {
                    return Text('No equipment available.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.equipments.length,
                    itemBuilder: (context, index) {
                      final equipment = controller.equipments[index];
                      final isSelected = _selectedEquipment.contains(equipment.id);
                      return CheckboxListTile(
                        title: Text(equipment.name),
                        value: isSelected,
                        onChanged: (bool? checked) {
                          setStateDialog(() {
                            if (checked == true) {
                              _selectedEquipment.add(equipment.id!);
                            } else {
                              _selectedEquipment.remove(equipment.id!);
                            }
                          });
                          setState(() {}); // Update main UI
                        },
                      );
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Service Name', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _originalPriceController,
                        decoration: InputDecoration(labelText: 'Original Price', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _salePriceController,
                        decoration: InputDecoration(labelText: 'Sale Price', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(labelText: 'Duration (Minutes)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _detailsController,
                  decoration: InputDecoration(labelText: 'Details (Optional)', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Divider(),
                Text('What is Included', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._whatIncludedControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              hintText: 'Included item...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeWhatIncludedField(entry.key),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                TextButton.icon(
                  onPressed: _addWhatIncludedField,
                  icon: Icon(Icons.add),
                  label: Text('Add Included Item'),
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Equipment (${_selectedEquipment.length} selected)', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: _showEquipmentMultiSelect,
                      child: Text('Select Equipment'),
                    ),
                  ],
                ),
                Divider(),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.photo_library),
                  label: Text('Add Images'),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._existingImages.asMap().entries.map((entry) => Stack(
                      children: [
                        Image.network(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(entry.key),
                            child: Container(
                              color: Colors.red,
                              child: Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )).toList(),
                    ..._newImages.asMap().entries.map((entry) => Stack(
                      children: [
                        Image.file(File(entry.value.path), width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(entry.key),
                            child: Container(
                              color: Colors.red,
                              child: Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
                SizedBox(height: 24),
                Obx(() => ElevatedButton(
                      onPressed: controller.isSavingService.value ? null : _saveService,
                      child: controller.isSavingService.value
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Save Service'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
