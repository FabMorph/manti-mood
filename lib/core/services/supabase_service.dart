import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/banner_item.dart';
import '../models/store_settings.dart';
import '../models/order.dart';
import '../data/default_data.dart';

/// Yönetici kimlik doğrulama sonucu
enum AdminAuthResult {
  success,
  unauthorizedEmail,
  invalidPassword,
}

/// Local-First ve Bulut Senkronizasyonlu Supabase Servisi
/// Yönetici değişikliklerinin anında yerel hafızada ve SharedPreferences'da
/// kalıcı olmasını sağlar.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  static const String supabaseUrl = 'https://oeyoeoazhskwgnckeckz.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable__aoFKkfpv-LtDNhUtNU3BQ_2OBE33bP';

  static const String _kProductsKey = 'mm_cached_products_v5';
  static const String _kSettingsKey = 'mm_cached_settings_v5';
  static const String _kAnnouncementKey = 'mm_persistent_announcement_v1';
  static const String _kBannersKey = 'mm_cached_banners_v5';
  static const String _kOrdersKey = 'mm_cached_orders_v4';
  static const String _kDeletedOrdersKey = 'mm_deleted_orders_v1';
  static const String _kSyncTimestampKey = 'mm_last_synced_at';
  static const String _kLocalModifiedProductsKey = 'mm_local_mod_products_v1';
  static const String _kLocalModifiedBannersKey = 'mm_local_mod_banners_v1';
  static const String _kLocalModifiedSettingsKey = 'mm_local_mod_settings_v1';

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _isUuid(String value) => _uuidRegex.hasMatch(value.trim());

  static String _generateUuidV4() {
    Random rnd;
    try {
      rnd = Random.secure();
    } catch (_) {
      rnd = Random();
    }
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  List<Product>? _localProducts;
  List<BannerItem>? _localBanners;
  StoreSettings? _cachedSettings;
  List<OrderModel>? _localOrders;

  final ValueNotifier<StoreSettings?> settingsNotifier = ValueNotifier<StoreSettings?>(null);
  StoreSettings? get currentSettings => _cachedSettings;
  List<Product> get currentProducts => _localProducts ?? defaultProducts;
  List<BannerItem> get currentBanners => _localBanners ?? defaultBanners;

  SupabaseClient get client => Supabase.instance.client;

  bool get isCloudAvailable {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Canlı veritabanı okuma/yazma senkronizasyonu yalnızca Release (Canlı Yayın) modunda aktiftir.
  /// Geliştirici modunda (flutter run / kDebugMode) yapılan deneme siparişleri ve test değişiklikleri
  /// canlı veritabanını bozmamak için yalnızca o oturumda (Sandbox) geçici olarak çalışır.
  bool get isCloudSyncEnabled => isCloudAvailable && !kDebugMode;

  // --- YÖNETİCİ YETKİLENDİRME (Admin Auth & Whitelist) ---
  static const List<String> allowedAdminEmails = [
    'mantimood@gmail.com',
    'busraozverenli@gmail.com',
    'fabmorph@gmail.com',
    'serkanozverenli@gmail.com',
    'rhythmofsadness@gmail.com',
  ];

  String? _simulatedAdminEmail;

  /// Aktif oturumdaki yönetici e-posta adresi
  String? get activeAdminEmail {
    try {
      final googleEmail = client.auth.currentUser?.email;
      if (googleEmail != null && googleEmail.isNotEmpty) {
        return googleEmail.toLowerCase().trim();
      }
    } catch (_) {}
    // Simülasyon yalnızca yerel geliştirme / test (Debug) ortamında geçerlidir
    if (kDebugMode) {
      return _simulatedAdminEmail?.toLowerCase().trim();
    }
    return null;
  }

  /// Mevcut kullanıcı yetkili bir yönetici mi?
  bool get isCurrentAdminAuthorized {
    final email = activeAdminEmail;
    if (email == null || email.isEmpty) return false;
    return allowedAdminEmails.contains(email);
  }

  /// Geliştirici modu ve testler için yetkili hesap simülasyonu
  void setSimulatedAdmin(String? email) {
    if (kDebugMode) {
      _simulatedAdminEmail = email?.toLowerCase().trim();
    }
  }

  /// Yalnızca test ortamı için doğrulama metodu (Release derlemelerinde devre dışıdır)
  AdminAuthResult verifyAdminCredentials({required String email, required String password}) {
    if (!kDebugMode) {
      return AdminAuthResult.unauthorizedEmail;
    }
    final cleanedEmail = email.toLowerCase().trim();
    if (!allowedAdminEmails.contains(cleanedEmail)) {
      return AdminAuthResult.unauthorizedEmail;
    }
    setSimulatedAdmin(cleanedEmail);
    return AdminAuthResult.success;
  }

  /// Google OAuth ile Giriş Yap
  Future<bool> signInWithGoogle() async {
    try {
      final origin = kIsWeb ? Uri.base.origin : 'io.supabase.mantimood://login-callback';
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: origin,
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  /// Yönetici oturumunu kapat
  Future<void> signOut() async {
    _simulatedAdminEmail = null;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialize warning: $e');
    }
    // Yerel önbelleği ve bulut verilerini hafızaya yükle
    await instance._preloadCache();
  }

  Future<void> _preloadCache() async {
    try {
      final prefs = await _getPrefs();

      // Mobil cihazda flutter run (Debug) ile yeni bir oturum başlatıldığında,
      // önceki test oturumundan kalan geçici deneme verilerini temizle ki her test oturumu temiz başlasın
      if (!kIsWeb && kDebugMode) {
        await prefs.remove(_kProductsKey);
        await prefs.remove(_kSettingsKey);
        await prefs.remove(_kAnnouncementKey);
        await prefs.remove(_kBannersKey);
        await prefs.remove(_kOrdersKey);
        await prefs.remove(_kDeletedOrdersKey);
        await prefs.remove(_kLocalModifiedProductsKey);
        await prefs.remove(_kLocalModifiedBannersKey);
        await prefs.remove(_kLocalModifiedSettingsKey);
        await prefs.remove(_kSyncTimestampKey);
        await prefs.remove('mm_persistent_cart_v1');
      }

      final lastSynced = prefs.getString(_kSyncTimestampKey);
      // Eğer tool/apply_sync.dart çalıştırılmışsa veya ilk açılışsa, varsayılanları taze verilerle senkronize et
      if (lastSynced != DefaultData.syncedAt) {
        _localProducts = _ensureAileBoyu(List<Product>.from(DefaultData.products));
        await _saveLocalProducts();

        _localBanners = List<BannerItem>.from(DefaultData.banners);
        await _saveLocalBanners();

        _cachedSettings = DefaultData.storeSettings;
        await _saveLocalSettings();

        await prefs.setString(_kSyncTimestampKey, DefaultData.syncedAt);
        settingsNotifier.value = _cachedSettings;
      }
    } catch (e) {
      debugPrint('Error syncing default cache: $e');
    }

    await Future.wait([
      _loadLocalProducts(),
      _loadLocalBanners(),
      getStoreSettings(),
      _loadLocalOrders(),
    ]);

    if (isCloudSyncEnabled) {
      await Future.wait([
        _pullSettingsFromCloud(force: true),
        _pullProductsFromCloud(force: true),
        _pullBannersFromCloud(force: true),
        if (isCurrentAdminAuthorized) _pullOrdersFromCloud(),
      ]);
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // --- VARSAYILAN GERÇEK MANTI MOOD VERİLERİ (DefaultData üzerinden) ---
  static List<Product> get defaultProducts => _ensureAileBoyu(DefaultData.products);
  static List<BannerItem> get defaultBanners => DefaultData.banners;
  static StoreSettings get defaultStoreSettings => DefaultData.storeSettings;

  static List<Product> _ensureAileBoyu(List<Product> list) {
    return list.map((p) {
      if (p.variants.isNotEmpty && !p.variants.any((v) => v.title.contains('2 Kg') || v.title.contains('Aile'))) {
        final base = p.variants.first.price;
        final kgPrice = p.variants.length > 1 ? p.variants[1].price : (base * 1.85);
        final famPrice = (kgPrice * 1.9).roundToDouble();
        return p.copyWith(variants: [
          ...p.variants,
          ProductVariant(title: '2 Kg (Aile Boyu)', price: famPrice),
        ]);
      }
      return p;
    }).toList();
  }

  Future<List<Product>> _loadLocalProducts() async {
    if (_localProducts != null) return _localProducts!;
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_kProductsKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          final list = <Product>[];
          for (var item in decoded) {
            if (item is Map) {
              list.add(Product.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          final hasDummyUnsplash = list.any((p) =>
              p.imageUrl.contains('unsplash') ||
              p.name.contains('Vejetaryen / Vegan Mantı') ||
              p.name.contains('Anne Eli') ||
              p.name.contains('Sinop'));
          if (list.isNotEmpty && !hasDummyUnsplash) {
            _localProducts = list;
            return _localProducts!;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached products: $e');
    }

    // Gerçek 6 El Açması Mantı ile başlat
    _localProducts = _ensureAileBoyu(List<Product>.from(defaultProducts));
    await _saveLocalProducts();
    return _localProducts!;
  }

  Future<void> _saveLocalProducts({bool markLocalModified = false}) async {
    if (_localProducts == null) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(_localProducts!.map((p) => p.toJson()).toList());
      await prefs.setString(_kProductsKey, encoded);
      if (markLocalModified) {
        await prefs.setBool(_kLocalModifiedProductsKey, true);
      }
    } catch (e) {
      debugPrint('Error saving local products to prefs: $e');
    }
  }

  Future<void> _pullProductsFromCloud({bool force = false}) async {
    if (!isCloudSyncEnabled) return;
    try {
      final prefs = await _getPrefs();
      final hasUnsyncedLocalMods = prefs.getBool(_kLocalModifiedProductsKey) ?? false;
      if (isCurrentAdminAuthorized && hasUnsyncedLocalMods && !force) return;

      final res = await client.from('products').select().order('sort_order', ascending: true);
      final rows = res as List;
      if (rows.isNotEmpty) {
        final cloudList = rows
            .whereType<Map>()
            .map((r) => Product.fromJson(Map<String, dynamic>.from(r)))
            .where((p) =>
                !p.imageUrl.contains('unsplash') &&
                !p.name.contains('Vejetaryen / Vegan Mantı') &&
                !p.name.contains('Anne Eli'))
            .toList();
        if (cloudList.isNotEmpty) {
          _localProducts = cloudList;
          await _saveLocalProducts();
        }
      }
    } catch (e) {
      debugPrint('Cloud products pull warning: $e');
    }
  }

  // --- ÜRÜNLERİ GETİR (Bulut + Yerel Senkronizasyonlu) ---
  Future<List<Product>> getProducts({bool onlyAvailable = false, bool forceRefresh = false}) async {
    if (isCloudSyncEnabled) {
      await _pullProductsFromCloud(force: forceRefresh);
    }
    final list = await _loadLocalProducts();
    if (onlyAvailable) {
      return list.where((p) => p.isAvailable).toList();
    }
    return List<Product>.from(list);
  }

  // --- ÜRÜN STOK DURUMU DEĞİŞTİRME ---
  Future<bool> toggleProductAvailability(String productId, bool currentStatus) async {
    await _loadLocalProducts();
    final idx = _localProducts!.indexWhere((p) => p.id == productId);
    Product? updatedProduct;
    if (idx != -1) {
      updatedProduct = _localProducts![idx].copyWith(isAvailable: !currentStatus);
      _localProducts![idx] = updatedProduct;
      await _saveLocalProducts(markLocalModified: true);
    }

    if (isCloudSyncEnabled && updatedProduct != null) {
      await _syncProductToCloud(updatedProduct, isUpdate: true);
    }

    return true;
  }

  // --- ÜRÜN KAYDET (Yeni Ekle veya Mevcut Düzenle) ---
  Future<bool> saveProduct({
    String? id,
    required String name,
    required String description,
    required String category,
    required double basePrice,
    required List<ProductVariant> variants,
    required String imageUrl,
    List<String>? mediaUrls,
    required String cookingInstructions,
    required String storageInstructions,
    required bool isAvailable,
  }) async {
    await _loadLocalProducts();

    final actualId = (id != null && id.isNotEmpty) ? id : 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final list = mediaUrls ?? (imageUrl.isNotEmpty ? [imageUrl] : []);
    final primaryImage = imageUrl.isNotEmpty ? imageUrl : (list.isNotEmpty ? list.first : '');

    final existingIdx = _localProducts!.indexWhere((p) => p.id == actualId);
    final previousName = existingIdx != -1 ? _localProducts![existingIdx].name : null;
    final isFeatured = existingIdx != -1 ? _localProducts![existingIdx].isFeatured : false;
    final sortOrder = existingIdx != -1 ? _localProducts![existingIdx].sortOrder : (_localProducts!.length + 1);

    final updatedProduct = Product(
      id: actualId,
      name: name,
      description: description,
      category: category,
      basePrice: basePrice,
      variants: variants,
      imageUrl: primaryImage,
      mediaUrls: list,
      cookingInstructions: cookingInstructions,
      storageInstructions: storageInstructions,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      sortOrder: sortOrder,
    );

    if (existingIdx != -1) {
      _localProducts![existingIdx] = updatedProduct;
    } else {
      _localProducts!.add(updatedProduct);
    }

    // 1. ANINDA YERELDE KALICI YAP
    await _saveLocalProducts(markLocalModified: true);

    // 2. Buluta (Supabase) senkronize et (Yalnızca Canlı Yayın / Release modunda)
    if (isCloudSyncEnabled) {
      await _syncProductToCloud(
        updatedProduct,
        isUpdate: existingIdx != -1,
        previousName: previousName,
      );
    }

    return true;
  }

  Future<void> _syncProductToCloud(
    Product product, {
    required bool isUpdate,
    String? previousName,
  }) async {
    if (!isCloudSyncEnabled) return;
    final fullPayload = {
      'name': product.name,
      'description': product.description,
      'category': product.category,
      'base_price': product.basePrice,
      'variants': product.variants.map((v) => v.toJson()).toList(),
      'image_url': product.imageUrl,
      'media_urls': product.mediaUrls,
      'cooking_instructions': product.cookingInstructions,
      'storage_instructions': product.storageInstructions,
      'is_available': product.isAvailable,
      'is_featured': product.isFeatured,
      'sort_order': product.sortOrder,
    };

    final corePayload = Map<String, dynamic>.from(fullPayload)..remove('media_urls');

    Future<Map<String, dynamic>?> writeRow(Map<String, dynamic> data) async {
      if (_isUuid(product.id)) {
        final res = await client
            .from('products')
            .update(data)
            .eq('id', product.id)
            .select()
            .maybeSingle();
        if (res != null) return Map<String, dynamic>.from(res);
      }

      // UUID değilse (örn: 'p-bohca' veya 'prod_...') isim üzerinden mevcut kaydı bulmayı dene
      final lookupName = previousName ?? product.name;
      final existing = await client
          .from('products')
          .select('id')
          .eq('name', lookupName)
          .limit(1)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        final res = await client
            .from('products')
            .update(data)
            .eq('id', existing['id'])
            .select()
            .maybeSingle();
        if (res != null) return Map<String, dynamic>.from(res);
      }

      final inserted = await client.from('products').insert(data).select().single();
      return Map<String, dynamic>.from(inserted);
    }

    try {
      Map<String, dynamic>? savedRow;
      try {
        savedRow = await writeRow(fullPayload);
      } catch (_) {
        savedRow = await writeRow(corePayload);
      }

      if (savedRow != null && savedRow['id'] != null) {
        final cloudId = savedRow['id'].toString();
        if (_localProducts != null) {
          final idx = _localProducts!.indexWhere((p) => p.id == product.id);
          if (idx != -1 && cloudId != product.id) {
            _localProducts![idx] = _localProducts![idx].copyWith(id: cloudId);
          }
        }
        final prefs = await _getPrefs();
        await prefs.setBool(_kLocalModifiedProductsKey, false);
        await _saveLocalProducts();
      }
    } catch (e) {
      debugPrint('Product cloud sync warning: $e');
    }
  }

  // --- ÜRÜN SİL ---
  Future<bool> deleteProduct(String id) async {
    await _loadLocalProducts();
    final existingIdx = _localProducts!.indexWhere((p) => p.id == id);
    final productName = existingIdx != -1 ? _localProducts![existingIdx].name : null;

    _localProducts!.removeWhere((p) => p.id == id);
    await _saveLocalProducts(markLocalModified: true);

    if (isCloudSyncEnabled) {
      try {
        if (_isUuid(id)) {
          await client.from('products').delete().eq('id', id);
        } else if (productName != null && productName.isNotEmpty) {
          await client.from('products').delete().eq('name', productName);
        }
        final prefs = await _getPrefs();
        await prefs.setBool(_kLocalModifiedProductsKey, false);
      } catch (e) {
        debugPrint('Delete product cloud warning: $e');
      }
    }

    return true;
  }

  // --- VİTRİN BANNERLARI (Banners) ---
  Future<List<BannerItem>> _loadLocalBanners() async {
    if (_localBanners != null) return _localBanners!;
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_kBannersKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          final list = <BannerItem>[];
          for (var item in decoded) {
            if (item is Map) {
              list.add(BannerItem.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          final hasDummy = list.any((b) =>
              b.imageUrl.contains('unsplash') ||
              b.title.contains('Anne Eli') ||
              b.title.contains('Taze Anne Eli'));
          if (list.isNotEmpty && !hasDummy) {
            _localBanners = list;
            return _localBanners!;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached banners: $e');
    }

    _localBanners = List<BannerItem>.from(defaultBanners);
    await _saveLocalBanners();
    return _localBanners!;
  }

  Future<void> _saveLocalBanners({bool markLocalModified = false}) async {
    if (_localBanners == null) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(_localBanners!.map((b) => b.toJson()).toList());
      await prefs.setString(_kBannersKey, encoded);
      if (markLocalModified) {
        await prefs.setBool(_kLocalModifiedBannersKey, true);
      }
    } catch (e) {
      debugPrint('Error saving banners to prefs: $e');
    }
  }

  Future<void> _pullBannersFromCloud({bool force = false}) async {
    if (!isCloudSyncEnabled) return;
    try {
      final prefs = await _getPrefs();
      final hasUnsyncedLocalMods = prefs.getBool(_kLocalModifiedBannersKey) ?? false;
      if (isCurrentAdminAuthorized && hasUnsyncedLocalMods && !force) return;

      final res = await client.from('banners').select().order('display_order', ascending: true);
      final rows = res as List;
      if (rows.isNotEmpty) {
        final cloudList = rows
            .whereType<Map>()
            .map((r) => BannerItem.fromJson(Map<String, dynamic>.from(r)))
            .where((b) =>
                !b.imageUrl.contains('unsplash') &&
                !b.title.contains('Anne Eli') &&
                !b.title.contains('Taze Anne Eli'))
            .toList();
        if (cloudList.isNotEmpty) {
          _localBanners = cloudList;
          await _saveLocalBanners();
        }
      }
    } catch (e) {
      debugPrint('Cloud banners pull warning: $e');
    }
  }

  Future<List<BannerItem>> getBanners({bool onlyActive = true, bool forceRefresh = false}) async {
    if (isCloudSyncEnabled) {
      await _pullBannersFromCloud(force: forceRefresh);
    }
    final list = await _loadLocalBanners();
    if (onlyActive) {
      return list.where((b) => b.isActive).toList();
    }
    return List<BannerItem>.from(list);
  }

  Future<bool> toggleBannerActive(String id, bool isActive) async {
    await _loadLocalBanners();
    final idx = _localBanners!.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final updated = _localBanners![idx].copyWith(isActive: isActive);
      _localBanners![idx] = updated;
      await _saveLocalBanners(markLocalModified: true);
      if (isCloudSyncEnabled) {
        await _syncBannerToCloud(updated, isUpdate: true);
      }
      return true;
    }
    return false;
  }

  Future<bool> saveBanner({
    String? id,
    required String title,
    required String subtitle,
    required String imageUrl,
    String? mobileImageUrl,
    required bool isActive,
  }) async {
    await _loadLocalBanners();
    final actualId = (id != null && id.isNotEmpty) ? id : 'ban_${DateTime.now().millisecondsSinceEpoch}';
    final existingIdx = _localBanners!.indexWhere((b) => b.id == actualId);
    final previousTitle = existingIdx != -1 ? _localBanners![existingIdx].title : null;

    final bannerItem = BannerItem(
      id: actualId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      mobileImageUrl: mobileImageUrl ?? '',
      actionUrl: '',
      isActive: isActive,
      displayOrder: existingIdx != -1 ? _localBanners![existingIdx].displayOrder : (_localBanners!.length + 1),
    );

    if (existingIdx != -1) {
      _localBanners![existingIdx] = bannerItem;
    } else {
      _localBanners!.add(bannerItem);
    }

    await _saveLocalBanners(markLocalModified: true);

    if (isCloudSyncEnabled) {
      await _syncBannerToCloud(
        bannerItem,
        isUpdate: existingIdx != -1,
        previousTitle: previousTitle,
      );
    }

    return true;
  }

  Future<void> _syncBannerToCloud(
    BannerItem banner, {
    required bool isUpdate,
    String? previousTitle,
  }) async {
    if (!isCloudSyncEnabled) return;
    final fullPayload = {
      'title': banner.title,
      'subtitle': banner.subtitle,
      'image_url': banner.imageUrl,
      'mobile_image_url': banner.mobileImageUrl,
      'is_active': banner.isActive,
      'display_order': banner.displayOrder,
    };
    final corePayload = Map<String, dynamic>.from(fullPayload)..remove('mobile_image_url');

    Future<Map<String, dynamic>?> writeRow(Map<String, dynamic> data) async {
      if (_isUuid(banner.id)) {
        final res = await client
            .from('banners')
            .update(data)
            .eq('id', banner.id)
            .select()
            .maybeSingle();
        if (res != null) return Map<String, dynamic>.from(res);
      }

      final lookupTitle = previousTitle ?? banner.title;
      final existing = await client
          .from('banners')
          .select('id')
          .eq('title', lookupTitle)
          .limit(1)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        final res = await client
            .from('banners')
            .update(data)
            .eq('id', existing['id'])
            .select()
            .maybeSingle();
        if (res != null) return Map<String, dynamic>.from(res);
      }

      final inserted = await client.from('banners').insert(data).select().single();
      return Map<String, dynamic>.from(inserted);
    }

    try {
      Map<String, dynamic>? savedRow;
      try {
        savedRow = await writeRow(fullPayload);
      } catch (_) {
        savedRow = await writeRow(corePayload);
      }

      if (savedRow != null && savedRow['id'] != null) {
        final cloudId = savedRow['id'].toString();
        if (_localBanners != null) {
          final idx = _localBanners!.indexWhere((b) => b.id == banner.id);
          if (idx != -1 && cloudId != banner.id) {
            _localBanners![idx] = _localBanners![idx].copyWith(id: cloudId);
          }
        }
        final prefs = await _getPrefs();
        await prefs.setBool(_kLocalModifiedBannersKey, false);
        await _saveLocalBanners();
      }
    } catch (e) {
      debugPrint('Banner cloud sync warning: $e');
    }
  }

  Future<bool> deleteBanner(String id) async {
    await _loadLocalBanners();
    final existingIdx = _localBanners!.indexWhere((b) => b.id == id);
    final bannerTitle = existingIdx != -1 ? _localBanners![existingIdx].title : null;

    _localBanners!.removeWhere((b) => b.id == id);
    await _saveLocalBanners(markLocalModified: true);

    if (isCloudSyncEnabled) {
      try {
        if (_isUuid(id)) {
          await client.from('banners').delete().eq('id', id);
        } else if (bannerTitle != null && bannerTitle.isNotEmpty) {
          await client.from('banners').delete().eq('title', bannerTitle);
        }
        final prefs = await _getPrefs();
        await prefs.setBool(_kLocalModifiedBannersKey, false);
      } catch (e) {
        debugPrint('Delete banner cloud warning: $e');
      }
    }

    return true;
  }

  // --- DÜKKAN AYARLARI (Store Settings) ---
  Future<void> _pullSettingsFromCloud({bool force = false}) async {
    if (!isCloudSyncEnabled) return;
    try {
      final prefs = await _getPrefs();
      final hasUnsyncedLocalMods = prefs.getBool(_kLocalModifiedSettingsKey) ?? false;
      if (isCurrentAdminAuthorized && hasUnsyncedLocalMods && !force) return;

      final res = await client
          .from('store_settings')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        final map = Map<String, dynamic>.from(res);
        // Eğer buluttaki satır henüz yönetici tarafından hiç güncellenmemiş ilk kurulum (seed) satırıysa
        // (badges ve story_card_content boşsa ve created_at == updated_at ise), DefaultData ayarlarını koru
        final isUntouchedSeed = map['created_at'] != null &&
            map['created_at'] == map['updated_at'] &&
            (map['badges'] is List && (map['badges'] as List).isEmpty) &&
            (map['story_card_content']?.toString().isEmpty ?? true);
        if (!isUntouchedSeed || force) {
          final cloudSettings = StoreSettings.fromJson(map);
          _cachedSettings = cloudSettings;
          settingsNotifier.value = _cachedSettings;
          await _saveLocalSettings();
        }
      }
    } catch (e) {
      debugPrint('Cloud settings pull warning: $e');
    }
  }

  /// Hem ürünleri hem bannerları hem de dükkan ayarlarını buluttan taze çekip yereli günceller
  Future<void> refreshAllData() async {
    if (isCloudSyncEnabled) {
      await Future.wait([
        _pullSettingsFromCloud(force: true),
        _pullProductsFromCloud(force: true),
        _pullBannersFromCloud(force: true),
      ]);
    }
  }

  Future<StoreSettings?> getStoreSettings({bool forceRefresh = false}) async {
    if (isCloudSyncEnabled && (forceRefresh || _cachedSettings == null)) {
      await _pullSettingsFromCloud(force: forceRefresh);
    }

    if (_cachedSettings != null && !forceRefresh) {
      settingsNotifier.value = _cachedSettings;
      return _cachedSettings;
    }

    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_kSettingsKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          _cachedSettings = StoreSettings.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('Error loading cached settings: $e');
    }

    if (_cachedSettings == null) {
      _cachedSettings = defaultStoreSettings;
      await _saveLocalSettings();
    }

    settingsNotifier.value = _cachedSettings;
    return _cachedSettings;
  }

  Future<void> _saveLocalSettings({bool markLocalModified = false}) async {
    if (_cachedSettings == null) return;
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_kSettingsKey, jsonEncode(_cachedSettings!.toJson()));
      if (markLocalModified) {
        await prefs.setBool(_kLocalModifiedSettingsKey, true);
      }

      // Dükkan duyurusunu bağımsız kalıcı anahtara da yaz veya kaldır
      final announcement = _cachedSettings!.announcementText.trim();
      if (announcement.isNotEmpty) {
        await prefs.setString(_kAnnouncementKey, announcement);
      } else {
        await prefs.remove(_kAnnouncementKey);
      }
    } catch (e) {
      debugPrint('Error saving settings to prefs: $e');
    }
  }

  Future<bool> updateStoreSettings(StoreSettings settings) async {
    _cachedSettings = settings;
    settingsNotifier.value = settings;
    await _saveLocalSettings(markLocalModified: true);

    if (isCloudSyncEnabled) {
      await _syncSettingsToCloud(settings);
    }
    return true;
  }

  Future<void> _syncSettingsToCloud(StoreSettings settings) async {
    if (!isCloudSyncEnabled) return;
    try {
      final fullPayload = {
        'store_name': settings.storeName,
        'whatsapp_number': settings.whatsappNumber,
        'is_open': settings.isOpen,
        'min_order_amount': settings.minOrderAmount,
        'free_delivery_threshold': settings.freeDeliveryThreshold,
        'announcement_text': settings.announcementText,
        'is_delivery_active': settings.isDeliveryActive,
        'delivery_title': settings.deliveryTitle,
        'delivery_description': settings.deliveryDescription,
        'is_pickup_active': settings.isPickupActive,
        'pickup_title': settings.pickupTitle,
        'pickup_description': settings.pickupDescription,
        'is_bank_transfer_active': settings.isBankTransferActive,
        'is_cod_active': settings.isCodActive,
        'is_ask_seller_active': settings.isAskSellerActive,
        'bank_accounts': settings.bankAccounts.map((a) => a.toJson()).toList(),
        'has_cleared_bank_accounts': settings.hasClearedBankAccounts,
        'badges': settings.badges.map((b) => b.toJson()).toList(),
        'categories': settings.categories,
        'is_story_card_active': settings.isStoryCardActive,
        'story_card_title': settings.storyCardTitle,
        'story_card_content': settings.storyCardContent,
        'story_card_image_url': settings.storyCardImageUrl,
        'iban': settings.iban,
        'bank_name': settings.bankName,
        'account_holder': settings.accountHolder,
        'theme_preset': settings.themePreset,
      };

      bool synced = false;
      try {
        final existing = await client.from('store_settings').select('id').limit(1).maybeSingle();
        if (existing != null && existing['id'] != null) {
          await client.from('store_settings').update(fullPayload).eq('id', existing['id']);
        } else {
          await client.from('store_settings').insert(fullPayload);
        }
        synced = true;
      } catch (err) {
        final fallbackPayload = {
          'store_name': settings.storeName,
          'whatsapp_number': settings.whatsappNumber,
          'is_open': settings.isOpen,
          'min_order_amount': settings.minOrderAmount,
          'free_delivery_threshold': settings.freeDeliveryThreshold,
          'announcement_text': settings.announcementText,
          'is_delivery_active': settings.isDeliveryActive,
          'is_bank_transfer_active': settings.isBankTransferActive,
          'is_cod_active': settings.isCodActive,
          'bank_accounts': settings.bankAccounts.map((a) => a.toJson()).toList(),
          'badges': settings.badges.map((b) => b.toJson()).toList(),
          'iban': settings.iban,
          'bank_name': settings.bankName,
          'account_holder': settings.accountHolder,
        };
        final existing = await client.from('store_settings').select('id').limit(1).maybeSingle();
        if (existing != null && existing['id'] != null) {
          await client.from('store_settings').update(fallbackPayload).eq('id', existing['id']);
          synced = true;
        }
      }

      if (synced) {
        final prefs = await _getPrefs();
        await prefs.setBool(_kLocalModifiedSettingsKey, false);
      }
    } catch (e) {
      debugPrint('Settings cloud sync warning: $e');
    }
  }

  // --- SİPARİŞLER (Orders) ---
  Future<Set<String>> _getDeletedOrderKeys() async {
    try {
      final prefs = await _getPrefs();
      final list = prefs.getStringList(_kDeletedOrdersKey) ?? const [];
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _markOrderKeyDeleted(String id, String orderNumber) async {
    try {
      final prefs = await _getPrefs();
      final current = (prefs.getStringList(_kDeletedOrdersKey) ?? const []).toSet();
      if (id.isNotEmpty) current.add(id);
      if (orderNumber.isNotEmpty) current.add(orderNumber);
      await prefs.setStringList(_kDeletedOrdersKey, current.toList());
    } catch (_) {}
  }

  Future<List<OrderModel>> _loadLocalOrders() async {
    if (_localOrders != null) return _localOrders!;
    try {
      final prefs = await _getPrefs();
      final deletedKeys = await _getDeletedOrderKeys();
      final str = prefs.getString(_kOrdersKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          final list = <OrderModel>[];
          for (var item in decoded) {
            if (item is Map) {
              final order = OrderModel.fromJson(Map<String, dynamic>.from(item));
              if (!deletedKeys.contains(order.id) && !deletedKeys.contains(order.orderNumber)) {
                list.add(order);
              }
            }
          }
          _localOrders = list;
          return _localOrders!;
        }
      }
    } catch (e) {
      debugPrint('Error loading cached orders: $e');
    }

    _localOrders = [];
    return _localOrders!;
  }

  Future<void> _saveLocalOrders() async {
    if (_localOrders == null) return;
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(_localOrders!.map((o) => o.toJson()).toList());
      await prefs.setString(_kOrdersKey, encoded);
    } catch (e) {
      debugPrint('Error saving orders to prefs: $e');
    }
  }

  Future<void> _pullOrdersFromCloud() async {
    if (!isCloudSyncEnabled) return;
    try {
      await _loadLocalOrders();
      final deletedKeys = await _getDeletedOrderKeys();

      List<dynamic> orderRows = [];
      try {
        orderRows = await client
            .from('orders')
            .select('*, order_items(*)')
            .order('created_at', ascending: false);
      } catch (_) {
        orderRows = await client
            .from('orders')
            .select()
            .order('created_at', ascending: false);
      }

      if (orderRows.isEmpty) return;

      final cloudOrders = <OrderModel>[];
      for (final raw in orderRows) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final id = row['id']?.toString() ?? '';
        final orderNumber = row['order_number']?.toString() ?? '';
        if (deletedKeys.contains(id) || deletedKeys.contains(orderNumber)) {
          continue;
        }

        List<OrderItemModel> items = [];
        if (row['order_items'] is List) {
          items = (row['order_items'] as List)
              .whereType<Map>()
              .map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i)))
              .toList();
        } else if (id.isNotEmpty) {
          try {
            final itemsRes = await client.from('order_items').select().eq('order_id', id);
            items = (itemsRes as List)
                .whereType<Map>()
                .map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList();
          } catch (_) {}
        }

        cloudOrders.add(OrderModel.fromJson(row, items: items));
      }

      // Yerel siparişlerle orderNumber üzerinden birleştir
      final mergedByNumber = <String, OrderModel>{};
      for (final local in _localOrders!) {
        if (!deletedKeys.contains(local.id) && !deletedKeys.contains(local.orderNumber)) {
          mergedByNumber[local.orderNumber] = local;
        }
      }
      for (final cloud in cloudOrders) {
        final existingLocal = mergedByNumber[cloud.orderNumber];
        if (existingLocal != null) {
          // Yerelde items varsa ve buluttan items boş geldiyse yerel items'ı koru
          final mergedItems = cloud.items.isNotEmpty ? cloud.items : existingLocal.items;
          mergedByNumber[cloud.orderNumber] = cloud.copyWith(items: mergedItems);
        } else {
          mergedByNumber[cloud.orderNumber] = cloud;
        }
      }

      final mergedList = mergedByNumber.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _localOrders = mergedList;
      await _saveLocalOrders();
    } catch (e) {
      debugPrint('Cloud orders pull warning: $e');
    }
  }

  Future<OrderModel?> createOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryCity,
    required String deliveryDistrict,
    required String deliveryAddress,
    required String paymentMethod,
    required String codType,
    required double totalAmount,
    required String customerNote,
    required List<OrderItemModel> items,
  }) async {
    await _loadLocalOrders();
    final year = DateTime.now().year.toString().substring(2);
    final randCode = (DateTime.now().microsecondsSinceEpoch % 900000) + 100000;
    final orderNumber = '$year$randCode';
    final orderId = _generateUuidV4();

    final newOrder = OrderModel(
      id: orderId,
      orderNumber: orderNumber,
      userId: isCloudSyncEnabled ? client.auth.currentUser?.id : null,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      deliveryCity: deliveryCity,
      deliveryDistrict: deliveryDistrict,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      codType: codType,
      status: paymentMethod == 'bank_transfer' ? 'pending_payment' : 'order_received',
      statusSteps: paymentMethod == 'bank_transfer'
          ? ['order_received', 'pending_payment']
          : ['order_received'],
      totalAmount: totalAmount,
      customerNote: customerNote,
      invoiceSent: false,
      trackingCode: '',
      carrierCompany: '',
      createdAt: DateTime.now(),
      items: items,
    );

    _localOrders!.insert(0, newOrder);
    await _saveLocalOrders();

    if (isCloudSyncEnabled) {
      await _syncOrderToCloud(newOrder);
    }

    return _localOrders!.firstWhere(
      (o) => o.orderNumber == orderNumber,
      orElse: () => newOrder,
    );
  }

  Future<void> _syncOrderToCloud(OrderModel order) async {
    if (!isCloudSyncEnabled) return;
    try {
      final currentUser = client.auth.currentUser;
      final cloudOrderId = _isUuid(order.id) ? order.id : _generateUuidV4();
      final payload = {
        'id': cloudOrderId,
        'order_number': order.orderNumber,
        'user_id': currentUser?.id,
        'customer_name': order.customerName,
        'customer_email': order.customerEmail,
        'customer_phone': order.customerPhone,
        'delivery_city': order.deliveryCity,
        'delivery_district': order.deliveryDistrict,
        'delivery_address': order.deliveryAddress,
        'payment_method': order.paymentMethod,
        'cod_type': order.codType,
        'total_amount': order.totalAmount,
        'customer_note': order.customerNote,
        'status': order.status,
        'kvkk_accepted': true,
        'distance_sales_accepted': true,
      };

      try {
        await client.from('orders').insert({
          ...payload,
          'status_steps': order.statusSteps,
        });
      } catch (_) {
        await client.from('orders').insert(payload);
      }

      if (_localOrders != null && cloudOrderId != order.id) {
        final idx = _localOrders!.indexWhere((o) => o.orderNumber == order.orderNumber);
        if (idx != -1) {
          _localOrders![idx] = _localOrders![idx].copyWith(id: cloudOrderId);
          await _saveLocalOrders();
        }
      }

      if (order.items.isNotEmpty) {
        final itemsToInsert = order.items.map((item) => {
          'order_id': cloudOrderId,
          'product_id': (item.productId != null && _isUuid(item.productId!)) ? item.productId : null,
          'product_name': item.productName,
          'variant_title': item.variantTitle,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
        }).toList();
        await client.from('order_items').insert(itemsToInsert);
      }
    } catch (e) {
      debugPrint('Order cloud sync warning: $e');
    }
  }

  Future<OrderModel?> getOrderByNumber(String orderNumber, {bool maskForPublic = true}) async {
    final deletedKeys = await _getDeletedOrderKeys();
    final clean = orderNumber.trim().toLowerCase();

    if (isCloudSyncEnabled) {
      // 1. Önce güvenli RPC üzerinden sorgula (Anonim kullanıcıların tüm sipariş tablosunu okumasını engeller)
      try {
        final rpcRes = await client.rpc(
          'get_public_order_by_number',
          params: {'p_order_number': orderNumber.trim()},
        );
        if (rpcRes is Map) {
          final map = Map<String, dynamic>.from(rpcRes);
          final id = map['id']?.toString() ?? '';
          final numStr = map['order_number']?.toString() ?? '';
          if (numStr.isNotEmpty && !deletedKeys.contains(id) && !deletedKeys.contains(numStr)) {
            final rawItems = map['items'] is List ? (map['items'] as List) : const [];
            final items = rawItems
                .whereType<Map>()
                .map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i)))
                .toList();
            final order = OrderModel.fromJson(map, items: items);
            return maskForPublic ? order.toPublicMasked() : order;
          }
        }
      } catch (_) {}

      // 2. Yetkili admin veya kendi siparişi için doğrudan tablo sorgusu (yedek)
      try {
        final orderRes = await client
            .from('orders')
            .select()
            .ilike('order_number', orderNumber.trim())
            .maybeSingle();

        if (orderRes != null) {
          final id = orderRes['id']?.toString() ?? '';
          final numStr = orderRes['order_number']?.toString() ?? '';
          if (!deletedKeys.contains(id) && !deletedKeys.contains(numStr)) {
            final itemsRes = await client
                .from('order_items')
                .select()
                .eq('order_id', orderRes['id']);

            final items = (itemsRes as List).map((i) => OrderItemModel.fromJson(i)).toList();
            final order = OrderModel.fromJson(orderRes, items: items);
            return maskForPublic ? order.toPublicMasked() : order;
          }
        }
      } catch (_) {}
    }

    final list = await _loadLocalOrders();
    for (var o in list) {
      if (o.orderNumber.toLowerCase() == clean) {
        return maskForPublic ? o.toPublicMasked() : o;
      }
    }

    return null;
  }

  Future<List<OrderModel>> getAllOrders() async {
    if (isCloudSyncEnabled) {
      await _pullOrdersFromCloud();
    }
    final list = await _loadLocalOrders();
    return List<OrderModel>.from(list);
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    await _loadLocalOrders();
    final idx = _localOrders!.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    OrderModel? updated;
    if (idx != -1) {
      final current = _localOrders![idx];
      final newSteps = List<String>.from(current.statusSteps);
      if (!newSteps.contains(newStatus)) {
        newSteps.add(newStatus);
      }
      updated = current.copyWith(
        status: newStatus,
        statusSteps: newSteps,
      );
      _localOrders![idx] = updated;
      await _saveLocalOrders();
    }

    if (isCloudSyncEnabled && updated != null) {
      try {
        await client.from('orders').update({
          'status': newStatus,
          'status_steps': updated.statusSteps,
        }).eq('order_number', updated.orderNumber);
      } catch (_) {
        try {
          await client.from('orders').update({
            'status': newStatus,
          }).eq('order_number', updated.orderNumber);
        } catch (_) {}
      }
    }

    return true;
  }

  /// Belirli bir sipariş durum aşamasını işaretler veya işaretini kaldırır (Toggle)
  Future<OrderModel?> toggleOrderStep(String orderId, String stepKey) async {
    await _loadLocalOrders();
    final idx = _localOrders!.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    if (idx == -1) return null;

    final current = _localOrders![idx];
    final steps = List<String>.from(current.statusSteps);

    if (stepKey == 'order_received') {
      // Sipariş Alındı her zaman sabit ilk adımdır
      return current;
    }

    if (steps.contains(stepKey)) {
      steps.remove(stepKey);
    } else {
      steps.add(stepKey);
    }

    final newStatus = OrderModel.calculatePrimaryStatus(steps, fallback: 'order_received');
    final updated = current.copyWith(
      status: newStatus,
      statusSteps: steps,
    );
    _localOrders![idx] = updated;
    await _saveLocalOrders();

    if (isCloudSyncEnabled) {
      try {
        await client.from('orders').update({
          'status': newStatus,
          'status_steps': steps,
        }).eq('order_number', updated.orderNumber);
      } catch (_) {
        try {
          await client.from('orders').update({
            'status': newStatus,
          }).eq('order_number', updated.orderNumber);
        } catch (_) {}
      }
    }

    return updated;
  }

  Future<bool> markInvoiceSent(String orderId) async {
    await _loadLocalOrders();
    final idx = _localOrders!.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    final now = DateTime.now();
    OrderModel? updated;
    if (idx != -1) {
      final current = _localOrders![idx];
      updated = current.copyWith(
        invoiceSent: true,
        invoiceSentAt: now,
      );
      _localOrders![idx] = updated;
      await _saveLocalOrders();
    }

    if (isCloudSyncEnabled) {
      try {
        final targetOrderNumber = updated?.orderNumber;
        if (targetOrderNumber != null && targetOrderNumber.isNotEmpty) {
          await client.from('orders').update({
            'invoice_sent': true,
            'invoice_sent_at': now.toIso8601String(),
          }).eq('order_number', targetOrderNumber);
        } else if (_isUuid(orderId)) {
          await client.from('orders').update({
            'invoice_sent': true,
            'invoice_sent_at': now.toIso8601String(),
          }).eq('id', orderId);
        }
      } catch (_) {}
    }

    return true;
  }

  /// Müşteriye bilgi fişini e-posta ile gönderir (Supabase Edge Function üzerinden)
  Future<Map<String, dynamic>> sendInvoiceEmail(OrderModel order, {String? receiptImageBase64}) async {
    // 1. Önce veritabanında ve yerelde bilgi fişi gönderildi olarak işaretle
    await markInvoiceSent(order.id);

    // 2. Eğer bulut bağlıysa invoice / send-order-receipt Edge Function'ı çağır
    if (isCloudAvailable) {
      try {
        final localCreatedAt = order.createdAt.toLocal();
        final dateStr =
            '${localCreatedAt.day.toString().padLeft(2, '0')}.${localCreatedAt.month.toString().padLeft(2, '0')}.${localCreatedAt.year} '
            '${localCreatedAt.hour.toString().padLeft(2, '0')}:${localCreatedAt.minute.toString().padLeft(2, '0')}';

        final paymentLabel = order.paymentMethodLabel;

        final fullAddress = [
          if (order.deliveryDistrict.isNotEmpty) order.deliveryDistrict,
          if (order.deliveryCity.isNotEmpty) order.deliveryCity,
          if (order.deliveryAddress.isNotEmpty) order.deliveryAddress,
        ].join(', ');

        final payload = {
          'orderNumber': order.orderNumber,
          'orderDate': dateStr,
          'customerName': order.customerName,
          'customerEmail': order.customerEmail,
          'customerPhone': order.customerPhone,
          'deliveryCity': order.deliveryCity,
          'deliveryDistrict': order.deliveryDistrict,
          'deliveryAddress': fullAddress,
          'paymentMethod': order.paymentMethod,
          'paymentLabel': paymentLabel,
          'codType': order.codType,
          'carrierCompany': order.carrierCompany,
          'trackingCode': order.trackingCode,
          'totalAmount': order.totalAmount,
          'customerNote': order.customerNote,
          'receiptImageBase64': receiptImageBase64,
          'items': order.items.map((i) => {
            'productName': i.productName,
            'variantTitle': i.variantTitle,
            'quantity': i.quantity,
            'unitPrice': i.unitPrice,
            'subtotal': i.subtotal,
          }).toList(),
        };

        dynamic response;
        try {
          response = await client.functions.invoke(
            'send-order-receipt',
            body: payload,
          );
        } catch (_) {
          response = await client.functions.invoke(
            'invoice',
            body: payload,
          );
        }

        if (response.status == 200) {
          return {'success': true, 'message': 'Bilgi fişi e-postası başarıyla iletildi.'};
        } else {
          return {'success': false, 'error': response.data?['error'] ?? 'E-posta servisi hata döndürdü.'};
        }
      } catch (e) {
        debugPrint('Bilgi fişi gönderme edge function hatası: $e');
        return {'success': false, 'error': e.toString()};
      }
    }

    return {'success': true, 'message': 'Bilgi fişi durumu güncellendi (Yerel mod).'};
  }

  /// Siparişi ve ilişkili kalemlerini veritabanından ve yerel önbellekten kalıcı olarak siler
  Future<bool> deleteOrder(String orderId) async {
    await _loadLocalOrders();
    final idx = _localOrders!.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    final targetOrder = idx != -1 ? _localOrders![idx] : null;
    final orderNumber = targetOrder?.orderNumber ?? '';

    await _markOrderKeyDeleted(orderId, orderNumber);
    _localOrders!.removeWhere((o) => o.id == orderId || (orderNumber.isNotEmpty && o.orderNumber == orderNumber));
    await _saveLocalOrders();

    if (isCloudSyncEnabled) {
      try {
        String? cloudUuid = _isUuid(orderId) ? orderId : null;
        if (cloudUuid == null && orderNumber.isNotEmpty) {
          final existing = await client
              .from('orders')
              .select('id')
              .eq('order_number', orderNumber)
              .limit(1)
              .maybeSingle();
          cloudUuid = existing?['id']?.toString();
        }
        if (cloudUuid != null && cloudUuid.isNotEmpty) {
          await client.from('order_items').delete().eq('order_id', cloudUuid);
          await client.from('orders').delete().eq('id', cloudUuid);
        } else if (orderNumber.isNotEmpty) {
          await client.from('orders').delete().eq('order_number', orderNumber);
        }
      } catch (e) {
        debugPrint('Delete order cloud warning: $e');
      }
    }

    return true;
  }
}

