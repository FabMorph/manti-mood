import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/product.dart';
import '../../core/models/store_settings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_presets.dart';
import '../../core/widgets/product_image.dart';
import '../../main.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_sheet.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;
  final StoreSettings? storeSettings;

  const ProductDetailDialog({
    super.key,
    required this.product,
    this.storeSettings,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    StoreSettings? storeSettings,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProductDetailDialog(
        product: product,
        storeSettings: storeSettings,
      ),
    );
  }

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  late PageController _pageController;
  int _currentMediaIndex = 0;
  late ProductVariant _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedVariant = widget.product.variants.isNotEmpty
        ? widget.product.variants.first
        : ProductVariant(title: 'Standart', price: widget.product.basePrice);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _mediaList {
    final list = widget.product.allMedia;
    if (list.isEmpty) {
      return ['assets/images/manti-cesitleri/bohca.png'];
    }
    return list;
  }

  void _showFullscreenMedia(BuildContext context, String mediaUrl, bool isVideo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Center(
                child: ProductImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (isVideo)
              Center(
                child: FloatingActionButton.large(
                  backgroundColor: AppColors.primary,
                  onPressed: () async {
                    if (mediaUrl.startsWith('http')) {
                      final uri = Uri.parse(mediaUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: const Icon(Icons.play_arrow, size: 48, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final palette = AppThemePresets.fromKey(widget.storeSettings?.themePreset ?? SupabaseService.instance.currentSettings?.themePreset);
    final mediaList = _mediaList;
    final currentPrice = _selectedVariant.price;
    final totalPrice = currentPrice * _quantity;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: palette.cardBorder, width: 1.2),
      ),
      backgroundColor: palette.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 10, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 680 : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: palette.surface,
        ),
        child: Column(
          children: [
            // Üst Kapat Butonu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.product.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: palette.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: palette.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // İçerik (Kaydırılabilir)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. MEDYA CAROUSEL (FOTOĞRAF & VİDEO - ANA SAYFAYLA BİREBİR 1.45:1 ORANI)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.45,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: mediaList.length,
                            onPageChanged: (index) {
                              setState(() => _currentMediaIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final mediaUrl = mediaList[index];
                              final isVideo = Product.isMediaVideo(mediaUrl);

                              return GestureDetector(
                                onTap: () => _showFullscreenMedia(context, mediaUrl, isVideo),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ProductImage(
                                      imageUrl: mediaUrl,
                                      fit: BoxFit.cover,
                                    ),
                                    if (isVideo)
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                            size: 44,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Önceki Butonu (<)
                        if (mediaList.length > 1)
                          Positioned(
                            left: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              radius: 18,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                          ),

                        // Sonraki Butonu (>)
                        if (mediaList.length > 1)
                          Positioned(
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              radius: 18,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                          ),

                        // Sayaç Rozeti (Örn: 1 / 3)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Product.isMediaVideo(mediaList[_currentMediaIndex])
                                      ? Icons.videocam
                                      : Icons.photo_camera,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_currentMediaIndex + 1} / ${mediaList.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Büyütme İpucu
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.fullscreen, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Büyütmek için dokunun',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 2. ÜRÜN BİLGİLERİ
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.product.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.product.isAvailable
                                      ? (palette.isDark ? const Color(0xFF14532D) : AppColors.successContainer)
                                      : (palette.isDark ? const Color(0xFF450A0A) : AppColors.primaryContainer),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.product.isAvailable ? 'Günlük Taze' : 'Tükendi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.product.isAvailable
                                        ? (palette.isDark ? const Color(0xFF4ADE80) : AppColors.success)
                                        : (palette.isDark ? const Color(0xFFF87171) : AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. PAKET / PORSİYON SEÇENEKLERİ
                          Text(
                            'Porsiyon / Paket Seçiniz:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: palette.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: widget.product.variants.map((v) {
                              final isSelected = _selectedVariant.title == v.title;
                              return ChoiceChip(
                                label: Text('${v.title} (${v.price.toStringAsFixed(0)} ₺)'),
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
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedVariant = v);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 4. NASIL PİŞİRİLİR & SAKLAMA REHBERİ
                          if (widget.product.cookingInstructions.isNotEmpty ||
                              widget.product.storageInstructions.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: palette.surfaceMuted,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: palette.cardBorder, width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.product.cookingInstructions.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.soup_kitchen_outlined, color: palette.primary, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Nasıl Pişirilir? (Sos & Pişirme Rehberi)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: palette.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.product.cookingInstructions,
                                      style: TextStyle(fontSize: 12, height: 1.4, color: palette.textSecondary),
                                    ),
                                  ],
                                  if (widget.product.cookingInstructions.isNotEmpty &&
                                      widget.product.storageInstructions.isNotEmpty)
                                    Divider(height: 16, color: palette.cardBorder),
                                  if (widget.product.storageInstructions.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.ac_unit_outlined, color: palette.accent, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Saklama Koşulları',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: palette.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.product.storageInstructions,
                                      style: TextStyle(fontSize: 12, height: 1.4, color: palette.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. ALT SABİT SEPETE EKLEME ALANI
            Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.cardBorder)),
              ),
              child: Row(
                children: [
                  // Adet Seçici
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(Icons.remove, size: 16, color: palette.textPrimary),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text(
                          '$_quantity',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 16 : 14, color: palette.textPrimary),
                        ),
                        IconButton(
                          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(Icons.add, size: 16, color: palette.primary),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 8),

                  // Toplam Tutar & Ekle Butonu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Toplam Tutar', style: TextStyle(fontSize: 10, color: palette.textSecondary)),
                        Text(
                          '${totalPrice.toStringAsFixed(0)} ₺',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            color: palette.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 22 : 12, vertical: 12),
                      textStyle: TextStyle(fontSize: isDesktop ? 14 : 12, fontWeight: FontWeight.bold),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(Icons.shopping_bag_outlined, size: isDesktop ? 20 : 17),
                    label: const Text('Sepete Ekle'),
                    onPressed: widget.product.isAvailable
                        ? () {
                            CartController.instance.addItem(
                              widget.product,
                              _selectedVariant,
                              quantity: _quantity,
                            );
                            Navigator.pop(context);
                            final navContext = appNavigatorKey.currentContext;
                            if (navContext != null) {
                              final messenger = ScaffoldMessenger.of(navContext);
                              messenger.hideCurrentSnackBar();
                              final controller = messenger.showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  content: Text(
                                    '$_quantity x ${widget.product.name} (${_selectedVariant.title}) sepete eklendi!',
                                  ),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(milliseconds: 2500),
                                  action: SnackBarAction(
                                    label: 'Sepeti Gör',
                                    textColor: AppColors.accent,
                                    onPressed: () {
                                      messenger.hideCurrentSnackBar();
                                      final activeContext = appNavigatorKey.currentContext;
                                      if (activeContext != null) {
                                        CartSheet.show(activeContext, storeSettings: widget.storeSettings);
                                      }
                                    },
                                  ),
                                ),
                              );
                              // Web'de mouse imleci ekranda dursa bile bildirimi 2.5 sn sonra kesin olarak kapat
                              Future.delayed(const Duration(milliseconds: 2600), () {
                                try {
                                  controller.close();
                                } catch (_) {}
                              });
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
