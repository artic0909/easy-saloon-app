import 'package:easysaloonapp/core/network/api_service.dart';
import '../../services/models/service_model.dart';

class PackageModel {
  final int id;
  final String name;
  final String slug;
  final String details;
  final double originalPrice;
  final double salePrice;
  final int isActive;
  final String? image;
  final String? uniqueId;
  final List<PackageItemModel> items;

  PackageModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.details,
    required this.originalPrice,
    required this.salePrice,
    required this.isActive,
    this.image,
    this.uniqueId,
    required this.items,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    String? resolvedImage = json['image'];
    if (resolvedImage != null && !resolvedImage.startsWith('http')) {
      // Prepend the storage URL if it's a relative path
      // Strip 'api' from baseUrl and append 'storage/'
      final storageBaseUrl = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '/storage/');
      resolvedImage = '$storageBaseUrl$resolvedImage';
    }

    var itemsList = json['items'] as List? ?? [];
    List<PackageItemModel> parsedItems = itemsList.map((e) => PackageItemModel.fromJson(e)).toList();

    return PackageModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      details: json['details'] ?? '',
      originalPrice: double.tryParse(json['original_price'].toString()) ?? 0.0,
      salePrice: double.tryParse(json['sale_price'].toString()) ?? 0.0,
      isActive: json['is_active'] ?? 1,
      image: resolvedImage,
      uniqueId: json['unique_id'],
      items: parsedItems,
    );
  }
}

class PackageItemModel {
  final int id;
  final int packageId;
  final int serviceId;
  final ServiceModel? service;

  PackageItemModel({
    required this.id,
    required this.packageId,
    required this.serviceId,
    this.service,
  });

  factory PackageItemModel.fromJson(Map<String, dynamic> json) {
    return PackageItemModel(
      id: json['id'],
      packageId: json['package_id'],
      serviceId: json['service_id'],
      service: json['service'] != null ? ServiceModel.fromJson(json['service']) : null,
    );
  }
}
