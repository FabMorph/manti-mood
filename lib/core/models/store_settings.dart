class StoreBadge {
  final String icon; // Emoji veya ikon kodu (örn: "🥟", "🥩", "🌿", "🚚")
  final String title;
  final String subtitle;

  const StoreBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  StoreBadge copyWith({
    String? icon,
    String? title,
    String? subtitle,
  }) {
    return StoreBadge(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  factory StoreBadge.fromJson(Map<String, dynamic> json) {
    return StoreBadge(
      icon: json['icon'] as String? ?? '🥟',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'icon': icon,
    'title': title,
    'subtitle': subtitle,
  };
}

class BankAccount {
  final String bankName;
  final String iban;
  final String accountHolder;

  const BankAccount({
    required this.bankName,
    required this.iban,
    required this.accountHolder,
  });

  BankAccount copyWith({
    String? bankName,
    String? iban,
    String? accountHolder,
  }) {
    return BankAccount(
      bankName: bankName ?? this.bankName,
      iban: iban ?? this.iban,
      accountHolder: accountHolder ?? this.accountHolder,
    );
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      bankName: json['bank_name'] as String? ?? '',
      iban: json['iban'] as String? ?? '',
      accountHolder: json['account_holder'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'bank_name': bankName,
    'iban': iban,
    'account_holder': accountHolder,
  };
}

class StoreSettings {
  final String id;
  final String storeName;
  final bool isOpen;
  final String whatsappNumber;
  final double minOrderAmount;
  final double freeDeliveryThreshold;
  final String announcementText;

  // Yeni Modüler Özellikler
  final bool isDeliveryActive; // Adrese teslimat aktif mi? (Varsayılan: false)
  final String deliveryTitle; // Adrese teslimat başlığı
  final String deliveryDescription; // Adrese teslimat açıklaması
  final bool isPickupActive; // Gel-Al / Mutfaktan teslim aktif mi? (Varsayılan: true)
  final String pickupTitle; // Gel-Al başlığı
  final String pickupDescription; // Gel-Al açıklaması
  final bool isBankTransferActive; // Havale/EFT aktif mi?
  final bool isCodActive; // Elden / Kapıda ödeme aktif mi?
  final bool isAskSellerActive; // Üst barda "Satıcıya Sor" (WhatsApp) butonu aktif mi? (Varsayılan: true)
  final bool hasClearedBankAccounts; // Banka hesapları yönetici tarafından bilerek mi sıfırlandı?
  final List<BankAccount> bankAccounts; // Çoklu IBAN desteği
  final List<StoreBadge> badges; // Dinamik vitrin kartları
  final List<String> categories; // Dinamik kategori listesi

  // Alt Kart (Mantı Hikayesi & Tanıtım Bölümü)
  final bool isStoryCardActive; // Alt kart görünür mü?
  final String storyCardTitle; // Alt kart başlığı
  final String storyCardContent; // Alt kart metni
  final String storyCardImageUrl; // Alt kart görseli / logosu

  // Tema & Güvenlik Ayarları
  final String themePreset; // 'classic', 'terracotta', 'midnight', 'sage', 'bordeaux'
  final String adminPassword; // Eski sürüm geriye dönük uyumluluk alanı

  static const List<BankAccount> defaultBankAccounts = [
    BankAccount(
      bankName: 'Ziraat Bankası',
      iban: 'TR12 0006 2000 0000 1234 5678 90',
      accountHolder: 'Mantı Mood',
    ),
  ];

  const StoreSettings({
    this.id = '',
    this.storeName = 'Mantı Mood',
    this.isOpen = true,
    this.whatsappNumber = '905551234567',
    this.minOrderAmount = 0.0,
    this.freeDeliveryThreshold = 500.0,
    this.announcementText = '',
    this.isDeliveryActive = false,
    this.deliveryTitle = 'Adrese Teslimat (Kurye / Kargo)',
    this.deliveryDescription = 'Siparişiniz adresinize özenle teslim edilir.',
    this.isPickupActive = true,
    this.pickupTitle = 'Gel-Al / Mutfaktan Teslim',
    this.pickupDescription = 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
    this.isBankTransferActive = true,
    this.isCodActive = true,
    this.isAskSellerActive = true,
    this.hasClearedBankAccounts = false,
    this.bankAccounts = defaultBankAccounts,
    this.badges = const [
      StoreBadge(icon: '🥩', title: '%100 Dana Eti', subtitle: 'Katkısız Harç'),
      StoreBadge(icon: '🥟', title: 'Günlük Taze', subtitle: 'El Açması Hamur'),
      StoreBadge(icon: '✨', title: 'Özel Tarif', subtitle: 'Geleneksel Lezzet'),
    ],
    this.categories = const [
      'Klasik Mantı',
      'Yöresel Mantı',
      'Sebzeli & Vejetaryen',
      'Soslar & Yan Ürünler',
    ],
    this.isStoryCardActive = true,
    this.storyCardTitle = 'Mantı Mood Hikayesi',
    this.storyCardContent = 'Evimizde annelerimizin elleriyle, taptaze un ve %100 yerli dana kıymayla tek tek büktüğümüz geleneksel lezzeti sofranıza getiriyoruz. Hiçbir koruyucu veya katkı maddesi kullanmadan, şok dondurarak tazeliğini ilk günkü gibi muhafaza ediyoruz.',
    this.storyCardImageUrl = 'assets/images/manti-mood-logo.png',
    this.themePreset = 'classic',
    this.adminPassword = '',
  });

  StoreSettings copyWith({
    String? id,
    String? storeName,
    bool? isOpen,
    String? whatsappNumber,
    double? minOrderAmount,
    double? freeDeliveryThreshold,
    String? announcementText,
    bool? isDeliveryActive,
    String? deliveryTitle,
    String? deliveryDescription,
    bool? isPickupActive,
    String? pickupTitle,
    String? pickupDescription,
    bool? isBankTransferActive,
    bool? isCodActive,
    bool? isAskSellerActive,
    bool? hasClearedBankAccounts,
    List<BankAccount>? bankAccounts,
    List<StoreBadge>? badges,
    List<String>? categories,
    bool? isStoryCardActive,
    String? storyCardTitle,
    String? storyCardContent,
    String? storyCardImageUrl,
    String? themePreset,
    String? adminPassword,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      isOpen: isOpen ?? this.isOpen,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      announcementText: announcementText ?? this.announcementText,
      isDeliveryActive: isDeliveryActive ?? this.isDeliveryActive,
      deliveryTitle: deliveryTitle ?? this.deliveryTitle,
      deliveryDescription: deliveryDescription ?? this.deliveryDescription,
      isPickupActive: isPickupActive ?? this.isPickupActive,
      pickupTitle: pickupTitle ?? this.pickupTitle,
      pickupDescription: pickupDescription ?? this.pickupDescription,
      isBankTransferActive: isBankTransferActive ?? this.isBankTransferActive,
      isCodActive: isCodActive ?? this.isCodActive,
      isAskSellerActive: isAskSellerActive ?? this.isAskSellerActive,
      hasClearedBankAccounts: hasClearedBankAccounts ?? this.hasClearedBankAccounts,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      badges: badges ?? this.badges,
      categories: categories ?? this.categories,
      isStoryCardActive: isStoryCardActive ?? this.isStoryCardActive,
      storyCardTitle: storyCardTitle ?? this.storyCardTitle,
      storyCardContent: storyCardContent ?? this.storyCardContent,
      storyCardImageUrl: storyCardImageUrl ?? this.storyCardImageUrl,
      themePreset: themePreset ?? this.themePreset,
      adminPassword: adminPassword ?? this.adminPassword,
    );
  }

  // Geriye dönük uyumluluk için ilk IBAN
  String get iban => bankAccounts.isNotEmpty ? bankAccounts.first.iban : '';
  String get bankName => bankAccounts.isNotEmpty ? bankAccounts.first.bankName : '';
  String get accountHolder => bankAccounts.isNotEmpty ? bankAccounts.first.accountHolder : '';

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    final bool hasCleared = json['has_cleared_bank_accounts'] as bool? ?? false;

    // Banka Hesapları
    List<BankAccount> accounts = [];
    final rawAccounts = json['bank_accounts'];
    if (rawAccounts is List) {
      accounts = rawAccounts
          .whereType<Map<String, dynamic>>()
          .map((a) => BankAccount.fromJson(a))
          .toList();
    }
    // Eğer bank_accounts boşsa eski tekil iban/bank_name kolonlarından doldur
    if (accounts.isEmpty && json['iban'] != null && (json['iban'] as String).isNotEmpty) {
      accounts.add(BankAccount(
        bankName: json['bank_name'] as String? ?? 'Banka',
        iban: json['iban'] as String? ?? '',
        accountHolder: json['account_holder'] as String? ?? '',
      ));
    }
    // Yönetici açıkça tüm hesapları silmemişse varsayılan hesabı (Ziraat) sağla
    if (accounts.isEmpty && !hasCleared) {
      accounts = List.from(defaultBankAccounts);
    }

    // Vitrin Rozetleri
    List<StoreBadge> badgeList = [];
    final rawBadges = json['badges'];
    if (rawBadges is List) {
      badgeList = rawBadges
          .whereType<Map<String, dynamic>>()
          .map((b) => StoreBadge.fromJson(b))
          .toList();
    }
    if (badgeList.isEmpty) {
      badgeList = const [
        StoreBadge(icon: '🥩', title: '%100 Dana Eti', subtitle: 'Katkısız Harç'),
        StoreBadge(icon: '🥟', title: 'Günlük Taze', subtitle: 'El Açması Hamur'),
        StoreBadge(icon: '✨', title: 'Özel Tarif', subtitle: 'Geleneksel Lezzet'),
      ];
    }

    // Kategoriler
    List<String> catList = [];
    final rawCategories = json['categories'];
    if (rawCategories is List) {
      catList = rawCategories.map((c) => c.toString()).toList();
    }
    if (catList.isEmpty) {
      catList = const [
        'Klasik Mantı',
        'Yöresel Mantı',
        'Sebzeli & Vejetaryen',
        'Soslar & Yan Ürünler',
      ];
    }

    return StoreSettings(
      id: json['id'] as String? ?? '',
      storeName: json['store_name'] as String? ?? 'Mantı Mood',
      isOpen: json['is_open'] as bool? ?? true,
      whatsappNumber: json['whatsapp_number'] as String? ?? '905551234567',
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      freeDeliveryThreshold: (json['free_delivery_threshold'] as num?)?.toDouble() ?? 500.0,
      announcementText: json['announcement_text'] as String? ?? '',
      isDeliveryActive: json['is_delivery_active'] as bool? ?? false,
      deliveryTitle: json['delivery_title'] as String? ?? 'Adrese Teslimat (Kurye / Kargo)',
      deliveryDescription: json['delivery_description'] as String? ?? 'Siparişiniz adresinize özenle teslim edilir.',
      isPickupActive: json['is_pickup_active'] as bool? ?? true,
      pickupTitle: json['pickup_title'] as String? ?? 'Gel-Al / Mutfaktan Teslim',
      pickupDescription: json['pickup_description'] as String? ?? 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
      isBankTransferActive: json['is_bank_transfer_active'] as bool? ?? true,
      isCodActive: json['is_cod_active'] as bool? ?? true,
      isAskSellerActive: json['is_ask_seller_active'] as bool? ?? true,
      hasClearedBankAccounts: hasCleared,
      bankAccounts: accounts,
      badges: badgeList,
      categories: catList,
      isStoryCardActive: json['is_story_card_active'] as bool? ?? true,
      storyCardTitle: json['story_card_title'] as String? ?? 'Mantı Mood Hikayesi',
      storyCardContent: json['story_card_content'] as String? ?? 'Evimizde annelerimizin elleriyle, taptaze un ve %100 yerli dana kıymayla tek tek büktüğümüz geleneksel lezzeti sofranıza getiriyoruz. Hiçbir koruyucu veya katkı maddesi kullanmadan, şok dondurarak tazeliğini ilk günkü gibi muhafaza ediyoruz.',
      storyCardImageUrl: json['story_card_image_url'] as String? ?? 'assets/images/manti-mood-logo.png',
      themePreset: json['theme_preset'] as String? ?? json['themePreset'] as String? ?? 'classic',
      adminPassword: json['admin_password'] as String? ?? json['adminPassword'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'store_name': storeName,
    'is_open': isOpen,
    'whatsapp_number': whatsappNumber,
    'min_order_amount': minOrderAmount,
    'free_delivery_threshold': freeDeliveryThreshold,
    'announcement_text': announcementText,
    'is_delivery_active': isDeliveryActive,
    'delivery_title': deliveryTitle,
    'delivery_description': deliveryDescription,
    'is_pickup_active': isPickupActive,
    'pickup_title': pickupTitle,
    'pickup_description': pickupDescription,
    'is_bank_transfer_active': isBankTransferActive,
    'is_cod_active': isCodActive,
    'is_ask_seller_active': isAskSellerActive,
    'has_cleared_bank_accounts': hasClearedBankAccounts,
    'bank_accounts': bankAccounts.map((a) => a.toJson()).toList(),
    'badges': badges.map((b) => b.toJson()).toList(),
    'categories': categories,
    'is_story_card_active': isStoryCardActive,
    'story_card_title': storyCardTitle,
    'story_card_content': storyCardContent,
    'story_card_image_url': storyCardImageUrl,
    'theme_preset': themePreset,
    'admin_password': adminPassword,
    'iban': iban,
    'bank_name': bankName,
    'account_holder': accountHolder,
  };
}
