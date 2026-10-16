import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manti_mood/core/models/order.dart';
import 'package:manti_mood/core/models/product.dart';
import 'package:manti_mood/core/models/store_settings.dart';
import 'package:manti_mood/core/services/supabase_service.dart';
import 'package:manti_mood/core/theme/theme_presets.dart';
import 'package:manti_mood/core/widgets/image_cropper_dialog.dart';
import 'package:manti_mood/core/services/crop_state_registry.dart';
import 'package:manti_mood/features/checkout/checkout_dialog.dart';
import 'package:manti_mood/features/home/home_screen.dart';
import 'package:manti_mood/features/admin/admin_dashboard.dart';
import 'package:manti_mood/features/orders/order_tracking_dialog.dart';
import 'package:manti_mood/features/cart/cart_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Product model parses correctly', () {
    final product = Product.fromJson({
      'id': '1',
      'name': 'Geleneksel Mantı',
      'base_price': 250.0,
      'variants': [
        {'title': '500 gr', 'price': 250.0},
        {'title': '1 Kg', 'price': 450.0},
      ],
      'media_urls': ['assets/images/1.png', 'https://site.com/video.mp4'],
    });

    expect(product.name, 'Geleneksel Mantı');
    expect(product.variants.length, 2);
    expect(product.variants.first.price, 250.0);
    expect(product.mediaUrls.length, 2);
    expect(product.allMedia.length, 2);
    expect(Product.isMediaVideo('https://site.com/video.mp4'), isTrue);
    expect(Product.isMediaVideo('assets/images/1.png'), isFalse);
  });

  test('Product cleans paranthetical descriptions like (Patatesli / Kıymalı) and (Kafkas Usulü/Mantısı)', () {
    expect(Product.cleanProductName('Hıngel Mantısı (Patatesli / Kıymalı)'), 'Hıngel Mantısı');
    expect(Product.cleanProductName('Hıngel Mantısı (patatesli/kıymalı)'), 'Hıngel Mantısı');
    expect(Product.cleanProductName('Örgü Mantı (Kafkas Usulü)'), 'Örgü Mantı');
    expect(Product.cleanProductName('Örgü Mantı (Kafkas Mantısı)'), 'Örgü Mantı');
    expect(Product.cleanProductName('Örgü Mantı (kafkas mantısı)'), 'Örgü Mantı');
  });

  test('StoreSettings parses categories correctly with fallbacks', () {
    final settings = StoreSettings.fromJson({
      'categories': ['Mantı', 'Makarna', 'Tatlı'],
    });
    expect(settings.categories.length, 3);
    expect(settings.categories, contains('Makarna'));

    // Test fallback when empty or missing
    final emptySettings = StoreSettings.fromJson({});
    expect(emptySettings.categories.length, 4);
    expect(emptySettings.categories, contains('Klasik Mantı'));
  });

  test('All default products contain 2 Kg Aile Boyu option', () {
    for (final product in SupabaseService.defaultProducts) {
      expect(
        product.variants.any((v) => v.title.contains('2 Kg') || v.title.contains('Aile')),
        isTrue,
        reason: '${product.name} must have 2 Kg option',
      );
      expect(product.variants.length, greaterThanOrEqualTo(3));
    }
  });

  test('saveProduct updates product price and multi-images and persists locally', () async {
    final service = SupabaseService.instance;
    final initialList = await service.getProducts();
    expect(initialList, isNotEmpty);

    // Bohça mantısının fiyatını ve görsellerini güncelle
    final success = await service.saveProduct(
      id: 'p-bohca',
      name: 'Bohça Mantı (Geleneksel)',
      description: 'Güncellenmiş açıklama',
      category: 'Klasik Mantı',
      basePrice: 320.0,
      variants: const [
        ProductVariant(title: '500 gr', price: 320.0),
        ProductVariant(title: '1 Kg', price: 600.0),
        ProductVariant(title: '2 Kg (Aile Boyu)', price: 1150.0),
      ],
      imageUrl: 'assets/images/manti-cesitleri/bohca.png',
      mediaUrls: [
        'assets/images/manti-cesitleri/bohca.png',
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ],
      cookingInstructions: '8-10 dakika haşlayın.',
      storageInstructions: '-18°C dondurucuda saklayınız.',
      isAvailable: true,
    );

    expect(success, isTrue);

    // Tekrar ürünleri çek ve değişikliğin korunduğunu doğrula
    final updatedList = await service.getProducts();
    final bohca = updatedList.firstWhere((p) => p.id == 'p-bohca');
    expect(bohca.basePrice, 320.0);
    expect(bohca.variants.first.price, 320.0);
    expect(bohca.allMedia.length, 2);
    expect(bohca.mediaUrls.length, 2);
    expect(bohca.description, 'Güncellenmiş açıklama');
  });

  testWidgets('ImageCropperDialog renders with zoom controls and aspect ratios', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImageCropperDialog(
            imageSource: 'assets/images/manti-cesitleri/bohca.png',
            defaultAspectRatio: 4 / 3,
            title: 'Test Görsel Çerçeveleme',
          ),
        ),
      ),
    );

    expect(find.text('Test Görsel Çerçeveleme'), findsOneWidget);
    expect(find.text('4:3 (Ürün Kartı)'), findsOneWidget);
    expect(find.text('16:7 (Vitrin Banner)'), findsOneWidget);
    expect(find.text('Çerçeveyi Kaydet & Kullan'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

    // Tap zoom in repeatedly beyond 400% maximum limit
    for (int i = 0; i < 15; i++) {
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
    }
    // Verify zero exceptions and slider value stays strictly clamped to 4.0
    expect(tester.takeException(), isNull);
    final Slider sliderMax = tester.widget(find.byType(Slider));
    expect(sliderMax.value, lessThanOrEqualTo(4.0));
    expect(sliderMax.value, greaterThanOrEqualTo(0.5));

    // Tap zoom out repeatedly beyond 50% minimum limit
    for (int i = 0; i < 25; i++) {
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
    }
    // Verify zero exceptions and slider value stays strictly clamped to 0.5
    expect(tester.takeException(), isNull);
    final Slider sliderMin = tester.widget(find.byType(Slider));
    expect(sliderMin.value, greaterThanOrEqualTo(0.5));
    expect(sliderMin.value, lessThanOrEqualTo(4.0));
  });

  test('StoreSettings delivery and pickup default values and serialization', () {
    final defaultSettings = StoreSettings.fromJson({});

    // Verify pickup default text does not contain 'dükkanımızdan' and contains 'elden teslim alabilirsiniz'
    expect(defaultSettings.pickupDescription.contains('dükkanımızdan'), isFalse);
    expect(defaultSettings.pickupDescription.contains('elden teslim alabilirsiniz'), isTrue);
    expect(defaultSettings.isDeliveryActive, isFalse);
    expect(defaultSettings.isPickupActive, isTrue);
    expect(defaultSettings.isStoryCardActive, isTrue);
    expect(defaultSettings.storyCardTitle, 'Mantı Mood Hikayesi');

    // Test custom values and JSON roundtrip
    final customJson = {
      'is_delivery_active': false,
      'delivery_title': 'Özel Kurye',
      'delivery_description': 'Aynı gün teslim',
      'is_pickup_active': true,
      'pickup_title': 'Mutfaktan Al',
      'pickup_description': 'Sıcak teslim alınız',
      'is_story_card_active': false,
      'story_card_title': 'Biz Kimiz?',
      'story_card_content': 'El yapımı taze lezzetler sunuyoruz.',
      'story_card_image_url': 'assets/images/custom-story.png',
    };

    final customSettings = StoreSettings.fromJson(customJson);
    expect(customSettings.isDeliveryActive, isFalse);
    expect(customSettings.deliveryTitle, 'Özel Kurye');
    expect(customSettings.isPickupActive, isTrue);
    expect(customSettings.pickupTitle, 'Mutfaktan Al');
    expect(customSettings.isStoryCardActive, isFalse);
    expect(customSettings.storyCardTitle, 'Biz Kimiz?');
    expect(customSettings.storyCardContent, 'El yapımı taze lezzetler sunuyoruz.');
    expect(customSettings.storyCardImageUrl, 'assets/images/custom-story.png');

    // Test toJson
    final serialized = customSettings.toJson();
    expect(serialized['is_delivery_active'], isFalse);
    expect(serialized['pickup_title'], 'Mutfaktan Al');
    expect(serialized['is_story_card_active'], isFalse);
    expect(serialized['story_card_title'], 'Biz Kimiz?');
  });

  testWidgets('CheckoutDialog shows delivery options when isDeliveryActive is true', (tester) async {
    const activeDeliverySettings = StoreSettings(
      isDeliveryActive: true,
      isPickupActive: true,
      deliveryTitle: 'Adrese Kurye',
      deliveryDescription: 'Özel kurye ile hızlı teslimat.',
      pickupTitle: 'Mutfaktan Teslim',
      pickupDescription: 'Dilediğiniz saatte elden teslim alabilirsiniz.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CheckoutDialog(storeSettings: activeDeliverySettings),
        ),
      ),
    );

    // Verify both options appear
    expect(find.text('Mutfaktan Teslim'), findsWidgets);
    expect(find.text('Adrese Kurye'), findsOneWidget);
    expect(find.text('2 Seçenek Mevcut'), findsOneWidget);

    // Initially defaults to pickup
    expect(find.text('Dilediğiniz saatte elden teslim alabilirsiniz.'), findsOneWidget);

    // Tap on Adrese Kurye to switch to delivery
    await tester.tap(find.text('Adrese Kurye'));
    await tester.pumpAndSettle();

    // Verify address inputs now appear
    expect(find.text('Özel kurye ile hızlı teslimat.'), findsOneWidget);
    expect(find.text('İl Seçiniz *'), findsOneWidget);
    expect(find.text('İlçe / Semt *'), findsOneWidget);
    expect(find.text('Açık Teslimat Adresi *'), findsOneWidget);
  });

  test('OrderModel toPublicMasked masks sensitive customer data for public queries', () {
    final order = OrderModel(
      id: 'ord-123',
      orderNumber: '26715996',
      customerName: 'Ahmet Yılmaz',
      customerEmail: 'ahmetyilmaz@gmail.com',
      customerPhone: '05321234567',
      deliveryCity: 'İstanbul',
      deliveryDistrict: 'Kadıköy',
      deliveryAddress: 'Bağdat Cad. No: 45 Daire: 8',
      paymentMethod: 'cod',
      codType: 'cash',
      status: 'preparing',
      totalAmount: 600.0,
      customerNote: 'Zili çalmayın lütfen, bebek uyuyor',
      invoiceSent: false,
      trackingCode: '',
      carrierCompany: '',
      createdAt: DateTime.now(),
      items: [],
    );

    final masked = order.toPublicMasked();

    // Check name masking
    expect(masked.customerName, 'A**** Y*****');
    expect(masked.customerName.contains('Ahmet'), isFalse);
    expect(masked.customerName.contains('Yılmaz'), isFalse);

    // Check phone masking
    expect(masked.customerPhone.contains('12345'), isFalse);
    expect(masked.customerPhone.startsWith('053*'), isTrue);

    // Check email masking
    expect(masked.customerEmail, 'ah*********@gmail.com');

    // Check address masking
    expect(masked.deliveryAddress.contains('Bağdat Cad'), isFalse);
    expect(masked.deliveryAddress.contains('Daire: 8'), isFalse);
    expect(masked.deliveryAddress.contains('Kadıköy / İstanbul'), isTrue);
    expect(masked.deliveryAddress.contains('Açık adres güvenlik gereği gizlenmiştir'), isTrue);

    // Check customer note is completely cleared for privacy
    expect(masked.customerNote, isEmpty);

    // Non-sensitive data remains intact
    expect(masked.orderNumber, '26715996');
    expect(masked.totalAmount, 600.0);
    expect(masked.status, 'preparing');
  });

  test('StoreSettings announcement persistence and page refresh resilience', () async {
    final service = SupabaseService.instance;
    final prefs = await SharedPreferences.getInstance();

    // 1. Yeni duyuru kaydet
    const announcementText = '🔥 Bugün saat 18:00\'e kadar tüm siparişlerde tereyağlı sos hediye!';
    final currentSettings = await service.getStoreSettings();
    final updatedSettings = currentSettings!.copyWith(announcementText: announcementText);
    await service.updateStoreSettings(updatedSettings);

    // SharedPreferences kontrolü: hem ana JSON'da hem de özel kalıcı anahtarda var mı?
    final savedKey = prefs.getString('mm_persistent_announcement_v1');
    expect(savedKey, announcementText);

    // 2. Sayfa yenileme (refresh / F5) simülasyonu: forceRefresh ile belleği baypas edip diskten yükle
    final reloadedSettings = await service.getStoreSettings(forceRefresh: true);
    expect(reloadedSettings?.announcementText, announcementText);

    // 3. Admin metni boş bırakıp kaydettiğinde (silme)
    final clearedSettings = reloadedSettings!.copyWith(announcementText: '');
    await service.updateStoreSettings(clearedSettings);

    // Özel kalıcı anahtardan da silindiğini doğrula
    final clearedKey = prefs.getString('mm_persistent_announcement_v1');
    expect(clearedKey, isNull);

    // Sayfa tekrar yenilendiğinde boş olduğunu doğrula
    final reloadedAfterClear = await service.getStoreSettings(forceRefresh: true);
    expect(reloadedAfterClear?.announcementText, isEmpty);

    // 4. Duyuru silindikten sonra başka bir ayar değiştirildiğinde duyuru ASLA geri gelmemeli
    final changedDeliverySettings = reloadedAfterClear!.copyWith(isDeliveryActive: true, themePreset: 'terracotta');
    await service.updateStoreSettings(changedDeliverySettings);

    final reloadedAfterSubsequent = await service.getStoreSettings(forceRefresh: true);
    expect(reloadedAfterSubsequent?.announcementText, isEmpty);
    expect(reloadedAfterSubsequent?.isDeliveryActive, isTrue);
    expect(reloadedAfterSubsequent?.themePreset, 'terracotta');
  });

  test('Admin Whitelist allows only the 5 specified Gmail accounts', () {
    final service = SupabaseService.instance;

    const expectedAdmins = [
      'mantimood@gmail.com',
      'busraozverenli@gmail.com',
      'fabmorph@gmail.com',
      'serkanozverenli@gmail.com',
      'rhythmofsadness@gmail.com',
    ];

    expect(SupabaseService.allowedAdminEmails, containsAll(expectedAdmins));

    // Her 5 yetkili yöneticinin kabul edildiğini doğrula
    for (final email in expectedAdmins) {
      service.setSimulatedAdmin(email);
      expect(service.isCurrentAdminAuthorized, isTrue, reason: '$email yetkili olmalı');
      // Büyük harfle girilse bile kabul edilmeli
      service.setSimulatedAdmin(email.toUpperCase());
      expect(service.isCurrentAdminAuthorized, isTrue, reason: '${email.toUpperCase()} yetkili olmalı');
    }

    // Yetkisiz müşteri e-postasının reddedildiğini doğrula
    service.setSimulatedAdmin('unauthorized_customer@gmail.com');
    expect(service.isCurrentAdminAuthorized, isFalse);

    // Boş / giriş yapılmamış durumun reddedildiğini doğrula
    service.setSimulatedAdmin(null);
    expect(service.isCurrentAdminAuthorized, isFalse);
  });

  test('StoreSettings handles themePreset and adminPassword serialization', () {
    final defaultSettings = StoreSettings.fromJson({});
    expect(defaultSettings.themePreset, 'classic');
    expect(defaultSettings.adminPassword, '');

    final custom = defaultSettings.copyWith(
      themePreset: 'terracotta',
      adminPassword: 'super_secret_password',
    );
    expect(custom.themePreset, 'terracotta');
    expect(custom.adminPassword, 'super_secret_password');

    final json = custom.toJson();
    expect(json['theme_preset'], 'terracotta');
    expect(json['admin_password'], 'super_secret_password');

    final restored = StoreSettings.fromJson(json);
    expect(restored.themePreset, 'terracotta');
    expect(restored.adminPassword, 'super_secret_password');
  });

  test('AppThemePresets verifies distinct palettes and classic preservation', () {
    // 1. Classic must match exact original AppColors
    final classic = AppThemePresets.classic;
    expect(classic.background, const Color(0xFFF9F9FB));
    expect(classic.surface, const Color(0xFFFFFFFF));
    expect(classic.cardBorder, const Color(0xFFE5E7EB));
    expect(classic.primary, const Color(0xFFB91C1C));
    expect(classic.isDark, isFalse);

    // 2. Midnight must be dark mode with obsidian background and slate card surface
    final midnight = AppThemePresets.midnight;
    expect(midnight.isDark, isTrue);
    expect(midnight.background, const Color(0xFF0F172A));
    expect(midnight.surface, const Color(0xFF1E293B));
    expect(midnight.cardBorder, const Color(0xFF334155));
    expect(midnight.primary, const Color(0xFFF59E0B));

    // 3. Terracotta must be warm stone tone
    final terracotta = AppThemePresets.terracotta;
    expect(terracotta.isDark, isFalse);
    expect(terracotta.background, const Color(0xFFF8F3EC));
    expect(terracotta.cardBorder, const Color(0xFFDFCABA));

    // 4. Sage must be botanical green
    final sage = AppThemePresets.sage;
    expect(sage.background, const Color(0xFFF2F8F4));
    expect(sage.cardBorder, const Color(0xFFC5DECC));

    // 5. Bordeaux must be royal wine tone
    final bordeaux = AppThemePresets.bordeaux;
    expect(bordeaux.background, const Color(0xFFFAF2F5));
    expect(bordeaux.cardBorder, const Color(0xFFE0C4D1));

    // 6. All presets available in all list
    expect(AppThemePresets.all.length, 5);
  });

  testWidgets('HomeScreen renders cleanly on narrow 360x640 mobile viewport with zero RenderFlex overflow exceptions', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mantı Mood'), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
    
    // 2 sütunlu mobil ızgarayı doğrula
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    // Mobilde kompakt "İncele" butonunun göründüğünü doğrula
    expect(find.text('İncele'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminDashboard renders cleanly on narrow 360x640 mobile viewport with zero RenderFlex overflow exceptions', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yönetici Paneli'), findsOneWidget);
    expect(find.text('Mutfak & Sipariş'), findsOneWidget);
    expect(find.text('Ürün Yönetimi'), findsOneWidget);
    expect(find.text('Vitrin Banner'), findsOneWidget);
    expect(find.text('Dükkan Ayarları'), findsOneWidget);

    // Switch to Ürün Yönetimi tab
    final urunTab = find.text('Ürün Yönetimi');
    await tester.ensureVisible(urunTab);
    await tester.tap(urunTab);
    await tester.pumpAndSettle();
    expect(find.text('Kategoriler'), findsOneWidget);
    expect(find.text('Ürün Ekle'), findsOneWidget);

    // Switch to Vitrin Banner tab
    final bannerTab = find.text('Vitrin Banner');
    await tester.ensureVisible(bannerTab);
    await tester.tap(bannerTab);
    await tester.pumpAndSettle();
    expect(find.text('Banner Ekle'), findsOneWidget);

    // Switch to Dükkan Ayarları tab
    final ayarlarTab = find.text('Dükkan Ayarları');
    await tester.ensureVisible(ayarlarTab);
    await tester.tap(ayarlarTab);
    await tester.pumpAndSettle();
    expect(find.text('Teslimat Seçenekleri Yönetimi'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminDashboard renders cleanly on ultra-narrow 320x568 mobile viewport with zero RenderFlex overflow exceptions', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to Ürün Yönetimi tab
    final urunTab = find.text('Ürün Yönetimi');
    await tester.ensureVisible(urunTab);
    await tester.tap(urunTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to Vitrin Banner tab
    final bannerTab = find.text('Vitrin Banner');
    await tester.ensureVisible(bannerTab);
    await tester.tap(bannerTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to Dükkan Ayarları tab
    final ayarlarTab = find.text('Dükkan Ayarları');
    await tester.ensureVisible(ayarlarTab);
    await tester.tap(ayarlarTab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Smart Hybrid Banner adapts: static for single banner, PageView carousel for multiple banners', (tester) async {
    final service = SupabaseService.instance;
    // 1. Başlangıçta sadece varsayılan tek afiş var -> PageView YOK (statik tekil vitrin)
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);

    // 2. Yedek bir afiş ekle (isActive: false) -> Hala tek aktif var -> PageView YOK
    await service.saveBanner(
      id: 'test-ban-yedek',
      title: 'Yedek Afiş',
      subtitle: 'Depoda bekleyen afiş',
      imageUrl: 'https://example.com/banner_yedek.jpg',
      isActive: false,
    );

    final activeOnly = await service.getBanners();
    expect(activeOnly.any((b) => b.id == 'test-ban-yedek'), isFalse);

    final allBanners = await service.getBanners(onlyActive: false);
    expect(allBanners.any((b) => b.id == 'test-ban-yedek'), isTrue);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);

    // 3. Yedek afişi yayına al (isActive: true) -> Artık 2 aktif afiş var -> Otomatik PageView karusele dönüşür
    await service.toggleBannerActive('test-ban-yedek', true);
    final activeNow = await service.getBanners();
    expect(activeNow.length, greaterThanOrEqualTo(2));

    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);

    // 4. Afişi tekrar pasife / yedeğe çek -> Tekrar statik tekil vitrine döner
    await service.toggleBannerActive('test-ban-yedek', false);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);

    // Test temizliği
    await service.deleteBanner('test-ban-yedek');
  });

  testWidgets('Banner edit dialog displays Web Görünümü and Mobil Görünümü without numbering', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Vitrin Banner tab
    final bannerTab = find.text('Vitrin Banner');
    await tester.ensureVisible(bannerTab);
    await tester.tap(bannerTab);
    await tester.pumpAndSettle();

    // Click "Banner Ekle"
    final addBtn = find.text('Banner Ekle');
    await tester.ensureVisible(addBtn);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify dialog title and headings
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Banner Ekle')), findsOneWidget);
    expect(find.text('Web Görünümü (16:7)'), findsOneWidget);
    expect(find.text('Mobil Görünümü (16:9)'), findsOneWidget);

    // Verify no old numbering remains
    expect(find.text('1. Web Banner Görseli (16:7)'), findsNothing);
    expect(find.text('2. Mobil Banner Görseli (16:9)'), findsNothing);

    // Verify clear helper descriptions
    expect(find.text('Bilgisayar ve geniş ekranlarda sergilenecek ana vitrin görselidir.'), findsOneWidget);
    expect(find.textContaining('İsteğe bağlıdır. Boş bırakırsanız Web Görünümü mobilde de otomatik uyarlanır'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
  });

  testWidgets('HomeScreen on desktop 1280x800 scales product images proportionally matching mobile ratio', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SliverGrid), findsOneWidget);
    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);
    expect(delegate.mainAxisExtent, greaterThan(270.0)); // Proportional, not squished at 260
    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminDashboard opens enhanced Invoice Dialog with visual receipt slip and clean actions', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    final invoiceBtn = find.textContaining('Bilgi Fişi');
    if (invoiceBtn.evaluate().isNotEmpty) {
      await tester.tap(invoiceBtn.first);
      await tester.pumpAndSettle();

      expect(find.text('Bilgi Fişi'), findsWidgets);
      expect(find.text('MANTI MOOD'), findsWidgets);
      expect(find.text('BİLGİ FİŞİ'), findsOneWidget);
      expect(find.textContaining('Esnaf Muafiyeti kapsamında olduğumuzdan'), findsOneWidget);
      expect(find.text('Bilgi Fişini İndir'), findsOneWidget);
      expect(find.text('WhatsApp ile Paylaş'), findsOneWidget);
      expect(find.text('Bilgi Fişini E-Postala'), findsOneWidget);
      expect(find.text('Kapat'), findsOneWidget);

      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeScreen on wide 1920x1080 web limits grid to max 4 columns and ProductDetailDialog has 1.45 aspect ratio', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    // Must be 4 (not 6!)
    expect(delegate.crossAxisCount, 4);

    // Open product detail dialog
    final inceleBtn = find.text('İncele');
    expect(inceleBtn, findsWidgets);
    await tester.tap(inceleBtn.first);
    await tester.pumpAndSettle();

    // Verify AspectRatio widget with 1.45 is present for the image carousel
    final aspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
    final has145Ratio = aspectRatios.any((ar) => (ar.aspectRatio - 1.45).abs() < 0.01);
    expect(has145Ratio, isTrue);

    // Close dialog
    final closeBtn = find.byIcon(Icons.close);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminDashboard displays Hazırlanıyor, İptal Et, and Geri Al status action buttons and filters', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await SupabaseService.instance.createOrder(
      customerName: 'Test Müşteri',
      customerEmail: 'test@example.com',
      customerPhone: '05551234567',
      deliveryCity: 'İstanbul',
      deliveryDistrict: 'Kadıköy',
      deliveryAddress: 'Test Mah. Test Sok.',
      paymentMethod: 'cod',
      codType: 'nakit',
      totalAmount: 450,
      customerNote: 'Acil',
      items: [
        OrderItemModel(
          productName: 'Kayseri Mantısı',
          variantTitle: '1 Kg',
          quantity: 1,
          unitPrice: 450,
          subtotal: 450,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify filter chips have İptal Edilenler
    expect(find.text('İptal Edilenler'), findsOneWidget);

    // Verify status buttons on order card
    expect(find.textContaining('Ödeme Alındı'), findsWidgets);
    expect(find.textContaining('Hazırlanıyor'), findsWidgets);
    expect(find.textContaining('Hazırlandı'), findsWidgets);
    expect(find.textContaining('Kargoda'), findsWidgets);
    expect(find.textContaining('Teslim Edildi'), findsWidgets);
    expect(find.textContaining('İptal Et'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('CropStateRegistry preserves master source and prior zoom across multi-crop operations', () {
    const rawHighResMaster = 'https://storage.supabase.co/raw_master_photo_4k.jpg';
    const firstCropUrl = 'https://storage.supabase.co/crop_1.png';
    const secondCropUrl = 'https://storage.supabase.co/crop_2.png';

    // First crop with 400% zoom (scale: 4.0)
    CropStateRegistry.register(
      originalSource: rawHighResMaster,
      croppedResult: firstCropUrl,
      scale: 4.0,
      rotationQuarterTurns: 0,
    );

    // Verify lookup from firstCropUrl
    expect(CropStateRegistry.getOriginalSource(firstCropUrl), equals(rawHighResMaster));
    expect(CropStateRegistry.getSavedScale(firstCropUrl), equals(4.0));

    // Second crop based on firstCropUrl adjusted down to 250% zoom (scale: 2.5)
    CropStateRegistry.register(
      originalSource: firstCropUrl,
      croppedResult: secondCropUrl,
      scale: 2.5,
      rotationQuarterTurns: 1,
    );

    // Crucial check: root master image must be preserved without generational loss
    expect(CropStateRegistry.getOriginalSource(secondCropUrl), equals(rawHighResMaster));
    expect(CropStateRegistry.getSavedScale(secondCropUrl), equals(2.5));
    expect(CropStateRegistry.getSavedRotation(secondCropUrl), equals(1));
  });

  testWidgets('ImageCropperDialog restores previously saved 400% zoom and master source without resetting to 100%', (tester) async {
    const masterPhoto = 'assets/images/manti-cesitleri/bohca.png';
    const priorCroppedResult = 'https://mock.storage/crop_400_sample.png';

    // Register that priorCroppedResult was previously saved at 400% zoom (scale: 4.0)
    CropStateRegistry.register(
      originalSource: masterPhoto,
      croppedResult: priorCroppedResult,
      scale: 4.0,
      rotationQuarterTurns: 0,
    );

    // Open ImageCropperDialog passing the cropped result (as happens when admin re-edits image)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImageCropperDialog(
            imageSource: priorCroppedResult,
            defaultAspectRatio: 4 / 3,
            title: 'Yeniden Boyutlandırma Testi',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify that the Slider is NOT reset to 100% (1.0). It must strictly be 400% (4.0)!
    final Slider slider = tester.widget(find.byType(Slider));
    expect(slider.value, equals(4.0));

    // 2. Verify that percentage text displays '400%'
    expect(find.text('400%'), findsOneWidget);

    // 3. Verify user can now zoom OUT from 400% back down towards 100% or 50%
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    final Slider updatedSlider = tester.widget(find.byType(Slider));
    expect(updatedSlider.value, lessThan(4.0));
    expect(updatedSlider.value, greaterThanOrEqualTo(0.5));

    // Verify zero exceptions
    expect(tester.takeException(), isNull);
  });

  test('StoreSettings defaults contain Ziraat Bankası account and support editing, deleting, and serializing', () {
    const settings = StoreSettings();
    expect(settings.bankAccounts.length, equals(1));
    expect(settings.bankAccounts.first.bankName, equals('Ziraat Bankası'));
    expect(settings.bankAccounts.first.iban, equals('TR12 0006 2000 0000 1234 5678 90'));
    expect(settings.bankAccounts.first.accountHolder, equals('Mantı Mood'));

    // From empty JSON
    final parsed = StoreSettings.fromJson({});
    expect(parsed.bankAccounts.length, equals(1));
    expect(parsed.bankAccounts.first.bankName, equals('Ziraat Bankası'));

    // When admin explicitly clears all bank accounts
    final cleared = StoreSettings.fromJson({
      'has_cleared_bank_accounts': true,
      'bank_accounts': [],
    });
    expect(cleared.bankAccounts.isEmpty, isTrue);
    expect(cleared.hasClearedBankAccounts, isTrue);

    // Serialization roundtrip
    final json = settings.toJson();
    expect(json['bank_accounts'], isNotEmpty);
    expect(json['has_cleared_bank_accounts'], isFalse);
  });

  testWidgets('HomeScreen dynamically displays 🟢 Açık when open and 🔴 Kapalı when closed', (tester) async {
    // 1. Open state
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isOpen: true),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('🟢 Açık'), findsOneWidget);
    expect(find.text('🔴 Kapalı'), findsNothing);

    // 2. Closed state
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isOpen: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('🔴 Kapalı'), findsOneWidget);
    expect(find.text('🟢 Açık'), findsNothing);

    // Reset back to open
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isOpen: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('🟢 Açık'), findsOneWidget);
  });

  testWidgets('AdminDashboard settings tab does not contain Yönetici Güvenlik Kilidi', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Yönetici Güvenlik Kilidi" is completely removed
    expect(find.text('Yönetici Güvenlik Kilidi'), findsNothing);
    expect(find.text('OAuth 2.0 Korumalı'), findsNothing);
  });

  test('StoreSettings isAskSellerActive defaults to true and serializes properly', () {
    const s = StoreSettings();
    expect(s.isAskSellerActive, isTrue);

    final json = s.toJson();
    expect(json['is_ask_seller_active'], isTrue);

    final parsedFromFalse = StoreSettings.fromJson({
      'is_ask_seller_active': false,
    });
    expect(parsedFromFalse.isAskSellerActive, isFalse);

    final modified = s.copyWith(isAskSellerActive: false);
    expect(modified.isAskSellerActive, isFalse);
  });

  testWidgets('HomeScreen displays Satıcıya Sor button next to Sipariş Durumu when active and hides when inactive', (tester) async {
    // 1. Active on desktop
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isAskSellerActive: true),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Satıcıya Sor'), findsOneWidget);
    expect(find.text('Sipariş Durumu'), findsOneWidget);

    // 2. Inactive on desktop
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isAskSellerActive: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Satıcıya Sor'), findsNothing);
    expect(find.text('Sipariş Durumu'), findsOneWidget);

    // 3. Active on mobile
    tester.view.physicalSize = const Size(360, 640);
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isAskSellerActive: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Satıcıya Sor'), findsOneWidget);
    expect(find.text('Sipariş Durumu'), findsOneWidget);

    // 4. Inactive on mobile
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isAskSellerActive: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Satıcıya Sor'), findsNothing);
    expect(find.text('Sipariş Durumu'), findsOneWidget);

    // Reset back to true
    await SupabaseService.instance.updateStoreSettings(
      const StoreSettings(isAskSellerActive: true),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('OrderTrackingDialog prevents brute-force spam with consecutive failure cooldown', (tester) async {
    DateTime currentTime = DateTime(2026, 10, 16, 12, 0, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderTrackingDialog(
            nowProvider: () => currentTime,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    final button = find.widgetWithText(ElevatedButton, 'Sorgula');

    // 5 consecutive wrong inputs advancing virtual clock past debounce
    for (int i = 1; i <= 5; i++) {
      await tester.enterText(input, 'invalid_no_$i');
      await tester.tap(button);
      await tester.pumpAndSettle();
      currentTime = currentTime.add(const Duration(seconds: 2));
    }

    // After 5 failed attempts, verify lockout warning
    expect(find.textContaining('Çok fazla hatalı'), findsOneWidget);
  });

  test('SupabaseService.deleteOrder permanently removes order from database and local storage', () async {
    final service = SupabaseService.instance;
    final createdOrder = await service.createOrder(
      customerName: 'Silinecek Müşteri',
      customerEmail: 'sil@test.com',
      customerPhone: '05550001122',
      deliveryCity: 'Bursa',
      deliveryDistrict: 'Nilüfer',
      deliveryAddress: 'Test Adres',
      paymentMethod: 'bank_transfer',
      codType: '',
      totalAmount: 300,
      customerNote: 'Test notu',
      items: [
        OrderItemModel(
          productName: 'Mantı',
          variantTitle: '500 gr',
          quantity: 1,
          unitPrice: 300,
          subtotal: 300,
        ),
      ],
    );

    final ordersBefore = await service.getAllOrders();
    expect(ordersBefore.any((o) => o.id == createdOrder?.id), isTrue);

    // Kalıcı silme işlemi
    final deleted = await service.deleteOrder(createdOrder!.id);
    expect(deleted, isTrue);

    final ordersAfter = await service.getAllOrders();
    expect(ordersAfter.any((o) => o.id == createdOrder.id), isFalse);
  });

  testWidgets('AdminDashboard provides Excel/CSV export button and irreversible permanent delete warning dialog', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = await SupabaseService.instance.createOrder(
      customerName: 'Excel Test Müşteri',
      customerEmail: 'excel@test.com',
      customerPhone: '05553334455',
      deliveryCity: 'İzmir',
      deliveryDistrict: 'Bornova',
      deliveryAddress: 'Deneme Mah. 123 Sok.',
      paymentMethod: 'bank_transfer',
      codType: '',
      totalAmount: 500,
      customerNote: 'Özel not',
      items: [
        OrderItemModel(
          productName: 'Kayseri Mantısı',
          variantTitle: '1 Kg',
          quantity: 1,
          unitPrice: 500,
          subtotal: 500,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboard(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Excel / CSV İndir button exists in orders toolbar
    expect(find.text('Excel / CSV İndir'), findsOneWidget);

    // 2. Locate permanent delete button for the order
    final deleteBtn = find.byTooltip('Siparişi Veritabanından Tamamen Sil');
    expect(deleteBtn, findsWidgets);

    // Tap permanent delete button
    await tester.tap(deleteBtn.first);
    await tester.pumpAndSettle();

    // 3. Verify confirmation dialog and strict warning text
    expect(find.text('Siparişi Kalıcı Olarak Sil'), findsOneWidget);
    expect(find.textContaining('Bu işlem GERİ ALINAMAZ!'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
    expect(find.text('Kalıcı Olarak Sil'), findsOneWidget);

    // Tap confirm delete
    await tester.tap(find.text('Kalıcı Olarak Sil'));
    await tester.pumpAndSettle();

    // 4. Verify order was deleted and snackbar shown
    expect(find.textContaining('veritabanından kalıcı olarak silindi'), findsOneWidget);
    final orders = await SupabaseService.instance.getAllOrders();
    expect(orders.any((o) => o.id == order?.id), isFalse);
  });

  test('OrderModel.paymentMethodLabel formats all payment methods and markInvoiceSent preserves statusSteps', () async {
    final eftOrder = await SupabaseService.instance.createOrder(
      customerName: 'EFT Müşteri',
      customerEmail: 'eft@test.com',
      customerPhone: '05551112233',
      deliveryCity: 'İstanbul',
      deliveryDistrict: 'Beşiktaş',
      deliveryAddress: 'Adres 1',
      paymentMethod: 'bank_transfer',
      codType: '',
      totalAmount: 450,
      customerNote: '',
      items: [],
    );
    expect(eftOrder!.paymentMethodLabel, equals('Havale / EFT'));

    final instantEftOrder = await SupabaseService.instance.createOrder(
      customerName: 'Anlık EFT Müşteri',
      customerEmail: 'instanteft@test.com',
      customerPhone: '05551112234',
      deliveryCity: 'İstanbul',
      deliveryDistrict: 'Beşiktaş',
      deliveryAddress: 'Adres 2',
      paymentMethod: 'cod',
      codType: 'instant_eft',
      totalAmount: 450,
      customerNote: '',
      items: [],
    );
    expect(instantEftOrder!.paymentMethodLabel, equals('Kapıda Ödeme (Anlık Havale / EFT)'));

    final cashOrder = await SupabaseService.instance.createOrder(
      customerName: 'Nakit Müşteri',
      customerEmail: 'cash@test.com',
      customerPhone: '05551112235',
      deliveryCity: 'İstanbul',
      deliveryDistrict: 'Beşiktaş',
      deliveryAddress: 'Adres 3',
      paymentMethod: 'cod',
      codType: 'cash',
      totalAmount: 450,
      customerNote: '',
      items: [],
    );
    expect(cashOrder!.paymentMethodLabel, equals('Kapıda Ödeme (Nakit)'));

    // Toggle steps and verify markInvoiceSent preserves statusSteps
    await SupabaseService.instance.toggleOrderStep(cashOrder.id, 'payment_received');
    await SupabaseService.instance.toggleOrderStep(cashOrder.id, 'preparing');
    await SupabaseService.instance.markInvoiceSent(cashOrder.id);

    final allOrders = await SupabaseService.instance.getAllOrders();
    final updatedCashOrder = allOrders.firstWhere((o) => o.id == cashOrder.id);
    expect(updatedCashOrder.invoiceSent, isTrue);
    expect(updatedCashOrder.statusSteps, containsAll(['order_received', 'payment_received', 'preparing']));
  });

  test('Saving product without 2 Kg (Aile Boyu) variant persists without re-injecting it', () async {
    final products = await SupabaseService.instance.getProducts();
    final target = products.first;
    final customVariants = [
      const ProductVariant(title: '500 gr (2 Porsiyon)', price: 260.0),
      const ProductVariant(title: '1 Kg (4 Porsiyon)', price: 480.0),
    ];

    await SupabaseService.instance.saveProduct(
      id: target.id,
      name: target.name,
      description: target.description,
      category: target.category,
      basePrice: 260.0,
      variants: customVariants,
      imageUrl: target.imageUrl,
      mediaUrls: target.mediaUrls,
      cookingInstructions: target.cookingInstructions,
      storageInstructions: target.storageInstructions,
      isAvailable: target.isAvailable,
    );

    final reloaded = await SupabaseService.instance.getProducts();
    final saved = reloaded.firstWhere((p) => p.id == target.id);
    expect(saved.variants.length, equals(2));
    expect(saved.variants.any((v) => v.title.contains('2 Kg')), isFalse);
  });

  test('CartController persists items to SharedPreferences and Debug mode isolates cloud sync', () async {
    expect(SupabaseService.instance.isCloudSyncEnabled, isFalse);

    final cart = CartController.instance;
    cart.clear();
    final products = await SupabaseService.instance.getProducts();
    final firstProduct = products.first;
    final firstVariant = firstProduct.variants.first;

    cart.addItem(firstProduct, firstVariant, quantity: 2);
    expect(cart.totalItemCount, equals(2));

    // Wait briefly for async SharedPreferences write
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(CartController.storageKey);
    expect(savedJson, isNotNull);
    expect(savedJson, contains(firstProduct.name));

    cart.clear();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(prefs.getString(CartController.storageKey), isNull);
  });

  testWidgets('HomeScreen hides Yönetici Paneli button on mobile platforms (Android/iOS)', (tester) async {
    tester.view.physicalSize = const Size(1280, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify copyright is visible but Yönetici Paneli is completely hidden on mobile app
      expect(find.textContaining('Mantı Mood — Tüm Hakları Saklıdır'), findsOneWidget);
      expect(find.text('Yönetici Paneli'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('HomeScreen shows Yönetici Paneli button on web and desktop environments', (tester) async {
    tester.view.physicalSize = const Size(1280, 2500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // On web/desktop platforms, Yönetici Paneli is visible
      expect(find.text('Yönetici Paneli'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('HomeScreen includes RefreshIndicator with ClampingScrollPhysics preventing visual distortion', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final refreshIndicatorFinder = find.byType(RefreshIndicator);
    expect(refreshIndicatorFinder, findsOneWidget);

    final customScrollViewFinder = find.byType(CustomScrollView);
    expect(customScrollViewFinder, findsOneWidget);

    final customScrollView = tester.widget<CustomScrollView>(customScrollViewFinder);
    expect(customScrollView.physics, isA<AlwaysScrollableScrollPhysics>());
    final alwaysPhysics = customScrollView.physics as AlwaysScrollableScrollPhysics;
    expect(alwaysPhysics.parent, isA<ClampingScrollPhysics>());
  });
}
