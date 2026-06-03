import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../../../core/network/api_service.dart';
import '../models/package_model.dart';
import '../../services/models/service_model.dart';
import 'package:image_picker/image_picker.dart';

class AdminPackageController extends GetxController {
  final ApiService _apiService = ApiService();
  
  var packages = <PackageModel>[].obs;
  var allServices = <ServiceModel>[].obs;
  
  var isLoadingPackages = false.obs;
  var isLoadingServices = false.obs;
  
  var isSavingPackage = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
    fetchServices();
  }

  Future<void> fetchPackages() async {
    isLoadingPackages.value = true;
    try {
      final response = await _apiService.dio.get('/admin/packages');
      if (response.statusCode == 200) {
        final List data = response.data['packages'] ?? [];
        packages.value = data.map((e) => PackageModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch packages: $e');
    } finally {
      isLoadingPackages.value = false;
    }
  }

  Future<void> fetchServices() async {
    isLoadingServices.value = true;
    try {
      final response = await _apiService.dio.get('/admin/services');
      if (response.statusCode == 200) {
        final List data = response.data['services'] ?? [];
        allServices.value = data.map((e) => ServiceModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch services: $e');
    } finally {
      isLoadingServices.value = false;
    }
  }

  Future<void> savePackage({
    int? id,
    required String name,
    required String details,
    required double originalPrice,
    required double salePrice,
    required List<int> serviceIds,
    XFile? newImage,
    String? existingImage,
    bool isActive = true,
  }) async {
    isSavingPackage.value = true;
    try {
      Map<String, dynamic> dataMap = {
        'name': name,
        'details': details,
        'original_price': originalPrice,
        'sale_price': salePrice,
        'is_active': isActive ? 1 : 0,
        if (id != null) '_method': 'PUT',
      };
      
      for (int i = 0; i < serviceIds.length; i++) {
        dataMap['services[$i]'] = serviceIds[i];
      }
      
      if (existingImage != null) {
        String img = existingImage;
        if (img.startsWith('https://test.sumatrasales.com/storage/')) {
          img = img.replaceFirst('https://test.sumatrasales.com/storage/', '');
        }
        dataMap['existing_image'] = img;
      }

      dio.FormData formData = dio.FormData.fromMap(dataMap);
      
      if (newImage != null) {
        formData.files.add(MapEntry(
          'image',
          await dio.MultipartFile.fromFile(newImage.path, filename: newImage.name),
        ));
      }

      dio.Response response;
      if (id == null) {
        response = await _apiService.dio.post('/admin/packages', data: formData);
      } else {
        response = await _apiService.dio.post('/admin/packages/$id', data: formData);
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('Success', 'Package saved successfully');
        fetchPackages();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save package: $e');
    } finally {
      isSavingPackage.value = false;
    }
  }

  Future<void> deletePackage(int id) async {
    try {
      final response = await _apiService.dio.post(
        '/admin/packages/$id',
        data: {'_method': 'DELETE'},
      );
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Package deleted successfully');
        fetchPackages();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete package: $e');
    }
  }
}
