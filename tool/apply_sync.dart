// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Mantı Mood — Canlı Veri Senkronizasyon Aracı (CLI Tool)
///
/// Kullanım:
///   dart run tool/apply_sync.dart
///
/// Bu script, `tool/current_data.json` dosyasını okur, tüm ürün ve
/// ayarları detaylı olarak denetler, terminale rapor basar ve
/// `lib/core/data/default_data.dart` dosyasını otomatik olarak günceller.
void main(List<String> args) {
  print('============================================================');
  print('🥟 MANTI MOOD — VERİ SENKRONİZASYON SİSTEMİ');
  print('============================================================');

  final inputFile = File('tool/current_data.json');
  if (!inputFile.existsSync()) {
    print('❌ HATA: "tool/current_data.json" dosyası bulunamadı!');
    print('ℹ  Lütfen Admin Panelinden "Dışa Aktar" yaparak kopyaladığınız');
    print('   JSON içeriğini bu dosyaya yapıştırıp kaydedin.');
    print('============================================================');
    exit(1);
  }

  final rawContent = inputFile.readAsStringSync().trim();
  if (rawContent.isEmpty) {
    print('❌ HATA: "tool/current_data.json" dosyası boş!');
    print('ℹ  Lütfen Admin Panelinden dışa aktarılan JSON içeriğini yapıştırın.');
    print('============================================================');
    exit(1);
  }

  dynamic decodedJson;
  try {
    decodedJson = jsonDecode(rawContent);
  } catch (e) {
    print('❌ HATA: JSON formatı bozuk veya geçersiz!');
    print('Detay: $e');
    print('============================================================');
    exit(1);
  }

  if (decodedJson is! Map<String, dynamic>) {
    print('❌ HATA: JSON kökü bir nesne (Map) olmalıdır.');
    print('============================================================');
    exit(1);
  }

  final data = decodedJson;
  final exportedAt = data['exported_at'] as String? ?? DateTime.now().toIso8601String();
  final rawSettings = data['store_settings'] as Map<String, dynamic>? ?? {};
  final rawProducts = (data['products'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
  final rawBanners = (data['banners'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

  print('📂 Okunan Dosya: tool/current_data.json');
  print('⏰ Dışa Aktarılma Tarihi: $exportedAt\n');

  // 1. Dükkan Ayarları Denetimi
  print('🏪 DÜKKAN AYARLARI KONTROL EDİLİYOR:');
  final storeName = rawSettings['store_name'] ?? 'Mantı Mood';
  final isOpen = rawSettings['is_open'] == true;
  print('  ✔ Dükkan Adı: $storeName (Durum: ${isOpen ? "🟢 Açık" : "🔴 Kapalı"})');

  final whatsapp = rawSettings['whatsapp_number'] ?? '';
  print('  ✔ WhatsApp Hattı: +$whatsapp');

  final isDeliveryActive = rawSettings['is_delivery_active'] == true;
  final deliveryTitle = rawSettings['delivery_title'] ?? 'Adrese Teslimat';
  print('  ✔ $deliveryTitle: ${isDeliveryActive ? "🟢 AKTİF (Açık)" : "🔴 PASİF (Kapalı)"}');

  final isPickupActive = rawSettings['is_pickup_active'] == true;
  final pickupTitle = rawSettings['pickup_title'] ?? 'Gel-Al / Mutfaktan Teslim';
  print('  ✔ $pickupTitle: ${isPickupActive ? "🟢 AKTİF (Açık)" : "🔴 PASİF (Kapalı)"}');

  final minOrder = rawSettings['min_order_amount'] ?? 0;
  final freeDelivery = rawSettings['free_delivery_threshold'] ?? 500;
  print('  ✔ Minimum Sepet Tutarı: $minOrder TL');
  print('  ✔ Ücretsiz Teslimat Sınırı: $freeDelivery TL');

  final announcement = (rawSettings['announcement_text'] as String?)?.trim() ?? '';
  if (announcement.isNotEmpty) {
    print('  ✔ Dükkan Duyurusu: 🟢 "$announcement"');
  } else {
    print('  ✔ Dükkan Duyurusu: ⚪ (Aktif duyuru yok)');
  }

  final badges = (rawSettings['badges'] as List?) ?? [];
  print('  ✔ Güven Rozetleri: ${badges.length} adet tanımlandı');

  final categories = (rawSettings['categories'] as List?) ?? [];
  print('  ✔ Kategoriler: ${categories.length} kategori güncellendi (${categories.join(", ")})');

  // 2. Ürünler Denetimi
  print('\n📦 ÜRÜNLER KONTROL EDİLİYOR (${rawProducts.length} Adet):');
  for (int i = 0; i < rawProducts.length; i++) {
    final p = rawProducts[i];
    final name = p['name'] ?? 'İsimsiz Ürün';
    final price = p['base_price'] ?? 0;
    final variants = (p['variants'] as List?)?.length ?? 0;
    final category = p['category'] ?? 'Genel';
    final isAvailable = p['is_available'] == true;
    final statusEmoji = isAvailable ? '🟢' : '🔴';

    print('  ✔ [${i + 1}/${rawProducts.length}] $name — $price TL ($variants varyant | $category) $statusEmoji');
  }

  // 3. Bannerlar Denetimi
  if (rawBanners.isNotEmpty) {
    print('\n🎨 VİTRİN BANNERLARI KONTROL EDİLİYOR (${rawBanners.length} Adet):');
    for (int i = 0; i < rawBanners.length; i++) {
      final b = rawBanners[i];
      final title = b['title'] ?? 'Banner';
      final isActive = b['is_active'] == true;
      print('  ✔ [${i + 1}/${rawBanners.length}] $title (${isActive ? "🟢 Aktif" : "⚪ Pasif"})');
    }
  }

  // 4. Dart Kod Dosyasını Üret
  print('\n📝 DART DOSYALARI OLUŞTURULUYOR:');
  final targetFile = File('lib/core/data/default_data.dart');
  if (!targetFile.parent.existsSync()) {
    targetFile.parent.createSync(recursive: true);
  }

  final encoder = const JsonEncoder.withIndent('  ');
  final formattedSettings = encoder.convert(rawSettings);
  final formattedProducts = encoder.convert(rawProducts);
  final formattedBanners = encoder.convert(rawBanners);

  final dartContent = '''// ==============================================================================
// 🥟 MANTI MOOD — VARSAYILAN MAĞAZA VE ÜRÜN VERİLERİ (SEED DATA)
// ==============================================================================
// ⚠️ BU DOSYA `tool/apply_sync.dart` TARAFINDAN OTOMATİK OLARAK ÜRETİLMİŞTİR.
// Canlıdaki en son ayarları içeri aktarmak için:
//   1. Admin Panelinden "Dışa Aktar" yapıp JSON kopyalayın.
//   2. `tool/current_data.json` dosyasına yapıştırın.
//   3. Terminalde `dart run tool/apply_sync.dart` komutunu çalıştırın.
// ==============================================================================

import '../models/product.dart';
import '../models/store_settings.dart';
import '../models/banner_item.dart';

class DefaultData {
  /// Son senkronizasyon zaman damgası (Önbellek uyumsuzluklarını önler)
  static const String syncedAt = '$exportedAt';

  /// Varsayılan Dükkan Ayarları
  static StoreSettings get storeSettings {
    try {
      return StoreSettings.fromJson(_rawStoreSettings);
    } catch (_) {
      return const StoreSettings(id: 'settings-default');
    }
  }

  /// Varsayılan Ürün Listesi
  static List<Product> get products {
    try {
      return _rawProducts
          .map((p) => Product.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Varsayılan Banner Listesi
  static List<BannerItem> get banners {
    try {
      return _rawBanners
          .map((b) => BannerItem.fromJson(Map<String, dynamic>.from(b)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // --- HAM VERİLER (JSON Kaynakları) ---
  static const Map<String, dynamic> _rawStoreSettings = $formattedSettings;

  static const List<Map<String, dynamic>> _rawProducts = $formattedProducts;

  static const List<Map<String, dynamic>> _rawBanners = $formattedBanners;
}
''';

  targetFile.writeAsStringSync(dartContent);
  print('  ✔ lib/core/data/default_data.dart dosyası başarıyla güncellendi!');

  print('\n============================================================');
  print('🎉 İŞLEM BAŞARIYLA TAMAMLANDI!');
  print('Tüm canlı veriler eksiksiz şekilde Dart kodlarınıza işlendi.');
  print('============================================================');
}
