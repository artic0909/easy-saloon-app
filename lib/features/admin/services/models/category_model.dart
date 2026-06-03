class CategoryModel {
  final int? id;
  final String name;
  final String? image;
  final String? slug;

  CategoryModel({
    this.id,
    required this.name,
    this.image,
    this.slug,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'];
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = 'https://test.sumatrasales.com/storage/$imageUrl';
    }
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      image: imageUrl,
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'slug': slug,
    };
  }
}
