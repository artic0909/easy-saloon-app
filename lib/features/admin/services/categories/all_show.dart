import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_service_controller.dart';
import 'add_edit.dart';
import 'service_category_wise_show.dart';

class CategoryListScreen extends StatelessWidget {
  CategoryListScreen({super.key});

  final AdminServiceController controller = Get.put(AdminServiceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Categories'),
      ),
      body: Obx(() {
        if (controller.isLoadingCategories.value) {
          return Center(child: CircularProgressIndicator());
        }
        if (controller.categories.isEmpty) {
          return Center(child: Text('No categories found.'));
        }
        return ListView.builder(
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            return ListTile(
              leading: category.image != null
                  ? Image.network(category.image!, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.category))
                  : Icon(Icons.category),
              title: Text(category.name),
              onTap: () {
                Get.to(() => ServiceCategoryWiseShowScreen(category: category));
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Get.to(() => CategoryAddEditScreen(category: category));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, category.id!);
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => CategoryAddEditScreen());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteCategory(id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
