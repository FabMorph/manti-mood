class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String mobileImageUrl;
  final String actionUrl;
  final bool isActive;
  final int displayOrder;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.mobileImageUrl = '',
    required this.actionUrl,
    required this.isActive,
    required this.displayOrder,
  });

  BannerItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? mobileImageUrl,
    String? actionUrl,
    bool? isActive,
    int? displayOrder,
  }) {
    return BannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      mobileImageUrl: mobileImageUrl ?? this.mobileImageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  /// Cihaz türüne göre en uygun banner görselini döndürür (Mobilde ayrı görsel yoksa ana görsel kullanılır)
  String getEffectiveImageUrl({required bool isMobile}) {
    if (isMobile && mobileImageUrl.trim().isNotEmpty) {
      return mobileImageUrl.trim();
    }
    return imageUrl.trim();
  }

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      mobileImageUrl: json['mobile_image_url'] as String? ?? json['mobileImageUrl'] as String? ?? '',
      actionUrl: json['action_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'image_url': imageUrl,
    'mobile_image_url': mobileImageUrl,
    'action_url': actionUrl,
    'is_active': isActive,
    'display_order': displayOrder,
  };
}
