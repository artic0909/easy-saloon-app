import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../../../core/network/api_service.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import 'package:image_picker/image_picker.dart';

class AdminServiceController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var categories = <CategoryModel>[].obs;
  var services = <ServiceModel>[].obs;
  var equipments = <EquipmentModel>[].obs;
  
  var isLoadingCategories = false.obs;
  var isLoadingServices = false.obs;
  var isLoadingEquipments = false.obs;
  
  var isSavingCategory = false.obs;
  var isSavingService = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchEquipments();
  }

  Future<void> fetchEquipments() async {
    isLoadingEquipments.value = true;
    try {
      final response = await _apiService.dio.get('/admin/equipments');
      if (response.statusCode == 200) {
        final List data = response.data['equipments'] ?? [];
        equipments.value = data.map((e) => EquipmentModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch equipments: $e');
    } finally {
      isLoadingEquipments.value = false;
    }
  }

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final response = await _apiService.dio.get('/admin/categories');
      if (response.statusCode == 200) {
        final List data = response.data['categories'] ?? [];
        categories.value = data.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> saveCategory({int? id, required String name, XFile? image}) async {
    isSavingCategory.value = true;
    try {
      dio.FormData formData = dio.FormData.fromMap({
        'name': name,
        if (id != null) '_method': 'PUT',
      });
      
      if (image != null) {
        formData.files.add(MapEntry(
          'image',
          await dio.MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }

      dio.Response response;
      if (id == null) {
        response = await _apiService.dio.post('/admin/categories', data: formData);
      } else {
        response = await _apiService.dio.post('/admin/categories/$id', data: formData);
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('Success', 'Category saved successfully');
        fetchCategories();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save category: $e');
    } finally {
      isSavingCategory.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final response = await _apiService.dio.delete('/admin/categories/$id');
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Category deleted successfully');
        fetchCategories();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category: $e');
    }
  }

  Future<void> fetchServicesByCategory(int categoryId) async {
    isLoadingServices.value = true;
    try {
      final response = await _apiService.dio.get('/admin/services', queryParameters: {'category_id': categoryId});
      if (response.statusCode == 200) {
        final List data = response.data['services'] ?? [];
        services.value = data.map((e) => ServiceModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch services: $e');
    } finally {
      isLoadingServices.value = false;
    }
  }

  Future<void> saveService({
    int? id,
    required String name,
    required int categoryId,
    required double originalPrice,
    required double salePrice,
    required int durationMinutes,
    String? details,
    List<String>? whatIncluded,
    List<int>? equipment,
    List<XFile>? newImages,
    List<String>? existingImages,
  }) async {
    isSavingService.value = true;
    try {
      Map<String, dynamic> dataMap = {
        'name': name,
        'category_id': categoryId,
        'original_price': originalPrice,
        'sale_price': salePrice,
        'duration_minutes': durationMinutes,
        if (details != null) 'details': details,
        if (id != null) '_method': 'PUT',
      };
      
      if (whatIncluded != null) {
        for (int i = 0; i < whatIncluded.length; i++) {
          dataMap['what_included[$i]'] = whatIncluded[i];
        }
      }

      if (equipment != null) {
        for (int i = 0; i < equipment.length; i++) {
          dataMap['equipment[$i]'] = equipment[i];
        }
      }
      
      if (existingImages != null) {
        for (int i = 0; i < existingImages.length; i++) {
          dataMap['existing_images[$i]'] = existingImages[i];
        }
      }

      dio.FormData formData = dio.FormData.fromMap(dataMap);
      
      if (newImages != null) {
        for (var image in newImages) {
          formData.files.add(MapEntry(
            'images[]',
            await dio.MultipartFile.fromFile(image.path, filename: image.name),
          ));
        }
      }

      dio.Response response;
      if (id == null) {
        response = await _apiService.dio.post('/admin/services', data: formData);
      } else {
        response = await _apiService.dio.post('/admin/services/$id', data: formData);
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('Success', 'Service saved successfully');
        fetchServicesByCategory(categoryId);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save service: $e');
    } finally {
      isSavingService.value = false;
    }
  }

  Future<void> deleteService(int id, int categoryId) async {
    try {
      final response = await _apiService.dio.delete('/admin/services/$id');
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Service deleted successfully');
        fetchServicesByCategory(categoryId);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete service: $e');
    }
  }
}
