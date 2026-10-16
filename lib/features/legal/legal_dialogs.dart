import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../cart/cart_controller.dart';

class LegalDialogs {
  LegalDialogs._();

  /// Resmi FabMorph Gizlilik Politikası ve KVKK Aydınlatma Metni Doğrudan Çapa Bağlantısı
  static const String privacyPolicyUrl = 'https://fabmorph.github.io/Privacy-Policy/#manti-mood';

  /// Resmi gizlilik politikasını harici tarayıcıda doğrudan Mantı Mood başlığıyla açar
  static Future<bool> openPrivacyPolicyOnline() async {
    final uri = Uri.parse(privacyPolicyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  static void showPrivacyPolicy(BuildContext context) {
    _showLegalModal(
      context,
      title: 'Gizlilik ve Çerez Politikası',
      content: '''
MANTI MOOD GİZLİLİK VE ÇEREZ POLİTİKASI

Son Güncelleme: 15 Ekim 2026

Mantı Mood olarak, müşterilerimizin ve ziyaretçilerimizin kişisel verilerinin gizliliğine ve güvenliğine büyük önem veriyoruz. Bu metin, web sitemizi ve mobil uygulamamızı kullandığınızda verilerinizin nasıl toplandığını, işlendiğini ve korunduğunu açıklar.

1. TOPLANAN VERİLER
- Kimlik ve İletişim Bilgileri: Adınız, soyadınız, telefon numaranız, e-posta adresiniz.
- Teslimat Bilgileri: Siparişinizin ulaştırılacağı il, ilçe ve açık adresiniz.
- Sipariş ve Ödeme Bilgileri: Satın aldığınız mantı ve sos çeşitleri, sipariş geçmişiniz, seçtiğiniz ödeme türü (Havale/EFT veya Kapıda Ödeme). Kart bilgileriniz sistemimizde ASLA toplanmaz ve saklanmaz.

2. VERİLERİN KULLANIM AMACI
Toplanan veriler yalnızca;
- Siparişlerinizin taze hazırlanıp adresinize teslim edilmesi,
- Sipariş durumunuz hakkında (Hazırlanıyor, Yola Çıktı vb.) bilgilendirme yapılması,
- Sipariş bilgi fişinin e-posta adresinize iletilmesi,
- Müşteri destek taleplerinizin (WhatsApp vb.) karşılanması amacıyla kullanılır.

3. VERİLERİN KORUNMASI VE BULUT GÜVENLİĞİ
Verileriniz ISO 27001 sertifikalı Supabase bulut altyapısında, modern şifreleme yöntemleriyle (AES-256 ve TLS) saklanır. Verileriniz hiçbir reklam verenle veya üçüncü tarafla ticari amaçla paylaşılmaz.

4. HAKLARINIZ VE VERİ SİLME TALEBİ
Kişisel verilerinizin silinmesini, anonimleştirilmesini veya güncellenmesini her zaman talep edebilirsiniz. Sitemizdeki "Hesabımı ve Verilerimi Sil" seçeneğini kullanabilir veya destek@mantimood.com adresine yazabilirsiniz.

5. ÇEREZLER VE TEKNİK YEREL DEPOLAMA (COOKIE POLICY)
- Sitemizde kullanıcıları siteler arası takip eden, profil çıkaran veya üçüncü taraf reklam şirketlerine (Google Ads, Meta Pixel vb.) veri aktaran HİÇBİR pazarlama veya izleme çerezi KULLANILMAMAKTADIR.
- Sitemizde yalnızca uygulamanın temel işlevlerini yerine getirebilmesi için 'Zorunlu / Teknik Depolama' (HTML5 Local Storage) kullanılmaktadır.
- Bu teknik depolama; sepetinize eklediğiniz mantı ve sosların sayfayı yenilediğinizde kaybolmaması, dükkan açık/kapalı durumu ve dükkan duyurularının tarayıcınızda hızlıca görüntülenmesi amacıyla sınırlı olarak tutulur.
- 6698 sayılı KVKK ve ilgili mevzuat uyarınca, bu tür zorunlu teknik veriler kullanıcının açık rızasına tabi olmayıp sözleşmenin ifası ve meşru menfaat hukuki sebeplerine dayanarak işlenmektedir. Tarayıcı ayarlarınızdan dilediğiniz zaman yerel depolama verilerini temizleyebilirsiniz.
''',
    );
  }

  static void showCookiePolicy(BuildContext context) {
    _showLegalModal(
      context,
      title: 'Çerez Politikası (Cookie Policy)',
      content: '''
MANTI MOOD ÇEREZ VE YEREL DEPOLAMA AYDINLATMA METNİ

Son Güncelleme: 15 Ekim 2026

Mantı Mood olarak ziyaretçilerimizin gizliliğine azami saygı gösteriyoruz. Web sitemiz ve mobil uygulamamızdaki çerez ve depolama mekanizması hakkında sizleri bilgilendirmek isteriz:

1. REKLAM VE TAKİP ÇEREZLERİ KULLANILMAZ
Sitemizde kullanıcıları siteler arası takip eden, profil çıkaran veya üçüncü taraf reklam şirketlerine veri aktaran HİÇBİR pazarlama, hedefleme veya izleme çerezi KULLANILMAMAKTADIR.

2. ZORUNLU TEKNİK YEREL DEPOLAMA (LOCAL STORAGE)
Sitemizin çalışması için teknik olarak zorunlu olan tarayıcı hafızası (HTML5 Local Storage) kullanılmaktadır:
- Sepete eklediğiniz mantı ve sosların sayfayı yenilediğinizde veya başka bölümlere geçtiğinizde kaybolmaması,
- Dükkan ayarları, çalışma saatleri ve duyuru şeridinin hızlı yüklenmesi,
- Sipariş formu doldururken akıcı ve güvenli bir deneyim sağlanması.

3. HUKUKİ SEBEP VE YÖNETİM
6698 sayılı KVKK ve Çerez Rehberi uyarınca, sitenin çalışması için zorunlu olan teknik depolama unsurları için kullanıcıdan ayrı bir onay/rıza (cookie banner) alma zorunluluğu bulunmamaktadır. 
Dilediğiniz zaman internet tarayıcınızın (Chrome, Safari, Firefox vb.) Ayarlar > Gizlilik bölümünden tarayıcı verilerini ve yerel depolamayı temizleyebilirsiniz.
''',
    );
  }

  static void showTermsOfService(BuildContext context) {
    _showLegalModal(
      context,
      title: 'Kullanım Koşulları & Mesafeli Satış',
      content: '''
MANTI MOOD KULLANIM KOŞULLARI VE ÖN BİLGİLENDİRME

1. TARAFLAR
Satıcı: Mantı Mood Ev Yapımı Mantı & Yöresel Lezzetler
Alıcı: Siteden/uygulamadan sipariş oluşturan tüketici.

2. ÜRÜN NİTELİĞİ VE SAKLAMA
Satışa sunulan mantılar taze el açması olup hijyen standartlarına uygun olarak şoklanarak (-18°C) veya taze olarak paketlenmektedir. Teslim alındıktan sonra hemen dondurucuya konulması önerilir.

3. ÖDEME VE TESLİMAT
- Havale / EFT ile yapılan ödemelerde, transfer açıklaması kısmına sipariş takip kodu yazılmalıdır.
- Kapıda veya elden teslimatta ödeme; yalnızca nakit olarak ya da teslim anında satıcının banka hesabına yapılacak anlık Havale / EFT yoluyla gerçekleştirilir.
- Siparişler, dükkandan Gel-Al (elden teslim) veya adrese teslimat aktif ise belirtilen adrese teslim yöntemiyle ulaştırılır.

4. CAYMA HAKKI İSTİSNASI
6502 sayılı Tüketicinin Korunması Hakkında Kanun uyarınca; "Çabuk bozulabilen veya son kullanma tarihi geçme ihtimali olan gıda maddeleri" niteliğindeki ürünlerde cayma hakkı bulunmamaktadır. Ancak hasarlı, bozuk veya ayıplı teslimatlarda koşulsuz telafi veya iade sağlanır.
''',
    );
  }

  static void showKvkkDialog(BuildContext context) {
    showKvkkAndDataRightsDialog(context);
  }

  static void showDataDeletionDialog(BuildContext context) {
    showKvkkAndDataRightsDialog(context);
  }

  /// KVKK Aydınlatma ve Kişisel Veri Silme Talebi Birleşik Modalı
  static void showKvkkAndDataRightsDialog(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 500;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        insetPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 24, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'KVKK & Veri Silme Hakları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '6698 SAYILI KVKK KAPSAMINDA AYDINLATMA VE VERİ SİLME BİLGİLENDİRMESİ\n',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Text(
                        'Mantı Mood olarak, 6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) uyarınca veri sorumlusu sıfatıyla; müşterilerimizin mahremiyetine ve kişisel verilerinin korunmasına azami özen gösteriyoruz.\n\n'
                        '1. İŞLENEN VERİLER VE AMAÇ\n'
                        'Sitemiz üzerinden verdiğiniz siparişlerde yalnızca sözleşmenin kurulması ve ifası (siparişin hazırlanması, bilgi fişi düzenlenmesi ve adresinize teslimi) amacıyla sınırlı olmak üzere;\n'
                        '• Ad, Soyad\n'
                        '• İletişim Numarası (Telefon)\n'
                        '• Teslimat Adresi (İl, İlçe, Açık Adres)\n'
                        'bilgileriniz otomatik yollarla işlenmektedir.\n\n'
                        '2. ÜYELİK SİSTEMİ BULUNMAMAKTADIR\n'
                        'Mantı Mood üzerinde kalıcı müşteri hesabı veya şifreli üyelik sistemi yer almamaktadır. Tüm siparişleriniz "Hızlı Misafir Siparişi" olarak gerçekleşir ve gereksiz hiçbir profil veya pazarlama verisi toplanmaz.\n\n'
                        '3. DEVAM EDEN (AKTİF) SİPARİŞLERİN KORUNMASI\n'
                        'Teslimatı henüz tamamlanmamış (hazırlık veya kurye aşamasındaki) siparişlerin adresinize sağlıklı bir şekilde ulaştırılabilmesi için zorunlu olan teslimat ve iletişim bilgileri, sipariş başarıyla teslim edilene kadar operasyonel zorunluluk gereği silinemez.\n\n'
                        '4. VERİ SİLME, YOK ETME VE ANONİMLEŞTİRME HAKKI (KVKK Md. 11)\n'
                        'Teslimatı tamamlanmış siparişlerinize ait kişisel verilerinizin sistemimizden silinmesini, maskelenmesini veya anonim hale getirilmesini dilediğiniz zaman talep edebilirsiniz. Talebiniz üzerine yasal muhasebe saklama süreleri sonrasında tüm kişisel bilgileriniz kalıcı olarak temizlenir.',
                        style: TextStyle(fontSize: 13, height: 1.55, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Aşağıdaki seçenekleri kullanarak cihazınızdaki geçici sepet verilerini hemen temizleyebilir veya tamamlanan siparişleriniz için WhatsApp üzerinden silme talebi iletebilirsiniz.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: AppColors.textSecondary),
                    label: const Text('Cihazımı Temizle', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    onPressed: () async {
                      CartController.instance.clear();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('mm_recent_order_query');
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cihazınızdaki sepet ve geçici oturum verileri başarıyla temizlendi.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: const Text('Resmi Gizlilik & KVKK Sayfası (FabMorph)', style: TextStyle(fontSize: 12)),
                    onPressed: openPrivacyPolicyOnline,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.message, size: 16, color: Colors.white),
                    label: const Text('WhatsApp ile Silme Talebi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final whatsapp = SupabaseService.instance.currentSettings?.whatsappNumber ?? '905551234567';
                      const msg = 'Merhaba Mantı Mood, KVKK haklarım kapsamında tamamlanan siparişlerime ait kişisel teslimat ve iletişim verilerimin silinmesini / anonimleştirilmesini talep ediyorum.';
                      final uri = Uri.parse('https://wa.me/$whatsapp?text=${Uri.encodeComponent(msg)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Kapat', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showLegalModal(BuildContext context, {required String title, required String content}) {
    final isNarrow = MediaQuery.of(context).size.width < 500;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        insetPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 24, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: isNarrow ? 18 : 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primaryLight),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: openPrivacyPolicyOnline,
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: const Text('Web\'de İncele', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Okudum, Kapat', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web için Çerez Tercih Kartı (Cookie Banner)
class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({super.key});

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    if (_accepted) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cookie_outlined, color: AppColors.accent, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mantı Mood deneyiminizi iyileştirmek için temel çerezler kullanıyoruz.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: LegalDialogs.openPrivacyPolicyOnline,
                      child: const Text(
                        'Detaylar',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => setState(() => _accepted = true),
                      child: const Text('Kabul Et'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.cookie_outlined, color: AppColors.accent, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Mantı Mood deneyiminizi iyileştirmek ve sepetinizi hatırlamak için temel çerezler kullanıyoruz.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: LegalDialogs.openPrivacyPolicyOnline,
                  child: const Text(
                    'Detaylar',
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => setState(() => _accepted = true),
                  child: const Text('Kabul Et'),
                ),
              ],
            ),
    );
  }
}
