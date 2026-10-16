# 🥟 Mantı Mood — Ev Yapımı El Mantısı & Yöresel Lezzetler

<div align="center">
  <img src="assets/images/manti-mood-logo.png" alt="Mantı Mood Logo" width="120" />
  <p><strong>Geleneksel anne eli lezzetini modern teknolojiyle sofralara taşıyan gurme e-ticaret platformu.</strong></p>
  <p>
    <a href="https://mantimood.pages.dev/">Web Canlı Yayın (Cloudflare Pages)</a> • 
    <a href="https://github.com/FabMorph/manti-mood">GitHub Deposu</a>
  </p>
</div>

---

## ✨ Özellikler

* **📱 Çift Platform (Web & Mobil):** Flutter ile tek kod tabanından hem Web (PWA / Cloudflare Pages) hem de yerel Android (APK / Google Play AAB) ve iOS desteği.
* **⚡ Bulut-Öncelikli Senkronizasyon (Supabase):** Dükkan sahibi yönetim panelinden fiyat, stok veya afiş değiştirdiğinde web ve mobil müşterilere anında yansır.
* **🛡️ Akıllı Yenileme (Pull-to-Refresh):** Mobilde ekran aşağı çekildiğinde arayüzü, logoları veya afişleri esnetip bozmadan (`ClampingScrollPhysics`) verileri tazeleyen yapı.
* **🚀 3 Saniyede Arka Plan Ön Yüklemesi:** Mobil açılış animasyonu (Splash) oynarken arka planda Supabase verileri ve vitrin görselleri belleğe (`CachedNetworkImage`) alınır, ana sayfa sıfır gecikmeyle açılır.
* **📦 Kapsamlı Sipariş ve Takip Sistemi:**
  * Müşteriler için SMS/WhatsApp veya kod ile canlı sipariş durumu takibi.
  * Adrese teslimat ve Gel-Al (Mutfaktan Teslim) seçenekleri.
  * Havale/EFT ve Kapıda Ödeme desteği.
  * Otomatik görsel fiş/fatura üretimi ve e-posta bildirimi.
* **🔐 Güvenli Yönetici Paneli:**
  * Yalnızca yetkili Google hesaplarına açık Whitelist korumalı yönetim arayüzü.
  * Ürün yönetimi, fiyatlandırma, varyantlar, stok açma/kapama.
  * Vitrin bannerları ekleme ve kırpma (16:7 Web & 16:9 Mobil uyumlu).
  * Canlı sipariş yönetimi, durum adımları (Hazırlanıyor, Yolda, Teslim Edildi), Excel/CSV dışa aktarım.
* **🎨 Dinamik Tema Motoru:** Yönetici panelinden anlık olarak değiştirilebilen renk paletleri ve kurumsal tasarım dili.

---

## 🛠️ Teknoloji Yığını

* **Frontend:** [Flutter](https://flutter.dev) (Dart 3.x)
* **Backend & Veritabanı:** [Supabase](https://supabase.com) (PostgreSQL, Row Level Security, Storage, Edge Functions)
* **Web Hosting:** [Cloudflare Pages](https://pages.cloudflare.com)
* **Mobil Dağıtım:** Google Play Console (Android App Bundle - AAB & APK)

---

## 🚀 Başlangıç ve Çalıştırma

### Gereksinimler
* Flutter SDK (3.x veya üzeri)
* Git

### Kurulum
```bash
# Depoyu klonlayın
git clone https://github.com/FabMorph/manti-mood.git
cd manti-mood

# Bağımlılıkları yükleyin
flutter pub get

# Web üzerinde çalıştırmak için
flutter run -d chrome

# Android üzerinde çalıştırmak için
flutter run -d android
```

### Derleme (Release)
```bash
# Web sürümü
flutter build web --release

# Android App Bundle (Google Play Store)
flutter build appbundle --release

# Android APK (Doğrudan Yükleme)
flutter build apk --release
```

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.
