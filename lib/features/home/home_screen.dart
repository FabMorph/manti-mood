import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/product.dart';
import '../../core/models/banner_item.dart';
import '../../core/models/store_settings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_presets.dart';
import '../../core/widgets/product_image.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_sheet.dart';
import '../catalog/product_detail_dialog.dart';
import '../orders/order_tracking_dialog.dart';
import '../legal/legal_dialogs.dart';
import '../admin/admin_dashboard.dart';
import '../admin/admin_login_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<BannerItem> _banners = [];
  StoreSettings? _settings;
  String _selectedCategory = 'Tümü';

  // Seçilen gramaj/varyant takibi: Map<ProductId, ProductVariant>
  final Map<String, ProductVariant> _selectedVariants = {};

  // Akıllı Vitrin Karusel Değişkenleri
  PageController? _bannerPageController;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  bool _isBannerHovered = false;

  /// Mobil mağaza derlemelerinde (Android APK/AAB ve iOS) Yönetici Paneli butonu gizlenir.
  /// Web tarayıcılarında (masaüstü ve mobil web dahil) görünür kalır.
  bool get _isMobileApp =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    final service = SupabaseService.instance;
    final initialProducts = service.currentProducts;
    final initialBanners = service.currentBanners;
    final initialSettings = service.currentSettings;

    if (initialProducts.isNotEmpty) {
      _products = initialProducts;
      _banners = initialBanners;
      _settings = initialSettings;
      _isLoading = false;
      for (var p in _products) {
        if (p.variants.isNotEmpty) {
          _selectedVariants[p.id] = p.variants.first;
        }
      }
      _initBannerCarousel();
    }

    service.settingsNotifier.addListener(_onSettingsUpdated);
    _fetchData(forceRefresh: true);
  }

  void _onSettingsUpdated() {
    if (mounted) {
      final updated = SupabaseService.instance.settingsNotifier.value;
      if (updated != null) {
        setState(() => _settings = updated);
      }
    }
  }

  @override
  void dispose() {
    SupabaseService.instance.settingsNotifier.removeListener(_onSettingsUpdated);
    _bannerTimer?.cancel();
    _bannerPageController?.dispose();
    super.dispose();
  }

  void _initBannerCarousel() {
    _bannerTimer?.cancel();
    if (_banners.length > 1) {
      _bannerPageController ??= PageController();
      _startBannerTimer();
    } else {
      _bannerPageController?.dispose();
      _bannerPageController = null;
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isBannerHovered || _banners.length <= 1) return;
      if (_bannerPageController == null || !_bannerPageController!.hasClients) return;
      final nextPage = (_currentBannerIndex + 1) % _banners.length;
      _bannerPageController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (!forceRefresh && _products.isEmpty) {
      setState(() => _isLoading = true);
    }
    final service = SupabaseService.instance;
    final results = await Future.wait([
      service.getProducts(onlyAvailable: true, forceRefresh: forceRefresh),
      service.getBanners(forceRefresh: forceRefresh),
      service.getStoreSettings(forceRefresh: forceRefresh),
    ]);

    if (!mounted) return;
    setState(() {
      _products = results[0] as List<Product>;
      _banners = results[1] as List<BannerItem>;
      _settings = results[2] as StoreSettings?;
      _currentBannerIndex = 0;

      // Varsayılan olarak her ürünün ilk varyantını seç
      for (var p in _products) {
        if (p.variants.isNotEmpty) {
          _selectedVariants[p.id] = p.variants.first;
        }
      }
      _isLoading = false;
    });

    _initBannerCarousel();
  }

  List<String> get _categories {
    final settingsCats = _settings?.categories ?? [];
    final productCats = _products.map((p) => p.category).toSet().toList();
    final allCats = <String>{...settingsCats, ...productCats}.toList();
    allCats.insert(0, 'Tümü');
    return allCats;
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Tümü') return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  Future<void> _openPrivacyPolicy() async {
    final launched = await LegalDialogs.openPrivacyPolicyOnline();
    if (!launched && mounted) {
      LegalDialogs.showPrivacyPolicy(context);
    }
  }

  Future<void> _openAskSellerWhatsApp() async {
    final rawNumber = _settings?.whatsappNumber ?? '905551234567';
    final cleanPhone = rawNumber.replaceAll(RegExp(r'\D'), '');
    final phoneWithCode = cleanPhone.startsWith('90')
        ? cleanPhone
        : (cleanPhone.startsWith('0') ? '9$cleanPhone' : '90$cleanPhone');
    final msg = Uri.encodeComponent('Merhaba, ürünleriniz ve siparişim hakkında bilgi almak istiyorum.');
    final uri = Uri.parse('https://wa.me/$phoneWithCode?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final palette = AppThemePresets.fromKey(_settings?.themePreset ?? SupabaseService.instance.currentSettings?.themePreset);

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: palette.primary,
            backgroundColor: palette.surface,
            onRefresh: () => _fetchData(forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
              slivers: [
                // 1. ÜST BAR (NAVBAR)
                SliverAppBar(
                pinned: true,
                backgroundColor: palette.surface,
                expandedHeight: isDesktop ? 88 : 78,
                collapsedHeight: isDesktop ? 76 : 68,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border(bottom: BorderSide(color: palette.cardBorder)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 10, vertical: 6),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/manti-mood-logo.png',
                            height: isDesktop ? 60 : 44,
                            width: isDesktop ? 60 : 44,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.restaurant, color: palette.primary, size: isDesktop ? 40 : 28),
                          ),
                          SizedBox(width: isDesktop ? 12 : 8),
                          // Başlık & Slogan
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Mantı Mood',
                                        style: TextStyle(
                                          color: palette.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isDesktop ? 20 : 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Builder(
                                      builder: (context) {
                                        final isStoreOpen = _settings?.isOpen ?? true;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isStoreOpen
                                                ? (palette.isDark ? const Color(0xFF14532D) : AppColors.successContainer)
                                                : (palette.isDark ? const Color(0xFF5A1A1A) : const Color(0xFFFFEBEE)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isStoreOpen ? '🟢 Açık' : '🔴 Kapalı',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isStoreOpen
                                                  ? (palette.isDark ? const Color(0xFF4ADE80) : AppColors.success)
                                                  : (palette.isDark ? const Color(0xFFF87171) : AppColors.error),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  'Ev Yapımı El Mantısı & Yöresel Lezzetler',
                                  style: TextStyle(fontSize: isDesktop ? 12 : 10.5, color: palette.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Buton: Satıcıya Sor (WhatsApp)
                          if (isDesktop && (_settings?.isAskSellerActive ?? true)) ...[
                            TextButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                              label: Text('Satıcıya Sor', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                              onPressed: _openAskSellerWhatsApp,
                            ),
                            const SizedBox(width: 4),
                          ],
                          // Buton: Sipariş Durumu
                          if (isDesktop) ...[
                            TextButton.icon(
                              icon: Icon(Icons.delivery_dining, size: 20, color: palette.primary),
                              label: Text('Sipariş Durumu', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                              onPressed: () => OrderTrackingDialog.show(context, storeSettings: _settings),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Sepet Butonu (Rozetli)
                          ListenableBuilder(
                            listenable: CartController.instance,
                            builder: (context, _) {
                              final count = CartController.instance.totalItemCount;
                              return Badge(
                                isLabelVisible: count > 0,
                                label: Text('$count'),
                                backgroundColor: palette.primary,
                                textColor: palette.isDark ? const Color(0xFF0F172A) : Colors.white,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: palette.primary,
                                    foregroundColor: palette.isDark ? const Color(0xFF0F172A) : Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 14 : 9,
                                      vertical: isDesktop ? 10 : 7,
                                    ),
                                    minimumSize: Size(isDesktop ? 88 : 64, 36),
                                  ),
                                  icon: Icon(Icons.shopping_basket_outlined, size: isDesktop ? 18 : 16),
                                  label: Text(
                                    isDesktop
                                        ? 'Sepet (${CartController.instance.totalPrice.toStringAsFixed(0)} ₺)'
                                        : '${CartController.instance.totalPrice.toStringAsFixed(0)} ₺',
                                    style: TextStyle(fontSize: isDesktop ? 13 : 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => CartSheet.show(context, storeSettings: _settings),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Mobilde Sipariş Durumu & Satıcıya Sor Kısayolu (Sağa Dayalı)
              if (!isDesktop)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: palette.surfaceMuted.withValues(alpha: 0.5),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_settings?.isAskSellerActive ?? true) ...[
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
                              label: Text('Satıcıya Sor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                              onPressed: _openAskSellerWhatsApp,
                            ),
                            const SizedBox(width: 8),
                          ],
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: Icon(Icons.delivery_dining, size: 18, color: palette.primary),
                            label: Text('Sipariş Durumu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                            onPressed: () => OrderTrackingDialog.show(context, storeSettings: _settings),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Dükkan Duyuru Şeridi
              if (_settings?.announcementText.trim().isNotEmpty == true)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: palette.primaryContainer.withValues(alpha: palette.isDark ? 0.35 : 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('📢', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duyuru',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: palette.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _settings!.announcementText.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. VİTRİN BANNERI (AKILLI HİBRİT: TEKİL SABİT VEYA ÇOKLU SLAYT)
              if (_banners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildBannerSection(isDesktop: isDesktop),
                    ),
                  ),
                ),

              // 3. ÖNE ÇIKAN DEĞERLER (TRUST BADGES - DİNAMİK YÖNETİM)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (_settings?.badges ?? const [
                        StoreBadge(icon: '🥩', title: '%100 Dana Eti', subtitle: 'Katkısız Harç'),
                        StoreBadge(icon: '🥟', title: 'Günlük Taze', subtitle: 'El Açması Hamur'),
                        StoreBadge(icon: '✨', title: 'Özel Tarif', subtitle: 'Geleneksel Lezzet'),
                      ]).map((badge) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildFeatureBadge(badge, palette),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 4. KATEGORİ FİLTRELERİ
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: palette.primary,
                          backgroundColor: palette.surface,
                          side: BorderSide(
                            color: isSelected ? palette.primary : palette.cardBorder,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (palette.isDark ? const Color(0xFF0F172A) : Colors.white)
                                : palette.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 5. ÜRÜN LİSTESİ / IZGARASI
              _isLoading
                  ? SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: palette.primary)),
                    )
                  : Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        // Webde kartları büyütüp tek satırda 3 veya 4 ürün göster (asla 5 veya 6 değil)
                        final int crossAxisCount = isDesktop
                            ? (screenWidth >= 1100 ? 4 : 3)
                            : 2;
                        final double hPadding = isDesktop ? 20.0 : 10.0;
                        final double crossSpacing = isDesktop ? 18.0 : 10.0;
                        final double mainSpacing = isDesktop ? 18.0 : 10.0;

                        final double availableGridWidth = screenWidth - (hPadding * 2);
                        final double cardWidth = (availableGridWidth - ((crossAxisCount - 1) * crossSpacing)) / crossAxisCount;

                        // Mobildeki mükemmel en/boy oranını (1.45:1) web versiyona da tam olarak uyarla
                        final double imageH = cardWidth / 1.45;
                        final double detailsH = isDesktop ? 96.0 : 76.0;
                        final double cardExtent = imageH + detailsH;

                        return SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: cardExtent,
                              crossAxisSpacing: crossSpacing,
                              mainAxisSpacing: mainSpacing,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product, palette, imageHeight: imageH);
                              },
                              childCount: _filteredProducts.length,
                            ),
                          ),
                        );
                      },
                    ),

              // 6. HİKAYEMİZ & KALİTE GÜVENCESİ (YÖNETİCİ KONTROLLÜ ALT KART)
              if (_settings?.isStoryCardActive ?? true)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: palette.cardBorder, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ProductImage(
                            imageUrl: (_settings?.storyCardImageUrl.isNotEmpty == true)
                                ? _settings!.storyCardImageUrl
                                : 'assets/images/manti-mood-logo.png',
                            height: 115,
                            width: 115,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          (_settings?.storyCardTitle.isNotEmpty == true)
                              ? _settings!.storyCardTitle
                              : 'Mantı Mood Hikayesi',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (_settings?.storyCardContent.isNotEmpty == true)
                              ? _settings!.storyCardContent
                              : 'Evimizde annelerimizin elleriyle, taptaze un ve %100 yerli dana kıymayla '
                                'tek tek büktüğümüz geleneksel lezzeti sofranıza getiriyoruz. '
                                'Hiçbir koruyucu veya katkı maddesi kullanmadan, şok dondurarak tazeliğini '
                                'ilk günkü gibi muhafaza ediyoruz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.textSecondary, height: 1.6, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

              // 7. FOOTER (YASAL LİNKLER & İLETİŞİM)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  color: palette.surfaceMuted,
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: _openPrivacyPolicy,
                            child: Text('Gizlilik Politikası & KVKK Aydınlatma Metni', style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () => LegalDialogs.showTermsOfService(context),
                            child: Text('Kullanım Koşulları', style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () => LegalDialogs.showKvkkAndDataRightsDialog(context),
                            child: Text('KVKK & Veri Silme Talebi', style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            '© 2026 Mantı Mood — Tüm Hakları Saklıdır. El Yapımı Butik Mantı.',
                            style: TextStyle(fontSize: 11, color: palette.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          if (!_isMobileApp)
                            InkWell(
                              onTap: () async {
                              final service = SupabaseService.instance;
                              if (service.isCurrentAdminAuthorized) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminDashboard(storeSettings: _settings)),
                                );
                                if (mounted) _fetchData();
                              } else {
                                final loggedIn = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (_) => const AdminLoginDialog(),
                                );
                                if (!context.mounted) return;
                                if (loggedIn == true && service.isCurrentAdminAuthorized) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AdminDashboard(storeSettings: _settings)),
                                  );
                                  if (mounted) _fetchData();
                                }
                              }
                            },
                            child: Text(
                              'Yönetici Paneli',
                              style: TextStyle(fontSize: 11, color: palette.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(StoreBadge badge, AppColorPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.icon.isEmpty ? '🥟' : badge.icon,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge.title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: palette.textPrimary),
              ),
              if (badge.subtitle.isNotEmpty)
                Text(
                  badge.subtitle,
                  style: TextStyle(fontSize: 10, color: palette.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, AppColorPalette palette, {double? imageHeight}) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final effectiveImageHeight = imageHeight ?? (isDesktop ? 195.0 : 120.0);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: isDesktop ? 2 : 1,
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
        side: BorderSide(color: palette.cardBorder, width: 1.2),
      ),
      child: InkWell(
        onTap: () => ProductDetailDialog.show(
          context,
          product: product,
          storeSettings: _settings,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ürün Fotoğrafı
            Stack(
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  height: effectiveImageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Kategori Rozeti
                Positioned(
                  top: isDesktop ? 10 : 6,
                  left: isDesktop ? 10 : 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 6,
                      vertical: isDesktop ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 11 : 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Çoklu Medya Sayacı (Eğer 1'den fazla görsel/video varsa)
                if (product.allMedia.length > 1)
                  Positioned(
                    top: isDesktop ? 10 : 6,
                    right: isDesktop ? 10 : 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 7 : 5,
                        vertical: isDesktop ? 3 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.collections, color: Colors.white, size: isDesktop ? 12 : 10),
                          const SizedBox(width: 3),
                          Text(
                            '${product.allMedia.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 11 : 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // İçerik
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 12 : 10,
                isDesktop ? 10 : 8,
                isDesktop ? 12 : 10,
                isDesktop ? 10 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 14.5 : 13,
                      height: 1.2,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isDesktop ? 8 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${product.basePrice.toStringAsFixed(0)} ₺',
                          style: TextStyle(
                            fontSize: isDesktop ? 17 : 15,
                            fontWeight: FontWeight.bold,
                            color: palette.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isDesktop)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: palette.isDark ? const Color(0xFF0F172A) : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 15),
                          label: const Text('İncele'),
                          onPressed: () => ProductDetailDialog.show(
                            context,
                            product: product,
                            storeSettings: _settings,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined, size: 12, color: palette.primary),
                              const SizedBox(width: 3),
                              Text(
                                'İncele',
                                style: TextStyle(
                                  color: palette.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection({required bool isDesktop}) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    // 1. TEKİL SABİT BANNER (Sadece 1 afiş aktifse sabit vitrin olarak kalır)
    if (_banners.length == 1) {
      return Container(
        margin: EdgeInsets.all(isDesktop ? 16 : 12),
        height: isDesktop ? 290 : 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 18),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildBannerItemContent(_banners.first, isDesktop: isDesktop),
      );
    }

    // 2. OTOMATİK DÖNEN SLAYT / KARUSEL (2 veya daha fazla aktif afiş varsa)
    _bannerPageController ??= PageController(initialPage: _currentBannerIndex);
    return MouseRegion(
      onEnter: (_) => setState(() => _isBannerHovered = true),
      onExit: (_) => setState(() => _isBannerHovered = false),
      child: Container(
        margin: EdgeInsets.all(isDesktop ? 16 : 12),
        height: isDesktop ? 290 : 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 18),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PageView.builder(
              controller: _bannerPageController,
              itemCount: _banners.length,
              onPageChanged: (idx) {
                setState(() => _currentBannerIndex = idx);
              },
              itemBuilder: (context, index) {
                return _buildBannerItemContent(_banners[index], isDesktop: isDesktop);
              },
            ),

            // Sayfa Gösterge Noktaları (Dots)
            Positioned(
              bottom: isDesktop ? 16 : 12,
              right: isDesktop ? 20 : 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_banners.length, (i) {
                    final isSelected = i == _currentBannerIndex;
                    return GestureDetector(
                      onTap: () {
                        _bannerPageController?.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isSelected ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Desktop fare geçiş okları (Hover edildiğinde görünür)
            if (isDesktop && _isBannerHovered) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onPressed: () {
                      final prevPage = (_currentBannerIndex - 1 + _banners.length) % _banners.length;
                      _bannerPageController?.animateToPage(
                        prevPage,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      final nextPage = (_currentBannerIndex + 1) % _banners.length;
                      _bannerPageController?.animateToPage(
                        nextPage,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBannerItemContent(BannerItem banner, {required bool isDesktop}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ProductImage(
          imageUrl: banner.getEffectiveImageUrl(isMobile: !isDesktop),
          fit: BoxFit.cover,
        ),
        // Karartma gradyanı
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        // Metinler
        Positioned(
          left: isDesktop ? 24 : 14,
          bottom: isDesktop ? 24 : 14,
          right: isDesktop ? 120 : 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                banner.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 26 : 18,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                banner.subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isDesktop ? 14 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
