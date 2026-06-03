import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/admin_service_controller.dart';
import '../models/category_model.dart';

class CategoryAddEditScreen extends StatefulWidget {
  final CategoryModel? category;

  const CategoryAddEditScreen({super.key, this.category});

  @override
  // ignore: library_private_types_in_public_api
  _CategoryAddEditScreenState createState() => _CategoryAddEditScreenState();
}

class _CategoryAddEditScreenState extends State<CategoryAddEditScreen> {
  final AdminServiceController controller = Get.find<AdminServiceController>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      controller.saveCategory(
        id: widget.category?.id,
        name: _nameController.text,
        image: _imageFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                      : (widget.category?.image != null
                          ? Image.network(widget.category!.image!, fit: BoxFit.cover)
                          : Center(child: Text('Tap to select image'))),
                ),
              ),
              SizedBox(height: 24),
              Obx(() => ElevatedButton(
                    onPressed: controller.isSavingCategory.value ? null : _saveCategory,
                    child: controller.isSavingCategory.value
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Save'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
