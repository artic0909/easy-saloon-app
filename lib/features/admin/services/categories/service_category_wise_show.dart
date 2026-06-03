import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_service_controller.dart';
import '../models/category_model.dart';
import 'service_add_edit.dart';

class ServiceCategoryWiseShowScreen extends StatefulWidget {
  final CategoryModel category;

  const ServiceCategoryWiseShowScreen({Key? key, required this.category}) : super(key: key);

  @override
  _ServiceCategoryWiseShowScreenState createState() => _ServiceCategoryWiseShowScreenState();
}

class _ServiceCategoryWiseShowScreenState extends State<ServiceCategoryWiseShowScreen> {
  final AdminServiceController controller = Get.find<AdminServiceController>();

  @override
  void initState() {
    super.initState();
    controller.fetchServicesByCategory(widget.category.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.name} Services'),
      ),
      body: Obx(() {
        if (controller.isLoadingServices.value) {
          return Center(child: CircularProgressIndicator());
        }
        if (controller.services.isEmpty) {
          return Center(child: Text('No services found in this category.'));
        }
        return ListView.builder(
          itemCount: controller.services.length,
          itemBuilder: (context, index) {
            final service = controller.services[index];
            return ListTile(
              leading: service.images != null && service.images!.isNotEmpty
                  ? Image.network(service.images![0], width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.design_services))
                  : Icon(Icons.design_services),
              title: Text(service.name),
              subtitle: Text('\$${service.salePrice} - ${service.durationMinutes} mins'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Get.to(() => ServiceAddEditScreen(
                            categoryId: widget.category.id!,
                            service: service,
                          ));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, service.id!, widget.category.id!);
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
          Get.to(() => ServiceAddEditScreen(categoryId: widget.category.id!));
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int serviceId, int categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Service'),
        content: Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteService(serviceId, categoryId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
