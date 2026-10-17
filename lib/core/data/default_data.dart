// ==============================================================================
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
  static const String syncedAt = '2026-10-17T13:23:23.323';

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
  static const Map<String, dynamic> _rawStoreSettings = {
  "id": "33518982-fe82-434b-a673-8e848f59ca67",
  "store_name": "Mantı Mood",
  "is_open": true,
  "whatsapp_number": "905551234567",
  "min_order_amount": 0,
  "free_delivery_threshold": 500,
  "announcement_text": "",
  "is_delivery_active": true,
  "delivery_title": "Adrese Teslimat (Kurye / Kargo)",
  "delivery_description": "Siparişiniz adresinize özenle teslim edilir.",
  "is_pickup_active": true,
  "pickup_title": "Gel-Al / Mutfaktan Teslim",
  "pickup_description": "Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.",
  "is_bank_transfer_active": true,
  "is_cod_active": true,
  "is_ask_seller_active": true,
  "has_cleared_bank_accounts": false,
  "bank_accounts": [
    {
      "bank_name": "Ziraat Bankası",
      "iban": "TR12 0006 2000 0000 1234 5678 80",
      "account_holder": "Test Amaçlıdır"
    }
  ],
  "badges": [
    {
      "icon": "🥩",
      "title": "%100 Dana Eti",
      "subtitle": "Katkısız Harç"
    },
    {
      "icon": "🥟",
      "title": "Günlük Taze",
      "subtitle": "El Açması Hamur"
    },
    {
      "icon": "✨",
      "title": "Özel Tarif",
      "subtitle": "Geleneksel Lezzet"
    }
  ],
  "categories": [
    "Klasik Mantı",
    "Yöresel Mantı",
    "Sebzeli & Vejetaryen",
    "Soslar & Yan Ürünler"
  ],
  "is_story_card_active": true,
  "story_card_title": "Mantı Mood Hikayesi",
  "story_card_content": "Evimizde annelerimizin elleriyle, taptaze un ve %100 yerli dana kıymayla tek tek büktüğümüz geleneksel lezzeti sofranıza getiriyoruz. Hiçbir koruyucu veya katkı maddesi kullanmadan, şok dondurarak tazeliğini ilk günkü gibi muhafaza ediyoruz.",
  "story_card_image_url": "assets/images/manti-mood-logo.png",
  "theme_preset": "classic",
  "admin_password": "",
  "iban": "TR12 0006 2000 0000 1234 5678 80",
  "bank_name": "Ziraat Bankası",
  "account_holder": "Test Amaçlıdır"
};

  static const List<Map<String, dynamic>> _rawProducts = [
  {
    "id": "c97cf2b0-ca82-40e6-9e39-ea2bb9528574",
    "name": "Bohça Mantı (Geleneksel)",
    "description": "Elde tek tek bükülen dört köşeli geleneksel bohça mantı. Bol dana kıymalı, incecik el açması.",
    "category": "Klasik Mantı",
    "base_price": 500,
    "variants": [
      {
        "title": "500 gr (1 Paket)",
        "price": 500
      },
      {
        "title": "1 Kg (2 Paket)",
        "price": 1000
      }
    ],
    "image_url": "assets/images/manti-cesitleri/bohca.png",
    "media_urls": [
      "assets/images/manti-cesitleri/bohca.png"
    ],
    "cooking_instructions": "Kaynayan bol tuzlu suya şoklanmış mantıları atın. 8-10 dakika haşlayın. Sarımsaklı yoğurt ve kızgın tereyağı ile servis yapın.",
    "storage_instructions": "-18°C dondurucuda 3 ay tazeliğini korur.",
    "is_available": true,
    "is_featured": true,
    "sort_order": 1
  },
  {
    "id": "990da49d-d4c0-4f61-9fc0-14365cd44a78",
    "name": "Hıngel Mantısı",
    "description": "Geleneksel Kafkas & Sivas usulü iri taneli hıngel mantı. Zengin iç harç ve yumuşacık hamur.",
    "category": "Yöresel Mantı",
    "base_price": 350,
    "variants": [
      {
        "title": "500 gr (1 Paket)",
        "price": 350
      },
      {
        "title": "1 Kg (2 Paket)",
        "price": 700
      }
    ],
    "image_url": "assets/images/manti-cesitleri/hingel.png",
    "media_urls": [
      "assets/images/manti-cesitleri/hingel.png"
    ],
    "cooking_instructions": "Kaynayan tuzlu suda 9-11 dakika orta ateşte haşlayın.",
    "storage_instructions": "-18°C dondurucuda saklayınız.",
    "is_available": true,
    "is_featured": true,
    "sort_order": 2
  },
  {
    "id": "14d878c8-6cfb-43d3-9887-7011be1a8bf6",
    "name": "Örgü Mantı",
    "description": "Özel örgü dikişi tekniğiyle kapatılmış, tüm lezzeti ve suyunu içine hapseden el emeği mantı.",
    "category": "Yöresel Mantı",
    "base_price": 500,
    "variants": [
      {
        "title": "500 gr (1 Paket)",
        "price": 500
      },
      {
        "title": "1 Kg (2 Paket)",
        "price": 1000
      }
    ],
    "image_url": "assets/images/manti-cesitleri/orgu.png",
    "media_urls": [
      "assets/images/manti-cesitleri/orgu.png"
    ],
    "cooking_instructions": "Kaynayan suda 8-10 dakika haşlayın.",
    "storage_instructions": "-18°C dondurucuda saklayınız.",
    "is_available": true,
    "is_featured": true,
    "sort_order": 3
  },
  {
    "id": "bea6dcc3-1615-4871-a0c0-4ec12cd42612",
    "name": "Pelmeni Mantısı",
    "description": "Yuvarlak ince hamurun özenle kapatılmasıyla hazırlanan, sulu ve bol etli geleneksel pelmeni.",
    "category": "Klasik Mantı",
    "base_price": 500,
    "variants": [
      {
        "title": "500 gr (2 Porsiyon)",
        "price": 500
      },
      {
        "title": "1 Kg (4 Porsiyon)",
        "price": 1000
      }
    ],
    "image_url": "assets/images/manti-cesitleri/pelmeni.png",
    "media_urls": [
      "assets/images/manti-cesitleri/pelmeni.png"
    ],
    "cooking_instructions": "Kaynayan suda 7-9 dakika haşlayınız.",
    "storage_instructions": "-18°C dondurucuda saklayınız.",
    "is_available": true,
    "is_featured": false,
    "sort_order": 4
  },
  {
    "id": "ad1eb217-2370-4e05-849e-2ab92ffbca97",
    "name": "Sebzeli Renkli Mantı",
    "description": "Ispanak, pancar ve zerdeçallı %100 doğal sebze pürelerinden hazırlanan renkli ve besleyici mantı.",
    "category": "Sebzeli & Vejetaryen",
    "base_price": 750,
    "variants": [
      {
        "title": "500 gr (1 Paket)",
        "price": 750
      },
      {
        "title": "1 Kg (2 Paket)",
        "price": 1500
      }
    ],
    "image_url": "assets/images/manti-cesitleri/sebzeli.png",
    "media_urls": [
      "assets/images/manti-cesitleri/sebzeli.png"
    ],
    "cooking_instructions": "Kaynar tuzlu suda 7-8 dakika haşlayınız.",
    "storage_instructions": "-18°C dondurucuda saklayınız.",
    "is_available": true,
    "is_featured": true,
    "sort_order": 5
  },
  {
    "id": "5145543f-2b99-4878-b7f6-3c3984c18f91",
    "name": "Fırınlanmış Tepsi Mantısı",
    "description": "Tepsiye tek tek dizilip nar gibi kızarana kadar fırınlanmış, çıtır ve lezzetli tepsi mantısı.",
    "category": "Yöresel Mantı",
    "base_price": 750,
    "variants": [
      {
        "title": "500 gr (1 Paket)",
        "price": 750
      },
      {
        "title": "1 Kg (2 Paket)",
        "price": 1000
      }
    ],
    "image_url": "assets/images/manti-cesitleri/tepsi_mantisi.png",
    "media_urls": [
      "assets/images/manti-cesitleri/tepsi_mantisi.png"
    ],
    "cooking_instructions": "Üzerine sıcak salçalı et suyu gezdirerek ocakta veya fırında suyunu çekene kadar pişirin.",
    "storage_instructions": "Kuru ve serin yerde veya dondurucuda muhafaza ediniz.",
    "is_available": true,
    "is_featured": true,
    "sort_order": 6
  }
];

  static const List<Map<String, dynamic>> _rawBanners = [
  {
    "id": "765986dc-0f55-4cf9-85f4-1ad0f1845752",
    "title": "Kayseri Usulü El Açması Mantı",
    "subtitle": "%100 yerli dana eti ve anne eli lezzetiyle sofranızda.",
    "image_url": "assets/images/manti-cesitleri/vitrin.webp",
    "mobile_image_url": "https://oeyoeoazhskwgnckeckz.supabase.co/storage/v1/object/public/products/crop_1792146275739.png",
    "action_url": "",
    "is_active": true,
    "display_order": 1
  },
  {
    "id": "c974b01a-e5a9-495c-b7b4-301773ddb6f7",
    "title": "",
    "subtitle": "",
    "image_url": "https://oeyoeoazhskwgnckeckz.supabase.co/storage/v1/object/public/products/crop_1792146217855.png",
    "mobile_image_url": "https://oeyoeoazhskwgnckeckz.supabase.co/storage/v1/object/public/products/crop_1792146237262.png",
    "action_url": "",
    "is_active": true,
    "display_order": 2
  }
];
}
