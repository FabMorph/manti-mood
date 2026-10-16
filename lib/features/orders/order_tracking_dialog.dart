import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/order.dart';
import '../../core/models/store_settings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';

class OrderTrackingDialog extends StatefulWidget {
  final StoreSettings? storeSettings;
  final String? initialOrderNumber;
  final DateTime Function()? nowProvider;

  const OrderTrackingDialog({
    super.key,
    this.storeSettings,
    this.initialOrderNumber,
    this.nowProvider,
  });

  static void show(BuildContext context, {StoreSettings? storeSettings, String? initialOrderNumber}) {
    showDialog(
      context: context,
      builder: (context) => OrderTrackingDialog(
        storeSettings: storeSettings,
        initialOrderNumber: initialOrderNumber,
      ),
    );
  }

  @override
  State<OrderTrackingDialog> createState() => _OrderTrackingDialogState();
}

class _OrderTrackingDialogState extends State<OrderTrackingDialog> {
  final _orderNumberController = TextEditingController();
  bool _isLoading = false;
  OrderModel? _order;
  String? _errorMessage;
  DateTime? _lastSearchTime;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  DateTime get _now => (widget.nowProvider ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderNumber != null && widget.initialOrderNumber!.isNotEmpty) {
      _orderNumberController.text = widget.initialOrderNumber!;
      _searchOrder();
    }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    super.dispose();
  }

  Future<void> _searchOrder() async {
    final now = _now;
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(now).inSeconds + 1;
      setState(() {
        _errorMessage = 'Çok fazla hatalı deneme yapıldı. Lütfen $remaining saniye bekleyiniz.';
      });
      return;
    }

    if (_lastSearchTime != null && now.difference(_lastSearchTime!).inMilliseconds < 1200) {
      return; // Çift tıklama ve hızlı basma engeli (debounce)
    }
    _lastSearchTime = now;

    final query = _orderNumberController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final order = await SupabaseService.instance.getOrderByNumber(query);

    setState(() {
      _isLoading = false;
      if (order != null) {
        _order = order;
        _failedAttempts = 0;
      } else {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _lockoutUntil = _now.add(const Duration(seconds: 15));
          _errorMessage = 'Çok fazla hatalı sipariş numarası denendi. Lütfen 15 saniye bekleyiniz.';
        } else {
          _errorMessage = 'Sipariş bulunamadı. Lütfen sipariş numaranızı kontrol ediniz (Örn: 26715996).';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 500;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: EdgeInsets.all(isNarrow ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delivery_dining, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sipariş Takibi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 12),

            // Arama Alanı
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _orderNumberController,
                    decoration: const InputDecoration(
                      hintText: 'Sipariş No Giriniz (Örn: 26715996)',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchOrder(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchOrder,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sorgula'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sonuç Alanı
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),

            if (_order != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sipariş Özeti Kartı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _order!.orderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                      tooltip: 'Sipariş Numarasını Kopyala',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: _order!.orderNumber));
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.white, size: 18),
                                                SizedBox(width: 8),
                                                Text('Sipariş no kopyalandı!'),
                                              ],
                                            ),
                                            duration: Duration(seconds: 2),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_order!.status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _order!.statusTitle,
                                    style: TextStyle(
                                      color: _getStatusColor(_order!.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Müşteri (Maskeli)
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Müşteri: ${_order!.customerName}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // İletişim (Maskeli)
                            if (_order!.customerPhone.isNotEmpty && _order!.customerPhone != '***') ...[
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'İletişim: ${_order!.customerPhone}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                            ],
                            // Teslimat Bölgesi (Maskeli / Güvenli)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Teslimat: ${_order!.deliveryAddress}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Toplam: ${_order!.totalAmount.toStringAsFixed(0)} ₺ (${_order!.paymentMethod == "bank_transfer" ? "Havale/EFT" : "Kapıda Ödeme"})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // KVKK & Güvenlik Bilgilendirmesi Rozeti
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'KVKK Koruması: Kişisel veriler ve açık adres 3. şahıslara karşı maskelenmiştir.',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Canlı Adım Takip Çubuğu
                      const Text(
                        'Canlı Sipariş Aşamaları',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusTimeline(_order!),
                      const SizedBox(height: 20),

                      // Ürünler
                      const Text(
                        'Sipariş Edilen Mantılar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ..._order!.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName} (${item.variantTitle})',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.subtotal.toStringAsFixed(0)} ₺',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),

                      // WhatsApp ile Destek
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                          label: const Text('Bu Sipariş İçin Yöneticiye Soru Sor (WhatsApp)'),
                          onPressed: () async {
                            final whatsapp = widget.storeSettings?.whatsappNumber ?? '905551234567';
                            final msg = Uri.encodeComponent(
                              'Merhaba Mantı Mood! ${_order!.orderNumber} numaralı siparişim hakkında bilgi alabilir miyim?',
                            );
                            final uri = Uri.parse('https://wa.me/$whatsapp?text=$msg');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage == null && !_isLoading)
              const Expanded(
                child: Center(
                  child: Text(
                    'Siparişinizin durumunu canlı takip etmek için\nyukarıya sipariş kodunuzu yazınız.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'order_received':
        return AppColors.primary;
      case 'pending_payment':
        return AppColors.warning;
      case 'payment_received':
        return AppColors.success;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.teal;
      case 'shipped':
      case 'on_the_way':
        return AppColors.accentDark;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildStatusTimeline(OrderModel order) {
    if (order.status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş İptal Edildi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bu sipariş iptal edilmiştir. Detaylı bilgi için WhatsApp destek hattımızdan bize ulaşabilirsiniz.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final masterSteps = [
      {
        'key': 'order_received',
        'title': 'Sipariş Alındı',
        'subtitle': 'Siparişiniz başarıyla sistemimize ulaştı.',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.primary,
      },
      {
        'key': 'pending_payment',
        'title': 'Ödeme Bekleniyor',
        'subtitle': 'Banka havalesi / EFT dekontu bekleniyor.',
        'icon': Icons.hourglass_top_rounded,
        'color': AppColors.warning,
      },
      {
        'key': 'payment_received',
        'title': 'Ödeme Alındı',
        'subtitle': 'Ödemeniz onaylandı ve muhasebeleştirildi.',
        'icon': Icons.paid_rounded,
        'color': AppColors.success,
      },
      {
        'key': 'preparing',
        'title': 'Hazırlanıyor',
        'subtitle': 'Mantılarınız anne eliyle özenle hazırlanıyor.',
        'icon': Icons.soup_kitchen_rounded,
        'color': Colors.orange,
      },
      {
        'key': 'ready',
        'title': 'Hazırlandı',
        'subtitle': 'Siparişiniz paketlendi, sevk için hazırlandı.',
        'icon': Icons.inventory_2_rounded,
        'color': Colors.teal,
      },
      {
        'key': 'shipped',
        'title': 'Kargoda',
        'subtitle': 'Siparişiniz kargoya verildi ve adrese doğru yolda.',
        'icon': Icons.local_shipping_rounded,
        'color': AppColors.accentDark,
      },
      {
        'key': 'delivered',
        'title': 'Teslim Edildi',
        'subtitle': 'Siparişiniz teslim edildi. Afiyet olsun!',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.success,
      },
    ];

    // Sadece admin tarafından işaretlenmiş olan adımları filtrele!
    final activeSteps = masterSteps.where((step) {
      final key = step['key'] as String;
      if (key == 'shipped') {
        return order.statusSteps.contains('shipped') || order.statusSteps.contains('on_the_way');
      }
      return order.statusSteps.contains(key);
    }).toList();

    if (activeSteps.isEmpty) {
      activeSteps.add(masterSteps.first);
    }

    // En son işaretlenen aşama aktif (current) aşamadır
    final currentActiveIndex = activeSteps.length - 1;

    return Column(
      children: List.generate(activeSteps.length, (index) {
        final step = activeSteps[index];
        final isLast = index == activeSteps.length - 1;
        final isDelivered = order.status == 'delivered';
        final isStepCompleted = index < currentActiveIndex || isDelivered;
        final isCurrent = index == currentActiveIndex && !isDelivered;
        final stepColor = step['color'] as Color;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isStepCompleted
                        ? AppColors.success
                        : (isCurrent ? stepColor : AppColors.cardBorder),
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: stepColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isStepCompleted ? Icons.check_rounded : (step['icon'] as IconData),
                    size: 18,
                    color: (isStepCompleted || isCurrent) ? Colors.white : AppColors.textMuted,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.5,
                    height: 32,
                    color: isStepCompleted ? AppColors.success : AppColors.cardBorder,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontWeight: (isCurrent || isStepCompleted) ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent
                                ? stepColor
                                : (isStepCompleted ? AppColors.textPrimary : AppColors.textMuted),
                            fontSize: 14,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: stepColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Güncel Aşama',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stepColor),
                            ),
                          ),
                        ],
                        if (isStepCompleted) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
