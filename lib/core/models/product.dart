class ProductVariant {
  final String title;
  final double price;

  const ProductVariant({
    required this.title,
    required this.price,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      title: json['title'] as String? ?? 'Standart',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'price': price,
  };
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double basePrice;
  final List<ProductVariant> variants;
  final String imageUrl;
  final List<String> mediaUrls; // Çoklu resim ve video desteği
  final String cookingInstructions;
  final String storageInstructions;
  final bool isAvailable;
  final bool isFeatured;
  final int sortOrder;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.variants,
    required this.imageUrl,
    this.mediaUrls = const [],
    required this.cookingInstructions,
    required this.storageInstructions,
    required this.isAvailable,
    required this.isFeatured,
    required this.sortOrder,
  });

  List<String> get allMedia {
    if (mediaUrls.isNotEmpty) return mediaUrls;
    if (imageUrl.isNotEmpty) return [imageUrl];
    return const [];
  }

  static bool isMediaVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.startsWith('data:video') ||
        lower.contains('video');
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? basePrice,
    List<ProductVariant>? variants,
    String? imageUrl,
    List<String>? mediaUrls,
    String? cookingInstructions,
    String? storageInstructions,
    bool? isAvailable,
    bool? isFeatured,
    int? sortOrder,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      variants: variants ?? this.variants,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      cookingInstructions: cookingInstructions ?? this.cookingInstructions,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'];
    List<ProductVariant> variantList = [];
    if (rawVariants is List) {
      for (var item in rawVariants) {
        if (item is Map) {
          variantList.add(ProductVariant.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    if (variantList.isEmpty) {
      variantList = [
        ProductVariant(
          title: 'Standart Porsiyon',
          price: (json['base_price'] as num?)?.toDouble() ?? 0.0,
        )
      ];
    }

    List<String> mediaList = [];
    final rawMedia = json['media_urls'];
    if (rawMedia is List) {
      mediaList = rawMedia.map((m) => m.toString()).toList();
    }
    final primaryImg = json['image_url'] as String? ?? '';
    if (mediaList.isEmpty && primaryImg.isNotEmpty) {
      mediaList = [primaryImg];
    }

    final rawName = json['name'] as String? ?? '';
    final cleanedName = cleanProductName(rawName);

    return Product(
      id: json['id'] as String? ?? '',
      name: cleanedName,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Mantı',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      variants: variantList,
      imageUrl: primaryImg.isNotEmpty ? primaryImg : (mediaList.isNotEmpty ? mediaList.first : ''),
      mediaUrls: mediaList,
      cookingInstructions: json['cooking_instructions'] as String? ?? '',
      storageInstructions: json['storage_instructions'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Ürün kartlarında simetriyi bozan ve alta taşmaya sebep olan parantezli açıklamaları temizler
  static String cleanProductName(String name) {
    return name
        .replaceAll(
          RegExp(r'\s*\((?:patatesli\s*\/?\s*kıymalı|kafkas\s*(?:usulü|mantısı)?)\)', caseSensitive: false),
          '',
        )
        .trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'base_price': basePrice,
    'variants': variants.map((v) => v.toJson()).toList(),
    'image_url': imageUrl,
    'media_urls': mediaUrls,
    'cooking_instructions': cookingInstructions,
    'storage_instructions': storageInstructions,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'sort_order': sortOrder,
  };
}
