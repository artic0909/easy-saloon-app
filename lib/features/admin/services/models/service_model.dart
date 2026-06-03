import 'category_model.dart';

class EquipmentModel {
  final int? id;
  final String name;
  final String? image;

  EquipmentModel({this.id, required this.name, this.image});

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'];
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = 'https://test.sumatrasales.com/storage/$imageUrl';
    }
    return EquipmentModel(
      id: json['id'],
      name: json['name'] ?? '',
      image: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}

class ServiceModel {
  final int? id;
  final String name;
  final int categoryId;
  final String? uniqueId;
  final double originalPrice;
  final double salePrice;
  final int durationMinutes;
  final String? details;
  final List<String>? whatIncluded;
  final List<String>? images;
  final CategoryModel? category;
  final List<EquipmentModel>? equipment;

  ServiceModel({
    this.id,
    required this.name,
    required this.categoryId,
    this.uniqueId,
    required this.originalPrice,
    required this.salePrice,
    required this.durationMinutes,
    this.details,
    this.whatIncluded,
    this.images,
    this.category,
    this.equipment,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    List<String>? imagesList;
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = (json['images'] as List).map((img) {
          String url = img.toString();
          if (!url.startsWith('http')) {
            url = 'https://test.sumatrasales.com/storage/$url';
          }
          return url;
        }).toList();
      } else if (json['images'] is String) {
        String url = json['images'];
        if (!url.startsWith('http')) {
          url = 'https://test.sumatrasales.com/storage/$url';
        }
        imagesList = [url];
      }
    }
    
    List<String>? whatIncludedList;
    if (json['what_included'] != null) {
       if (json['what_included'] is List) {
           whatIncludedList = List<String>.from(json['what_included']);
       }
    }

    List<EquipmentModel>? equipmentList;
    if (json['equipment'] != null) {
      if (json['equipment'] is List) {
        equipmentList = (json['equipment'] as List).map((e) => EquipmentModel.fromJson(e)).toList();
      }
    }

    return ServiceModel(
      id: json['id'],
      name: json['name'] ?? '',
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) ?? 0 : 0,
      uniqueId: json['unique_id'],
      originalPrice: json['original_price'] != null ? double.tryParse(json['original_price'].toString()) ?? 0.0 : 0.0,
      salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) ?? 0.0 : 0.0,
      durationMinutes: json['duration_minutes'] != null ? int.tryParse(json['duration_minutes'].toString()) ?? 0 : 0,
      details: json['details'],
      whatIncluded: whatIncludedList,
      images: imagesList,
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      equipment: equipmentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'unique_id': uniqueId,
      'original_price': originalPrice,
      'sale_price': salePrice,
      'duration_minutes': durationMinutes,
      'details': details,
      'what_included': whatIncluded,
      'images': images,
      if (category != null) 'category': category!.toJson(),
      if (equipment != null) 'equipment': equipment!.map((e) => e.toJson()).toList(),
    };
  }
}
