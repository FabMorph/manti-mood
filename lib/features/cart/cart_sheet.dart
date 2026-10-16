import 'package:flutter/material.dart';
import '../../core/models/store_settings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_presets.dart';
import '../../core/widgets/product_image.dart';
import '../checkout/checkout_dialog.dart';
import 'cart_controller.dart';

class CartSheet extends StatelessWidget {
  final StoreSettings? storeSettings;

  const CartSheet({super.key, this.storeSettings});

  static void show(BuildContext context, {StoreSettings? storeSettings}) {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (_) {}
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartSheet(storeSettings: storeSettings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartController.instance,
      builder: (context, _) {
        final cart = CartController.instance;
        final settings = storeSettings ?? SupabaseService.instance.currentSettings;
        final palette = AppThemePresets.fromKey(settings?.themePreset);
        final minOrder = settings?.minOrderAmount ?? 200.0;
        final isMinOrderReached = cart.totalPrice >= minOrder;
        final isStoreOpen = settings?.isOpen ?? true;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: palette.cardBorder, width: 1.2),
              left: BorderSide(color: palette.cardBorder, width: 1.2),
              right: BorderSide(color: palette.cardBorder, width: 1.2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Çizgi & Başlık
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: palette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.shopping_basket_outlined, color: palette.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sepetim (${cart.totalItemCount} Ürün)',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: palette.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!cart.isEmpty)
                    TextButton(
                      onPressed: () {
                        try {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        } catch (_) {}
                        cart.clear();
                      },
                      child: const Text('Temizle', style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
              Divider(color: palette.cardBorder),
              const SizedBox(height: 8),

              // Sepet Listesi
              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_shopping_cart_outlined, size: 64, color: palette.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'Sepetinizde henüz mantı bulunmuyor.',
                              style: TextStyle(fontSize: 16, color: palette.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Taze açılmış lezzetli mantılarımızdan ekleyebilirsiniz!',
                              style: TextStyle(fontSize: 13, color: palette.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: cart.items.length,
                        separatorBuilder: (_, _) => Divider(color: palette.cardBorder, height: 16),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ProductImage(
                                  imageUrl: item.product.imageUrl,
                                  width: 55,
                                  height: 55,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: palette.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.variant.title,
                                      style: TextStyle(fontSize: 12, color: palette.primary, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${item.subtotal.toStringAsFixed(0)} ₺',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: palette.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              // Adet Butonları
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                    icon: Icon(Icons.remove_circle_outline, size: 20, color: palette.textSecondary),
                                    onPressed: () => cart.decrement(item),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: palette.textPrimary),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                    icon: Icon(Icons.add_circle_outline, size: 20, color: palette.primary),
                                    onPressed: () => cart.increment(item),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Dip Toplam ve Buton
              if (!cart.isEmpty) ...[
                Divider(color: palette.cardBorder),
                if (!isStoreOpen) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dükkanımız şu anda sipariş alımına kapalıdır.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sepet Tutarı',
                            style: TextStyle(fontSize: 11, color: palette.textSecondary),
                          ),
                          Text(
                            '${cart.totalPrice.toStringAsFixed(0)} ₺',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: palette.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: (isStoreOpen && isMinOrderReached)
                          ? () {
                              Navigator.pop(context);
                              CheckoutDialog.show(context, storeSettings: settings);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.isDark ? const Color(0xFF0F172A) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        !isStoreOpen
                            ? 'Dükkan Şu An Kapalı'
                            : (isMinOrderReached
                                ? 'Siparişe Geç ➔'
                                : 'Min. ${minOrder.toStringAsFixed(0)} ₺ Gerekli'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
