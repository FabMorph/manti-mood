import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/order.dart';
import '../../core/models/product.dart';
import '../../core/models/banner_item.dart';
import '../../core/models/store_settings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_presets.dart';
import '../../core/widgets/product_image.dart';
import '../../core/services/media_upload_service.dart';
import '../../core/widgets/image_cropper_dialog.dart';
import '../../core/utils/file_download_helper.dart';

class AdminDashboard extends StatefulWidget {
  final StoreSettings? storeSettings;

  const AdminDashboard({super.key, this.storeSettings});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<OrderModel> _orders = [];
  List<Product> _products = [];
  List<BannerItem> _banners = [];
  StoreSettings? _settings;

  String _orderFilter = 'all';
  String _productCategoryFilter = 'all';

  TextEditingController? _phoneController;
  TextEditingController? _minOrderController;
  TextEditingController? _announcementController;
  TextEditingController? _pickupTitleCtrl;
  TextEditingController? _pickupDescCtrl;
  TextEditingController? _deliveryTitleCtrl;
  TextEditingController? _deliveryDescCtrl;
  TextEditingController? _storyTitleCtrl;
  TextEditingController? _storyContentCtrl;
  TextEditingController? _storyImageCtrl;

  void _initSettingsControllers(StoreSettings s, {bool force = false}) {
    if (force) {
      _phoneController?.dispose();
      _minOrderController?.dispose();
      _announcementController?.dispose();
      _pickupTitleCtrl?.dispose();
      _pickupDescCtrl?.dispose();
      _deliveryTitleCtrl?.dispose();
      _deliveryDescCtrl?.dispose();
      _storyTitleCtrl?.dispose();
      _storyContentCtrl?.dispose();
      _storyImageCtrl?.dispose();
      _phoneController = null;
      _minOrderController = null;
      _announcementController = null;
      _pickupTitleCtrl = null;
      _pickupDescCtrl = null;
      _deliveryTitleCtrl = null;
      _deliveryDescCtrl = null;
      _storyTitleCtrl = null;
      _storyContentCtrl = null;
      _storyImageCtrl = null;
    }

    if (_phoneController == null) {
      _phoneController = TextEditingController(text: s.whatsappNumber);
    } else if (force || s.whatsappNumber != _phoneController!.text) {
      _phoneController!.text = s.whatsappNumber;
    }

    if (_minOrderController == null) {
      _minOrderController = TextEditingController(text: s.minOrderAmount.toStringAsFixed(0));
    } else if (force || s.minOrderAmount.toStringAsFixed(0) != _minOrderController!.text) {
      _minOrderController!.text = s.minOrderAmount.toStringAsFixed(0);
    }

    if (_announcementController == null) {
      _announcementController = TextEditingController(text: s.announcementText);
    } else if (force || s.announcementText != _announcementController!.text) {
      _announcementController!.text = s.announcementText;
    }

    if (_pickupTitleCtrl == null) {
      _pickupTitleCtrl = TextEditingController(text: s.pickupTitle);
    } else if (force || s.pickupTitle != _pickupTitleCtrl!.text) {
      _pickupTitleCtrl!.text = s.pickupTitle;
    }

    if (_pickupDescCtrl == null) {
      _pickupDescCtrl = TextEditingController(text: s.pickupDescription);
    } else if (force || s.pickupDescription != _pickupDescCtrl!.text) {
      _pickupDescCtrl!.text = s.pickupDescription;
    }

    if (_deliveryTitleCtrl == null) {
      _deliveryTitleCtrl = TextEditingController(text: s.deliveryTitle);
    } else if (force || s.deliveryTitle != _deliveryTitleCtrl!.text) {
      _deliveryTitleCtrl!.text = s.deliveryTitle;
    }

    if (_deliveryDescCtrl == null) {
      _deliveryDescCtrl = TextEditingController(text: s.deliveryDescription);
    } else if (force || s.deliveryDescription != _deliveryDescCtrl!.text) {
      _deliveryDescCtrl!.text = s.deliveryDescription;
    }

    if (_storyTitleCtrl == null) {
      _storyTitleCtrl = TextEditingController(text: s.storyCardTitle);
    } else if (force || s.storyCardTitle != _storyTitleCtrl!.text) {
      _storyTitleCtrl!.text = s.storyCardTitle;
    }

    if (_storyContentCtrl == null) {
      _storyContentCtrl = TextEditingController(text: s.storyCardContent);
    } else if (force || s.storyCardContent != _storyContentCtrl!.text) {
      _storyContentCtrl!.text = s.storyCardContent;
    }

    if (_storyImageCtrl == null) {
      _storyImageCtrl = TextEditingController(text: s.storyCardImageUrl);
    } else if (force || s.storyCardImageUrl != _storyImageCtrl!.text) {
      _storyImageCtrl!.text = s.storyCardImageUrl;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController?.dispose();
    _minOrderController?.dispose();
    _announcementController?.dispose();
    _pickupTitleCtrl?.dispose();
    _pickupDescCtrl?.dispose();
    _deliveryTitleCtrl?.dispose();
    _deliveryDescCtrl?.dispose();
    _storyTitleCtrl?.dispose();
    _storyContentCtrl?.dispose();
    _storyImageCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final service = SupabaseService.instance;
    final results = await Future.wait([
      service.getAllOrders(),
      service.getProducts(onlyAvailable: false),
      service.getBanners(onlyActive: false),
      service.getStoreSettings(),
    ]);

    setState(() {
      _orders = results[0] as List<OrderModel>;
      _products = results[1] as List<Product>;
      _banners = results[2] as List<BannerItem>;
      _settings = results[3] as StoreSettings?;
      if (_settings != null) {
        _initSettingsControllers(_settings!);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Yönetici Paneli',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (SupabaseService.instance.activeAdminEmail != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle, size: 16, color: AppColors.primary),
                    if (MediaQuery.of(context).size.width >= 650) ...[
                      const SizedBox(width: 6),
                      Text(
                        SupabaseService.instance.activeAdminEmail!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
          IconButton(
            tooltip: 'Yenile',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Yönetici oturumunu kapatmak istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await SupabaseService.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yönetici oturumu kapatıldı.')),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: MediaQuery.of(context).size.width < 600,
          tabAlignment: MediaQuery.of(context).size.width < 600 ? TabAlignment.start : TabAlignment.fill,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_outlined), text: 'Mutfak & Sipariş'),
            Tab(icon: Icon(Icons.lunch_dining_outlined), text: 'Ürün Yönetimi'),
            Tab(icon: Icon(Icons.view_carousel_outlined), text: 'Vitrin Banner'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Dükkan Ayarları'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildProductsTab(),
                _buildBannersTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  // ==========================================
  // 1. SİPARİŞLER (MUTFAK EKRANI)
  // ==========================================
  Widget _buildOrdersTab() {
    final filtered = _orders.where((o) {
      if (_orderFilter == 'all') return true;
      if (_orderFilter == 'shipped' || _orderFilter == 'on_the_way') {
        return o.status == 'shipped' || o.status == 'on_the_way';
      }
      return o.status == _orderFilter;
    }).toList();

    return Column(
      children: [
        // Üst Eylem ve Excel Dışa Aktarma Çubuğu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _orderFilter == 'all'
                      ? 'Tüm Siparişler (${_orders.length})'
                      : 'Filtrelenen Siparişler (${filtered.length}/${_orders.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7E34), // Excel Yeşili
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.table_view_rounded, size: 16),
                label: const Text(
                  'Excel / CSV İndir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: _orders.isEmpty ? null : () => _exportOrdersToExcel(filtered),
              ),
            ],
          ),
        ),

        // Filtre Çipleri
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip('Tümü (${_orders.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Ödeme Bekleyen', 'pending_payment'),
              const SizedBox(width: 8),
              _buildFilterChip('Ödeme Alındı', 'payment_received'),
              const SizedBox(width: 8),
              _buildFilterChip('Hazırlanıyor', 'preparing'),
              const SizedBox(width: 8),
              _buildFilterChip('Hazırlandı', 'ready'),
              const SizedBox(width: 8),
              _buildFilterChip('Kargoda', 'shipped'),
              const SizedBox(width: 8),
              _buildFilterChip('Teslim Edildi', 'delivered'),
              const SizedBox(width: 8),
              _buildFilterChip('İptal Edilenler', 'cancelled'),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('Bu aşamada sipariş bulunmuyor.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _orderFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _orderFilter = value),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Sipariş Numarasını Kopyala',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.orderNumber));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${order.orderNumber} panoya kopyalandı!'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusTitle,
                    style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👤 ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('📞 ${order.customerPhone}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('📍 ${order.deliveryDistrict}, ${order.deliveryAddress}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'WhatsApp\'tan Yaz',
                  icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  onPressed: () async {
                    final cleanPhone = order.customerPhone.replaceAll(RegExp(r'\D'), '');
                    final phoneWithCode = cleanPhone.startsWith('0') ? '9$cleanPhone' : '90$cleanPhone';
                    final msg = Uri.encodeComponent('Merhaba ${order.customerName}, Mantı Mood siparişiniz hakkında...');
                    final uri = Uri.parse('https://wa.me/$phoneWithCode?text=$msg');
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
                IconButton(
                  tooltip: 'Telefonla Ara',
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  onPressed: () async {
                    final uri = Uri.parse('tel:${order.customerPhone}');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ],
            ),
            const Divider(color: AppColors.cardBorder, height: 16),
            ...order.items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '🥟 ${i.quantity}x ${i.productName} (${i.variantTitle}) — ${i.subtotal.toStringAsFixed(0)} ₺',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            )),
            if (order.customerNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('📝 Not: ${order.customerNote}', style: const TextStyle(fontSize: 12)),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Ödeme: ${order.paymentMethodLabel}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  'Toplam: ${order.totalAmount.toStringAsFixed(0)} ₺',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Sipariş Aşamaları (İşaretle / Kaldır):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildFixedStageChip('Sipariş Alındı', Icons.receipt_long_rounded),
                _buildStageToggleBtn(
                  order: order,
                  label: 'Ödeme Bekleniyor',
                  stepKey: 'pending_payment',
                  color: AppColors.warning,
                  icon: Icons.hourglass_top_rounded,
                ),
                _buildStageToggleBtn(
                  order: order,
                  label: 'Ödeme Alındı',
                  stepKey: 'payment_received',
                  color: AppColors.success,
                  icon: Icons.paid_rounded,
                ),
                _buildStageToggleBtn(
                  order: order,
                  label: 'Hazırlanıyor',
                  stepKey: 'preparing',
                  color: Colors.orange,
                  icon: Icons.soup_kitchen_rounded,
                ),
                _buildStageToggleBtn(
                  order: order,
                  label: 'Hazırlandı',
                  stepKey: 'ready',
                  color: Colors.teal,
                  icon: Icons.inventory_2_rounded,
                ),
                _buildStageToggleBtn(
                  order: order,
                  label: 'Kargoda',
                  stepKey: 'shipped',
                  color: AppColors.accentDark,
                  icon: Icons.local_shipping_rounded,
                ),
                _buildStageToggleBtn(
                  order: order,
                  label: 'Teslim Edildi',
                  stepKey: 'delivered',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
                if (_getLatestToggleableStep(order) != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.undo_rounded, size: 14),
                    label: const Text('Geri Al'),
                    onPressed: () async {
                      final stepToUndo = _getLatestToggleableStep(order);
                      if (stepToUndo == null) return;
                      final updated = await SupabaseService.instance.toggleOrderStep(order.id, stepToUndo);
                      if (updated != null) {
                        _loadAllData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sipariş #${order.orderNumber} son aşama geri alındı.'),
                            backgroundColor: AppColors.info,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                _buildCancelOrderBtn(order),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: order.invoiceSent ? AppColors.success : AppColors.primary),
                      foregroundColor: order.invoiceSent ? AppColors.success : AppColors.primary,
                      minimumSize: const Size(0, 38),
                    ),
                    icon: Icon(order.invoiceSent ? Icons.check_circle_outline : Icons.receipt_long_rounded),
                    label: Text(
                      order.invoiceSent ? 'Bilgi Fişi İletildi' : 'Bilgi Fişi',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onPressed: () => _showInvoiceDialog(order),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Siparişi Veritabanından Tamamen Sil',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 20),
                  onPressed: () => _confirmPermanentDeleteOrder(order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPermanentDeleteOrder(OrderModel order) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Siparişi Kalıcı Olarak Sil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${order.orderNumber} numaralı siparişi sistemden tamamen silmek istediğinize emin misiniz?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bu işlem GERİ ALINAMAZ! Bu sipariş veritabanınızdan, muhasebe/analiz dökümlerinden ve müşteri sorgulama ekranından tamamen silinecektir.',
                      style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await SupabaseService.instance.deleteOrder(order.id);
              _loadAllData();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Sipariş #${order.orderNumber} veritabanından kalıcı olarak silindi.'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportOrdersToExcel(List<OrderModel> listToExport) async {
    if (listToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak sipariş bulunmuyor.')),
      );
      return;
    }

    // Tarihe göre yeniden eskiye sırala (en güncel siparişler en üstte)
    final sorted = List<OrderModel>.from(listToExport)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final buffer = StringBuffer();
    // Excel Türkçe karakter (ğ, ü, ş, ı, ö, ç, İ) desteği için UTF-8 BOM
    buffer.write('\uFEFF');

    // Sütun başlıkları (Excel Türkçe/Avrupa standart noktalı virgül delimiter)
    buffer.writeln(
      'Sipariş No;Sipariş Tarihi;Sipariş Durumu;Toplam Tutar (TL);Ödeme Yöntemi;'
      'Müşteri Adı Soyadı;Telefon;E-Posta;Teslimat Şehri;Teslimat İlçesi;Teslimat Adresi;'
      'Sipariş Edilen Ürünler;Kargo Takip No;Kargo Firması;Müşteri Notu;Bilgi Fişi Durumu',
    );

    for (final order in sorted) {
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt.toLocal());
      final amountStr = order.totalAmount.toStringAsFixed(2).replaceAll('.', ',');
      final paymentMethodStr = order.paymentMethodLabel;
      final invoiceStatusStr = order.invoiceSent
          ? 'İletildi (${order.invoiceSentAt != null ? DateFormat('dd.MM.yyyy HH:mm').format(order.invoiceSentAt!.toLocal()) : ''})'
          : 'İletilmedi';

      final itemsSummary = order.items
          .map((i) => '${i.quantity}x ${i.productName} (${i.variantTitle}) - ${i.subtotal.toStringAsFixed(0)} TL')
          .join(' | ')
          .replaceAll('"', '""');

      final cleanAddress = order.deliveryAddress.replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', '');
      final cleanNote = order.customerNote.replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', '');
      final cleanName = order.customerName.replaceAll('"', '""');
      final cleanCity = order.deliveryCity.replaceAll('"', '""');
      final cleanDistrict = order.deliveryDistrict.replaceAll('"', '""');

      buffer.writeln(
        '"${order.orderNumber}";'
        '"$dateStr";'
        '"${order.statusTitle}";'
        '"$amountStr";'
        '"$paymentMethodStr";'
        '"$cleanName";'
        '"${order.customerPhone}";'
        '"${order.customerEmail}";'
        '"$cleanCity";'
        '"$cleanDistrict";'
        '"$cleanAddress";'
        '"$itemsSummary";'
        '"${order.trackingCode}";'
        '"${order.carrierCompany}";'
        '"$cleanNote";'
        '"$invoiceStatusStr"',
      );
    }

    final bytes = utf8.encode(buffer.toString());
    final fileName = 'manti_mood_siparisler_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    await FileDownloadHelper.downloadBytes(bytes, fileName, mimeType: 'text/csv;charset=utf-8');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${sorted.length} adet sipariş kaydı Excel tablosu (.csv) olarak İndirilenler klasörüne aktarıldı!'),
        backgroundColor: const Color(0xFF1E7E34),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _getLatestToggleableStep(OrderModel order) {
    if (order.status == 'cancelled') return 'cancelled';
    final nonFixed = order.statusSteps.where((s) => s != 'order_received').toList();
    if (nonFixed.isEmpty) return null;
    return nonFixed.last;
  }

  Widget _buildFixedStageChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '$label ✓',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStageToggleBtn({
    required OrderModel order,
    required String label,
    required String stepKey,
    required Color color,
    required IconData icon,
  }) {
    final isChecked = stepKey == 'shipped'
        ? (order.statusSteps.contains('shipped') || order.statusSteps.contains('on_the_way'))
        : order.statusSteps.contains(stepKey);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final updated = await SupabaseService.instance.toggleOrderStep(order.id, stepKey);
        if (updated != null) {
          _loadAllData();
          if (!mounted) return;
          final action = isChecked ? 'kaldırıldı' : 'işaretlendi';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sipariş #${order.orderNumber}: "$label" aşaması $action.'),
              backgroundColor: isChecked ? AppColors.info : AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isChecked ? color : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked ? color : AppColors.cardBorder,
            width: isChecked ? 1.5 : 1,
          ),
          boxShadow: isChecked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isChecked ? Icons.check_circle_rounded : icon,
              size: 14,
              color: isChecked ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              isChecked ? '$label ✓' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                color: isChecked ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelOrderBtn(OrderModel order) {
    final isCancelled = order.status == 'cancelled';
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isCancelled ? AppColors.error : AppColors.surfaceMuted,
        foregroundColor: isCancelled ? Colors.white : AppColors.error,
        elevation: 0,
        side: BorderSide(color: isCancelled ? AppColors.error : AppColors.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(
        isCancelled ? Icons.restore_rounded : Icons.cancel_outlined,
        size: 14,
        color: isCancelled ? Colors.white : AppColors.error,
      ),
      label: Text(isCancelled ? 'İptal Edildi (Geri Al)' : 'İptal Et'),
      onPressed: () async {
        if (isCancelled) {
          final updated = await SupabaseService.instance.toggleOrderStep(order.id, 'cancelled');
          if (updated != null) {
            _loadAllData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sipariş #${order.orderNumber} iptali geri alındı.'),
                backgroundColor: AppColors.info,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Siparişi İptal Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                '#${order.orderNumber} numaralı siparişi (${order.customerName}) iptal etmek istediğinize emin misiniz?',
                style: const TextStyle(fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Evet, İptal Et'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final updated = await SupabaseService.instance.toggleOrderStep(order.id, 'cancelled');
            if (updated != null) {
              _loadAllData();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sipariş #${order.orderNumber} iptal edildi olarak işaretlendi.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        }
      },
    );
  }

  void _showInvoiceDialog(OrderModel order) {
    final GlobalKey invoiceBoundaryKey = GlobalKey();
    bool isGenerating = false;
    String? generatedImageUrl;

    final localCreatedAt = order.createdAt.toLocal();
    final dateStr =
        '${localCreatedAt.day.toString().padLeft(2, '0')}.${localCreatedAt.month.toString().padLeft(2, '0')}.${localCreatedAt.year} '
        '${localCreatedAt.hour.toString().padLeft(2, '0')}:${localCreatedAt.minute.toString().padLeft(2, '0')}';
    final paymentLabel = order.paymentMethodLabel;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bilgi Fişi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // GÖRSEL BİLGİ FİŞİ ALANI
                  RepaintBoundary(
                    key: invoiceBoundaryKey,
                    child: Container(
                      width: 440,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Başlık & Logo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'MANTI MOOD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                          letterSpacing: 1.1,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'El Açması Butik Ev Mantısı & Lezzetleri',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                ),
                                child: const Text(
                                  'BİLGİ FİŞİ',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 10),

                          // Sipariş No ve Tarih
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sipariş No: #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                              Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Müşteri Bilgileri
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const Spacer(),
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(order.customerPhone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                                if (order.customerEmail.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.mail_outline, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(order.customerEmail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${order.deliveryDistrict}, ${order.deliveryAddress}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.customerNote.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.note_alt_outlined, size: 14, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Not: ${order.customerNote}',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.accent),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Ürün Başlıkları
                          Row(
                            children: const [
                              Expanded(flex: 5, child: Text('ÜRÜN & SEÇENEK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                              Expanded(flex: 2, child: Text('ADET', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                              Expanded(flex: 3, child: Text('TUTAR', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 6),

                          // Ürün Satırları
                          ...order.items.map((i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                          Text(i.variantTitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${i.quantity} adet', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text('${i.subtotal.toStringAsFixed(0)} ₺', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              )),

                          const SizedBox(height: 8),
                          Container(height: 1, color: Colors.grey.shade300),
                          const SizedBox(height: 8),

                          // Ödeme ve Toplam
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ödeme Yöntemi:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(paymentLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GENEL TOPLAM:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                              Text('${order.totalAmount.toStringAsFixed(0)} ₺', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Afiyet olsun! Mantı Mood butik ev lezzetlerini tercih ettiğiniz için teşekkür ederiz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'Önemli Uyarı! Esnaf Muafiyeti kapsamında olduğumuzdan bu belge fatura yerine geçmez. Sadece bilgilendirme amaçlıdır.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    order.invoiceSent
                        ? 'Bu bilgi fişinin e-postası daha önce gönderildi.'
                        : 'Bu bilgi fişi ${order.customerEmail} adresine e-posta olarak iletilecektir.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Kapat', style: TextStyle(color: AppColors.textSecondary)),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
                  label: const Text('WhatsApp ile Paylaş', style: TextStyle(color: Color(0xFF1E7E34), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF25D366)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isGenerating
                      ? null
                      : () async {
                          final cleanPhone = order.customerPhone.replaceAll(RegExp(r'\D'), '');
                          final phoneWithCode = cleanPhone.startsWith('0')
                              ? '9$cleanPhone'
                              : (cleanPhone.startsWith('90') ? cleanPhone : '90$cleanPhone');

                          final itemsSummary = order.items
                              .map((i) => '• ${i.quantity}x ${i.productName} (${i.variantTitle}) = ${i.subtotal.toStringAsFixed(0)} ₺')
                              .join('\n');

                          final buffer = StringBuffer();
                          buffer.writeln('🧾 *MANTI MOOD - SİPARİŞ BİLGİ FİŞİ*');
                          buffer.writeln('------------------------------------------');
                          buffer.writeln('Sipariş No: #${order.orderNumber}');
                          buffer.writeln('Tarih: $dateStr');
                          buffer.writeln('Alıcı: ${order.customerName}');
                          buffer.writeln('Teslimat: ${order.deliveryDistrict}, ${order.deliveryAddress}');
                          buffer.writeln('------------------------------------------');
                          buffer.writeln('*Sipariş Detayı:*');
                          buffer.writeln(itemsSummary);
                          buffer.writeln('------------------------------------------');
                          buffer.writeln('*Genel Toplam:* ${order.totalAmount.toStringAsFixed(0)} ₺');
                          buffer.writeln('Ödeme: $paymentLabel');
                          if (generatedImageUrl != null && generatedImageUrl!.startsWith('http')) {
                            buffer.writeln('------------------------------------------');
                            buffer.writeln('Bilgi Fişi Görseli: $generatedImageUrl');
                          }
                          buffer.writeln('------------------------------------------');
                          buffer.writeln('Önemli Uyarı: Esnaf Muafiyeti kapsamında olduğumuzdan bu belge fatura yerine geçmez. Sadece bilgilendirme amaçlıdır.');
                          buffer.writeln('Mantı Mood butik ev lezzetlerini tercih ettiğiniz için teşekkür ederiz. Afiyet olsun!');

                          final uri = Uri.parse('https://wa.me/$phoneWithCode?text=${Uri.encodeComponent(buffer.toString())}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                ),
                ElevatedButton.icon(
                  icon: isGenerating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Bilgi Fişini İndir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isGenerating
                      ? null
                      : () async {
                          setDialogState(() => isGenerating = true);
                          try {
                            await Future.delayed(const Duration(milliseconds: 60));
                            final boundary = invoiceBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                            if (boundary == null) throw Exception('Görsel alanı bulunamadı');
                            final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                            final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                            if (byteData == null) throw Exception('Görsel verisi oluşturulamadı');
                            final bytes = byteData.buffer.asUint8List();

                            final fileName = 'bilgi_fisi_${order.orderNumber}.png';

                            // 1. Doğrudan kullanıcının İndirilenler (Downloads) klasörüne indir
                            await FileDownloadHelper.downloadBytes(bytes, fileName);

                            // 2. Arka planda WhatsApp/E-posta paylaşımı için bulut bağlantısını da hazırla
                            MediaUploadService.instance.uploadRawImageBytes(
                              bytes,
                              fileName: fileName,
                            ).then((url) {
                              generatedImageUrl = url;
                            }).catchError((_) => null);

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bilgi fişi görseli İndirilenler klasörüne indirildi.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Bilgi fişi indirme hatası: $e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Görsel oluşturulurken hata: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } finally {
                            if (dialogCtx.mounted) {
                              setDialogState(() => isGenerating = false);
                            }
                          }
                        },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Bilgi Fişini E-Postala'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isGenerating
                      ? null
                      : () async {
                          setDialogState(() => isGenerating = true);
                          String? imageBase64;
                          try {
                            await Future.delayed(const Duration(milliseconds: 60));
                            final boundary = invoiceBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                            if (boundary != null) {
                              final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
                              final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                              if (byteData != null) {
                                imageBase64 = base64Encode(byteData.buffer.asUint8List());
                              }
                            }
                          } catch (e) {
                            debugPrint('Görsel fiş yakalama uyarısı: $e');
                          }

                          final result = await SupabaseService.instance.sendInvoiceEmail(
                            order,
                            receiptImageBase64: imageBase64,
                          );
                          if (!mounted) return;
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          _loadAllData();
                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bilgi fişi ${order.customerEmail} adresine başarıyla iletildi.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('E-Posta gönderilemedi: ${result['error'] ?? 'Hata'}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. ÜRÜN YÖNETİMİ (TAM DÜZENLEME & YENİ EKLEME)
  // ==========================================
  Widget _buildProductsTab() {
    final filteredProducts = _products.where((p) {
      if (_productCategoryFilter == 'all') return true;
      return p.category == _productCategoryFilter;
    }).toList();

    final allCategories = _settings?.categories ?? [
      'Klasik Mantı',
      'Yöresel Mantı',
      'Sebzeli & Vejetaryen',
      'Soslar & Yan Ürünler',
    ];

    return Column(
      children: [
        // Üst Başlık & Eylemler
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Text(
                    'Kayıtlı Lezzetler (${_products.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.category_outlined, size: 16),
                        label: const Text('Kategoriler'),
                        onPressed: _showCategoryManagerModal,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ürün Ekle'),
                        onPressed: () => _showProductEditDialog(null),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Kategori Filtre Çipleri
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildProductCategoryChip('Tümü (${_products.length})', 'all'),
                    ...allCategories.map((c) {
                      final count = _products.where((p) => p.category == c).length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildProductCategoryChip('$c ($count)', c),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Text('Bu kategoride ürün bulunamadı.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 460;
                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: ProductImage(
                                          imageUrl: product.imageUrl,
                                          width: 65,
                                          height: 65,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${product.basePrice.toStringAsFixed(0)} ₺ başlangıç',
                                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              product.category,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Switch(
                                            value: product.isAvailable,
                                            activeThumbColor: AppColors.success,
                                            onChanged: (val) async {
                                              await SupabaseService.instance.toggleProductAvailability(product.id, product.isAvailable);
                                              _loadAllData();
                                            },
                                          ),
                                          Text(
                                            product.isAvailable ? 'Satışta' : 'Tükendi',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: product.isAvailable ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (product.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      product.description,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (product.allMedia.length > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.photo_library, size: 11, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${product.allMedia.length} medya',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        const SizedBox.shrink(),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.edit_outlined, size: 15),
                                            label: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () => _showProductEditDialog(product),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            tooltip: 'Sil',
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                            onPressed: () => _confirmDeleteProduct(product),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            // Geniş / Tablet / Masaüstü Görünüm
                            return Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ProductImage(
                                    imageUrl: product.imageUrl,
                                    width: 70,
                                    height: 70,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          if (product.allMedia.length > 1) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.photo_library, size: 11, color: AppColors.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${product.allMedia.length} medya',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text('${product.basePrice.toStringAsFixed(0)} ₺ başlangıç', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(product.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      Text(
                                        product.description,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Düzenle & Sil Butonları
                                IconButton(
                                  tooltip: 'Düzenle (Fotoğraflar, Fiyat, Kategori)',
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                  onPressed: () => _showProductEditDialog(product),
                                ),
                                IconButton(
                                  tooltip: 'Sil',
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () => _confirmDeleteProduct(product),
                                ),
                                // Stok Aç/Kapa
                                Column(
                                  children: [
                                    Switch(
                                      value: product.isAvailable,
                                      activeThumbColor: AppColors.success,
                                      onChanged: (val) async {
                                        await SupabaseService.instance.toggleProductAvailability(product.id, product.isAvailable);
                                        _loadAllData();
                                      },
                                    ),
                                    Text(
                                      product.isAvailable ? 'Satışta' : 'Tükendi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: product.isAvailable ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCategoryChip(String label, String value) {
    final isSelected = _productCategoryFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _productCategoryFilter = value),
    );
  }

  // Ürün Düzenleme & Ekleme Dialogu
  void _showProductEditDialog(Product? product) {
    final isNew = product == null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    List<_VariantEditorItem> variantItems = [];
    if (product != null && product.variants.isNotEmpty) {
      variantItems = product.variants
          .map((v) => _VariantEditorItem(title: v.title, price: v.price))
          .toList();
    } else {
      variantItems = [
        _VariantEditorItem(title: '500 gr (2 Porsiyon)', price: 250.0),
        _VariantEditorItem(title: '1 Kg (4 Porsiyon)', price: 460.0),
        _VariantEditorItem(title: '2 Kg (Aile Boyu)', price: 880.0),
      ];
    }
    final customUrlCtrl = TextEditingController();
    final cookingCtrl = TextEditingController(text: product?.cookingInstructions ?? 'Kaynar suda 8-10 dakika haşlayınız.');
    final storageCtrl = TextEditingController(text: product?.storageInstructions ?? '-18°C dondurucuda 3 ay saklayınız.');

    final availableCategories = List<String>.from(_settings?.categories ?? [
      'Klasik Mantı',
      'Yöresel Mantı',
      'Sebzeli & Vejetaryen',
      'Soslar & Yan Ürünler',
    ]);

    String category = product?.category ?? (availableCategories.isNotEmpty ? availableCategories.first : 'Klasik Mantı');
    if (!availableCategories.contains(category)) {
      availableCategories.insert(0, category);
    }

    List<String> mediaList = List<String>.from(
      product?.allMedia.isNotEmpty == true 
          ? product!.allMedia 
          : (product?.imageUrl.isNotEmpty == true ? [product!.imageUrl] : ['assets/images/manti-cesitleri/bohca.png'])
    );
    final Map<String, String> localOriginalSourceMap = {};

    bool isUploadingMedia = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNarrow = MediaQuery.of(context).size.width < 500;
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 12 : 28,
              vertical: isNarrow ? 14 : 24,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
              padding: EdgeInsets.all(isNarrow ? 14 : 22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isNew ? 'Ürün / Mantı Ekle' : 'Ürünü Düzenle',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // 1. Ürün Adı
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ürün / Mantı Adı *',
                        hintText: 'Örn: Çıtır Sinop Mantısı veya Fırın Makarna',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Kategori Seçimi & Hızlı Ekleme
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            isExpanded: true,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Kategori *',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: availableCategories.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Kategori Ekle',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onPressed: () async {
                            final newCat = await _promptNewCategoryInline(context);
                            if (newCat != null && newCat.isNotEmpty) {
                              setDialogState(() {
                                if (!availableCategories.contains(newCat)) availableCategories.add(newCat);
                                category = newCat;
                              });
                              if (_settings != null && !_settings!.categories.contains(newCat)) {
                                final updated = List<String>.from(_settings!.categories)..add(newCat);
                                _saveSettings(_settings!.copyWith(categories: updated));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Porsiyon & Paket Seçenekleri (Dinamik Ekleme / Silme / Düzenleme)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.scale_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Porsiyon & Paket Seçenekleri',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Paket Ekle', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    variantItems.add(_VariantEditorItem(title: 'Paket / Porsiyon', price: 200.0));
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Varsayılan olarak 500 gr, 1 Kg ve 2 Kg (Aile Boyu) tanımlıdır. İsimleri ve fiyatları dilediğiniz gibi değiştirebilir (örn: 250 gr yapabilir), silebilir veya yeni seçenekler ekleyebilirsiniz.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          if (variantItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Varsayılan Paketleri Geri Yükle (500g, 1kg, 2kg)'),
                                  onPressed: () {
                                    setDialogState(() {
                                      variantItems = [
                                        _VariantEditorItem(title: '500 gr (2 Porsiyon)', price: 250.0),
                                        _VariantEditorItem(title: '1 Kg (4 Porsiyon)', price: 460.0),
                                        _VariantEditorItem(title: '2 Kg (Aile Boyu)', price: 880.0),
                                      ];
                                    });
                                  },
                                ),
                              ),
                            )
                          else
                            ...variantItems.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: isNarrow
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: item.titleCtrl,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  decoration: const InputDecoration(
                                                    labelText: 'Paket / Porsiyon Adı *',
                                                    hintText: 'Örn: 500 gr veya 1 Kg',
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                tooltip: 'Bu Seçeneği Sil',
                                                visualDensity: VisualDensity.compact,
                                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                                onPressed: () {
                                                  setDialogState(() {
                                                    variantItems.removeAt(idx);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: item.priceCtrl,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            decoration: const InputDecoration(
                                              labelText: 'Fiyat (₺) *',
                                              hintText: '250',
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: TextField(
                                              controller: item.titleCtrl,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              decoration: const InputDecoration(
                                                labelText: 'Paket / Porsiyon Adı *',
                                                hintText: 'Örn: 250 gr veya 2 Kg (Aile Boyu)',
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: TextField(
                                              controller: item.priceCtrl,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              decoration: const InputDecoration(
                                                labelText: 'Fiyat (₺) *',
                                                hintText: '250',
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Bu Seçeneği Sil',
                                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                            onPressed: () {
                                              setDialogState(() {
                                                variantItems.removeAt(idx);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                              );
                            }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Açıklama
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Ürün Açıklaması', hintText: '%100 dana kıymalı, anne eli taze el açması...'),
                  ),
                  const SizedBox(height: 14),

                  // 5. ÇOKLU FOTOĞRAF VE VİDEO YÖNETİMİ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Ürün Fotoğrafları & Videoları (${mediaList.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            if (isUploadingMedia)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cihazınızdan tek seferde birden fazla fotoğraf veya video seçebilirsiniz. Listenin ilk sırasındaki görsel vitrin kapağı olur.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_photo_alternate, size: 16),
                              label: const Text('Cihazdan Fotoğraf Seç'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: isUploadingMedia
                                  ? null
                                  : () async {
                                      setDialogState(() => isUploadingMedia = true);
                                      final picked = await MediaUploadService.instance.pickMultiImages();
                                      setDialogState(() {
                                        isUploadingMedia = false;
                                        if (picked.isNotEmpty) {
                                          for (final p in picked) {
                                            localOriginalSourceMap[p] = p;
                                          }
                                          mediaList.addAll(picked);
                                        }
                                      });
                                      if (picked.length == 1 && context.mounted) {
                                        final singlePicked = picked.first;
                                        final cropped = await ImageCropperDialog.show(
                                          context,
                                          imageSource: singlePicked,
                                          originalSource: singlePicked,
                                          defaultAspectRatio: 4 / 3,
                                          title: 'Ürün Fotoğrafını Çerçevele',
                                        );
                                        if (cropped != null && context.mounted) {
                                          localOriginalSourceMap[cropped] = singlePicked;
                                          setDialogState(() {
                                            final idx = mediaList.indexOf(singlePicked);
                                            if (idx != -1) {
                                              mediaList[idx] = cropped;
                                            }
                                          });
                                        }
                                      }
                                    },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.video_call_outlined, size: 16),
                              label: const Text('Video Ekle'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: isUploadingMedia
                                  ? null
                                  : () async {
                                      setDialogState(() => isUploadingMedia = true);
                                      final picked = await MediaUploadService.instance.pickVideo();
                                      setDialogState(() {
                                        isUploadingMedia = false;
                                        if (picked != null) {
                                          mediaList.add(picked);
                                        }
                                      });
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (mediaList.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 28),
                                SizedBox(height: 6),
                                Text('Henüz görsel/video eklenmedi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text('Yukarıdaki butonlarla cihazınızdan yükleme yapabilirsiniz.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 95,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: mediaList.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final item = mediaList[idx];
                                final isCover = idx == 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Tooltip(
                                      message: 'Fotoğrafı Çerçevele & Zoom Ayarla',
                                      child: InkWell(
                                        onTap: () async {
                                          final orig = localOriginalSourceMap[item];
                                          final cropped = await ImageCropperDialog.show(
                                            context,
                                            imageSource: item,
                                            originalSource: orig,
                                            defaultAspectRatio: 4 / 3,
                                            title: 'Fotoğrafı Çerçevele & Kırp',
                                          );
                                          if (cropped != null && context.mounted) {
                                            localOriginalSourceMap[cropped] = orig ?? item;
                                            setDialogState(() {
                                              mediaList[idx] = cropped;
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isCover ? AppColors.primary : AppColors.cardBorder,
                                              width: isCover ? 2 : 1,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: ProductImage(
                                            imageUrl: item,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isCover)
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Kapak', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            mediaList.removeAt(idx);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    // Kırp / Çerçevele Butonu
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () async {
                                          final orig = localOriginalSourceMap[item];
                                          final cropped = await ImageCropperDialog.show(
                                            context,
                                            imageSource: item,
                                            originalSource: orig,
                                            defaultAspectRatio: 4 / 3,
                                            title: 'Fotoğrafı Çerçevele & Kırp',
                                          );
                                          if (cropped != null && context.mounted) {
                                            localOriginalSourceMap[cropped] = orig ?? item;
                                            setDialogState(() {
                                              mediaList[idx] = cropped;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(color: Colors.white38, width: 0.5),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.crop, size: 10, color: Colors.white),
                                              SizedBox(width: 2),
                                              Text('Kırp', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: customUrlCtrl,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  labelText: 'veya Web Görsel URL / Dosya Yolu Girin',
                                  hintText: 'https://... veya assets/images/...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.crop, color: AppColors.primary),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Çerçevele & Listeye Ekle',
                              onPressed: () async {
                                final txt = customUrlCtrl.text.trim();
                                if (txt.isNotEmpty) {
                                  localOriginalSourceMap[txt] = txt;
                                  final cropped = await ImageCropperDialog.show(
                                    context,
                                    imageSource: txt,
                                    originalSource: txt,
                                    defaultAspectRatio: 4 / 3,
                                    title: 'Fotoğrafı Çerçevele & Kırp',
                                  );
                                  if (cropped != null && context.mounted) {
                                    localOriginalSourceMap[cropped] = txt;
                                    setDialogState(() {
                                      mediaList.add(cropped);
                                      customUrlCtrl.clear();
                                    });
                                  } else {
                                    setDialogState(() {
                                      mediaList.add(txt);
                                      customUrlCtrl.clear();
                                    });
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Listeye Ekle',
                              onPressed: () {
                                final txt = customUrlCtrl.text.trim();
                                if (txt.isNotEmpty) {
                                  setDialogState(() {
                                    mediaList.add(txt);
                                    customUrlCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. Pişirme & Saklama Rehberi
                  TextField(
                    controller: cookingCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Nasıl Pişirilir? (Sos & Pişirme Rehberi)', hintText: 'Kaç dakika kaynatılır?'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: storageCtrl,
                    decoration: const InputDecoration(labelText: 'Nasıl Saklanır?', hintText: '-18°C dondurucuda...'),
                  ),
                  const SizedBox(height: 20),

                  // 7. Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final savedVariants = <ProductVariant>[];
                        for (var item in variantItems) {
                          final title = item.titleCtrl.text.trim();
                          final price = double.tryParse(item.priceCtrl.text.trim()) ?? 0.0;
                          if (title.isNotEmpty && price > 0) {
                            savedVariants.add(ProductVariant(title: title, price: price));
                          }
                        }
                        if (savedVariants.isEmpty) {
                          savedVariants.addAll([
                            const ProductVariant(title: '500 gr (2 Porsiyon)', price: 250.0),
                            const ProductVariant(title: '1 Kg (4 Porsiyon)', price: 460.0),
                            const ProductVariant(title: '2 Kg (Aile Boyu)', price: 880.0),
                          ]);
                        }

                        final basePrice = savedVariants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
                        final primaryImage = mediaList.isNotEmpty
                            ? mediaList.first
                            : (product?.imageUrl.isNotEmpty == true ? product!.imageUrl : 'assets/images/manti-cesitleri/bohca.png');

                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        await SupabaseService.instance.saveProduct(
                          id: product?.id,
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          category: category,
                          basePrice: basePrice,
                          variants: savedVariants,
                          imageUrl: primaryImage,
                          mediaUrls: mediaList.isNotEmpty ? mediaList : [primaryImage],
                          cookingInstructions: cookingCtrl.text.trim(),
                          storageInstructions: storageCtrl.text.trim(),
                          isAvailable: product?.isAvailable ?? true,
                        );

                        if (!mounted) return;
                        nav.pop();
                        _loadAllData();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(isNew ? 'Ürün başarıyla eklendi!' : 'Ürün bilgileri güncellendi!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: Text(isNew ? 'Ürünü Yayınla' : 'Değişiklikleri Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${product.name} silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz. Ürün menüden kaldırılacaktır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              await SupabaseService.instance.deleteProduct(product.id);
              if (!mounted) return;
              nav.pop();
              _loadAllData();
              messenger.showSnackBar(
                const SnackBar(content: Text('Ürün silindi.'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KATEGORİ YÖNETİMİ MODALLARI & METOTLARI
  // ==========================================
  Future<String?> _promptNewCategoryInline(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Kategori Ekle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            hintText: 'Örn: Makarna veya Fırın Lezzetleri',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditCategoryDialog(String? oldCategory, int? index) {
    final isNew = oldCategory == null;
    final ctrl = TextEditingController(text: oldCategory ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isNew ? 'Kategori Ekle' : 'Kategoriyi Yeniden Adlandır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı *',
                hintText: 'Örn: Klasik Mantı, Makarna, Soslar',
              ),
            ),
            if (!isNew) ...[
              const SizedBox(height: 10),
              Text(
                'Bu kategorideki (${_products.where((p) => p.category == oldCategory).length}) ürünün kategorisi de otomatik olarak güncellenecektir.',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;

              final nav = Navigator.of(ctx);
              final currentList = List<String>.from(_settings?.categories ?? [
                'Klasik Mantı',
                'Yöresel Mantı',
                'Sebzeli & Vejetaryen',
                'Soslar & Yan Ürünler',
              ]);

              if (isNew) {
                if (!currentList.contains(newName)) {
                  currentList.add(newName);
                }
              } else if (index != null && index >= 0 && index < currentList.length) {
                currentList[index] = newName;
                final affected = _products.where((p) => p.category == oldCategory).toList();
                for (var p in affected) {
                  await SupabaseService.instance.saveProduct(
                    id: p.id,
                    name: p.name,
                    description: p.description,
                    category: newName,
                    basePrice: p.basePrice,
                    variants: p.variants,
                    imageUrl: p.imageUrl,
                    mediaUrls: p.mediaUrls,
                    cookingInstructions: p.cookingInstructions,
                    storageInstructions: p.storageInstructions,
                    isAvailable: p.isAvailable,
                  );
                }
              }

              if (ctx.mounted) nav.pop();
              await _saveSettings((_settings ?? const StoreSettings()).copyWith(categories: currentList));
              _loadAllData();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(int index) {
    if (_settings == null || index < 0 || index >= _settings!.categories.length) return;
    final catName = _settings!.categories[index];
    final affectedCount = _products.where((p) => p.category == catName).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('$catName Silinsin mi?'),
        content: Text(
          affectedCount > 0
              ? 'Bu kategoride $affectedCount adet ürün bulunuyor. Kategori silindiğinde bu ürünler ilk sıradaki kategoriye aktarılacaktır. Devam etmek istiyor musunuz?'
              : 'Bu kategoriyi menüden kaldırmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = List<String>.from(_settings!.categories);
              updated.removeAt(index);
              final fallbackCategory = updated.isNotEmpty ? updated.first : 'Klasik Mantı';

              final affected = _products.where((p) => p.category == catName).toList();
              for (var p in affected) {
                await SupabaseService.instance.saveProduct(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  category: fallbackCategory,
                  basePrice: p.basePrice,
                  variants: p.variants,
                  imageUrl: p.imageUrl,
                  mediaUrls: p.mediaUrls,
                  cookingInstructions: p.cookingInstructions,
                  storageInstructions: p.storageInstructions,
                  isAvailable: p.isAvailable,
                );
              }

              await _saveSettings(_settings!.copyWith(categories: updated));
              _loadAllData();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showCategoryManagerModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cats = _settings?.categories ?? [];
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category, color: AppColors.primary),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Kategori Yönetimi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Kategori Ekle'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddOrEditCategoryDialog(null, null);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (cats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tanımlı kategori bulunmuyor.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cats.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final c = cats[i];
                          final count = _products.where((p) => p.category == c).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.label_important_outline, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Text('$count ürün', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(width: 6),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showAddOrEditCategoryDialog(c, i);
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _confirmDeleteCategory(i);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 3. VİTRİN BANNERLARI (DÜZENLEME & EKLEME)
  // ==========================================
  Widget _buildBannersTab() {
    final activeCount = _banners.where((b) => b.isActive).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                'Vitrin Afişleri ($activeCount Yayında / ${_banners.length} Toplam)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Banner Ekle'),
                onPressed: () => _showBannerEditDialog(null),
              ),
            ],
          ),
        ),

        // Akıllı Hibrit Bilgilendirme Kutusu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.info,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Birden fazla banner eklerseniz ve yayında tutarsanız, resimler ana sayfada slayt geçişi olarak sergilenir.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _banners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'Henüz hiç vitrin afişi eklenmemiş.',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('İlk Afişi Ekle'),
                        onPressed: () => _showBannerEditDialog(null),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductImage(
                            imageUrl: banner.imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.infoContainer,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('🖥️ Web (16:7)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info)),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: banner.mobileImageUrl.isNotEmpty ? AppColors.successContainer : AppColors.surfaceMuted,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  banner.mobileImageUrl.isNotEmpty ? '📱 Mobil Özel' : '📱 Mobil (Web Ortak)',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: banner.mobileImageUrl.isNotEmpty ? AppColors.success : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(banner.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          Text(banner.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: banner.isActive ? AppColors.successContainer : AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: banner.isActive ? AppColors.success.withValues(alpha: 0.4) : AppColors.cardBorder,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            banner.isActive ? Icons.visibility : Icons.inventory_2_outlined,
                                            size: 14,
                                            color: banner.isActive ? AppColors.success : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            banner.isActive ? 'Yayında' : 'Yedek Depo',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: banner.isActive ? AppColors.success : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          banner.isActive ? 'Vitrinde' : 'Yedekte',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(width: 4),
                                        Transform.scale(
                                          scale: 0.85,
                                          child: Switch(
                                            value: banner.isActive,
                                            activeThumbColor: AppColors.success,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            onChanged: (val) async {
                                              await SupabaseService.instance.toggleBannerActive(banner.id, val);
                                              _loadAllData();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                                          tooltip: 'Düzenle',
                                          onPressed: () => _showBannerEditDialog(banner),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                          tooltip: 'Sil',
                                          onPressed: () async {
                                            await SupabaseService.instance.deleteBanner(banner.id);
                                            _loadAllData();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showBannerEditDialog(BannerItem? banner) {
    final isNew = banner == null;
    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final subCtrl = TextEditingController(text: banner?.subtitle ?? '');
    final imageCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    final mobileImageCtrl = TextEditingController(text: banner?.mobileImageUrl ?? '');
    String? originalWebSource = banner?.imageUrl;
    String? originalMobileSource = banner?.mobileImageUrl;
    bool isActive = banner?.isActive ?? true;
    bool isPickingWeb = false;
    bool isPickingMobile = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNarrow = MediaQuery.of(context).size.width < 500;
          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 12 : 28,
              vertical: isNarrow ? 16 : 24,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isNew ? 'Banner Ekle' : 'Bannerı Düzenle'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Banner Başlığı *', hintText: 'Örn: Taze Anne Eli Mantı'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subCtrl,
                      decoration: const InputDecoration(labelText: 'Alt Açıklama', hintText: 'Örn: %100 Dana Kıyma, Katkısız'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // WEB GÖRÜNÜMÜ (ANA VİTRİN)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.desktop_windows, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Web Görünümü (16:7)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Zorunlu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Bilgisayar ve geniş ekranlarda sergilenecek ana vitrin görselidir.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          if (imageCtrl.text.isNotEmpty)
                            Container(
                              height: 120,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  ProductImage(
                                    imageUrl: imageCtrl.text,
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black87,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        textStyle: const TextStyle(fontSize: 11),
                                      ),
                                      icon: const Icon(Icons.crop, size: 13),
                                      label: const Text('16:7 Çerçevele'),
                                      onPressed: () async {
                                        final sourceToCrop = (originalWebSource?.isNotEmpty == true) ? originalWebSource! : imageCtrl.text;
                                        final cropped = await ImageCropperDialog.show(
                                          context,
                                          imageSource: imageCtrl.text,
                                          originalSource: sourceToCrop,
                                          defaultAspectRatio: 16 / 7,
                                          title: 'Web Görünümünü Çerçevele (16:7)',
                                        );
                                        if (cropped != null && context.mounted) {
                                          setDialogState(() {
                                            imageCtrl.text = cropped;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              height: 70,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 20, color: AppColors.textMuted),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Görsel seçmek için aşağıdaki butonu kullanınız',
                                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (isNarrow) ...[
                            ElevatedButton.icon(
                              icon: isPickingWeb
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.upload_file, size: 16),
                              label: Text(isPickingWeb ? 'Yükleniyor...' : 'Cihazdan Fotoğraf Seç'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                              ),
                              onPressed: isPickingWeb
                                  ? null
                                  : () async {
                                      setDialogState(() => isPickingWeb = true);
                                      final picked = await MediaUploadService.instance.pickImageForCropping();
                                      setDialogState(() => isPickingWeb = false);
                                      if (picked != null && context.mounted) {
                                        originalWebSource = picked;
                                        final cropped = await ImageCropperDialog.show(
                                          context,
                                          imageSource: picked,
                                          originalSource: picked,
                                          defaultAspectRatio: 16 / 7,
                                          title: 'Web Görünümünü Çerçevele (16:7)',
                                        );
                                        setDialogState(() {
                                          imageCtrl.text = cropped ?? picked;
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: imageCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Web Görünümü Görsel URL / Yolu',
                                hintText: 'https://... veya assets/...',
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ] else
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: isPickingWeb
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.upload_file, size: 16),
                                  label: Text(isPickingWeb ? 'Yükleniyor...' : 'Cihazdan Seç'),
                                  onPressed: isPickingWeb
                                      ? null
                                      : () async {
                                          setDialogState(() => isPickingWeb = true);
                                          final picked = await MediaUploadService.instance.pickImageForCropping();
                                          setDialogState(() => isPickingWeb = false);
                                          if (picked != null && context.mounted) {
                                            originalWebSource = picked;
                                            final cropped = await ImageCropperDialog.show(
                                              context,
                                              imageSource: picked,
                                              originalSource: picked,
                                              defaultAspectRatio: 16 / 7,
                                              title: 'Web Görünümünü Çerçevele (16:7)',
                                            );
                                            setDialogState(() {
                                              imageCtrl.text = cropped ?? picked;
                                            });
                                          }
                                        },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: imageCtrl,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(
                                      labelText: 'Web Görünümü Görsel URL / Yolu',
                                      hintText: 'https://... veya assets/...',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // MOBİL GÖRÜNÜMÜ
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone_android, size: 18, color: AppColors.accent),
                                  SizedBox(width: 8),
                                  Text('Mobil Görünümü (16:9)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(4)),
                                child: const Text('İsteğe Bağlı', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'İsteğe bağlıdır. Boş bırakırsanız Web Görünümü mobilde de otomatik uyarlanır. Telefon ekranları için özel bir görsel eklemek isterseniz burayı kullanabilirsiniz.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          if (mobileImageCtrl.text.isNotEmpty)
                            Container(
                              height: 120,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  ProductImage(
                                    imageUrl: mobileImageCtrl.text,
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () => setDialogState(() => mobileImageCtrl.clear()),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black87,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        textStyle: const TextStyle(fontSize: 11),
                                      ),
                                      icon: const Icon(Icons.crop, size: 13),
                                      label: const Text('16:9 Çerçevele'),
                                      onPressed: () async {
                                        final sourceToCrop = (originalMobileSource?.isNotEmpty == true) ? originalMobileSource! : mobileImageCtrl.text;
                                        final cropped = await ImageCropperDialog.show(
                                          context,
                                          imageSource: mobileImageCtrl.text,
                                          originalSource: sourceToCrop,
                                          defaultAspectRatio: 16 / 9,
                                          title: 'Mobil Görünümünü Çerçevele (16:9)',
                                        );
                                        if (cropped != null && context.mounted) {
                                          setDialogState(() {
                                            mobileImageCtrl.text = cropped;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isNarrow) ...[
                            ElevatedButton.icon(
                              icon: isPickingMobile
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.upload_file, size: 16),
                              label: Text(isPickingMobile ? 'Yükleniyor...' : 'Cihazdan Fotoğraf Seç'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                              ),
                              onPressed: isPickingMobile
                                  ? null
                                  : () async {
                                      setDialogState(() => isPickingMobile = true);
                                      final picked = await MediaUploadService.instance.pickImageForCropping();
                                      setDialogState(() => isPickingMobile = false);
                                      if (picked != null && context.mounted) {
                                        originalMobileSource = picked;
                                        final cropped = await ImageCropperDialog.show(
                                          context,
                                          imageSource: picked,
                                          originalSource: picked,
                                          defaultAspectRatio: 16 / 9,
                                          title: 'Mobil Görünümünü Çerçevele (16:9)',
                                        );
                                        setDialogState(() {
                                          mobileImageCtrl.text = cropped ?? picked;
                                        });
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: mobileImageCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'Mobil Görünümü Görsel URL / Yolu',
                                hintText: 'İsteğe bağlı 16:9 görsel',
                                isDense: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ] else
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: isPickingMobile
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.upload_file, size: 16),
                                  label: Text(isPickingMobile ? 'Yükleniyor...' : 'Cihazdan Seç'),
                                  onPressed: isPickingMobile
                                      ? null
                                      : () async {
                                          setDialogState(() => isPickingMobile = true);
                                          final picked = await MediaUploadService.instance.pickImageForCropping();
                                          setDialogState(() => isPickingMobile = false);
                                          if (picked != null && context.mounted) {
                                            originalMobileSource = picked;
                                            final cropped = await ImageCropperDialog.show(
                                              context,
                                              imageSource: picked,
                                              originalSource: picked,
                                              defaultAspectRatio: 16 / 9,
                                              title: 'Mobil Görünümünü Çerçevele (16:9)',
                                            );
                                            setDialogState(() {
                                              mobileImageCtrl.text = cropped ?? picked;
                                            });
                                          }
                                        },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: mobileImageCtrl,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(
                                      labelText: 'Mobil Görünümü Görsel URL / Yolu',
                                      hintText: 'İsteğe bağlı 16:9 görsel',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. YAYIN DURUMU (AKTİF / YEDEK)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isActive,
                          activeThumbColor: AppColors.success,
                          title: const Text('Bu Afişi Vitrinde Yayınla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            isActive
                                ? 'Aktif afiş: Ana sayfada vitrinde gösterilir.'
                                : 'Yedek depo: Ana sayfada gizlenir, depoda saklanır.',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          onChanged: (val) => setDialogState(() => isActive = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: () async {
                final webImg = imageCtrl.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                if (webImg.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Lütfen bir Web Görünümü görseli belirleyin!'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                final mobImg = mobileImageCtrl.text.trim();
                await SupabaseService.instance.saveBanner(
                  id: banner?.id,
                  title: titleCtrl.text.trim(),
                  subtitle: subCtrl.text.trim(),
                  imageUrl: webImg,
                  mobileImageUrl: mobImg.isNotEmpty ? mobImg : null,
                  isActive: isActive,
                );
                if (!mounted) return;
                nav.pop();
                _loadAllData();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Vitrin afişi başarıyla kaydedildi!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    ),
  );
}

  // ==========================================
  // 4. DÜKKAN AYARLARI, TESLİMAT, IBAN & ROZETLER
  // ==========================================
  Future<void> _saveSettings(
    StoreSettings newSettings, {
    String? successMessage,
    bool clearAnnouncement = false,
  }) async {
    // Duyuru metnini güvenle çözümle
    String resolvedAnnouncement;
    if (clearAnnouncement) {
      resolvedAnnouncement = '';
      _announcementController?.clear();
    } else if (newSettings.announcementText != _settings?.announcementText) {
      // Eğer newSettings doğrudan yeni bir duyuru değeriyle çağrıldıysa onu esas al
      resolvedAnnouncement = newSettings.announcementText.trim();
      if (_announcementController != null && _announcementController!.text != resolvedAnnouncement) {
        _announcementController!.text = resolvedAnnouncement;
      }
    } else if (_announcementController != null) {
      // Form alanındaki güncel değeri esas al (temizlendiyse boş string olarak kalır)
      resolvedAnnouncement = _announcementController!.text.trim();
    } else {
      resolvedAnnouncement = newSettings.announcementText.trim();
    }

    final merged = newSettings.copyWith(
      announcementText: resolvedAnnouncement,
      pickupTitle: _pickupTitleCtrl?.text.trim() ?? newSettings.pickupTitle,
      pickupDescription: _pickupDescCtrl?.text.trim() ?? newSettings.pickupDescription,
      deliveryTitle: _deliveryTitleCtrl?.text.trim() ?? newSettings.deliveryTitle,
      deliveryDescription: _deliveryDescCtrl?.text.trim() ?? newSettings.deliveryDescription,
      storyCardTitle: _storyTitleCtrl?.text.trim() ?? newSettings.storyCardTitle,
      storyCardContent: _storyContentCtrl?.text.trim() ?? newSettings.storyCardContent,
      storyCardImageUrl: _storyImageCtrl?.text.trim() ?? newSettings.storyCardImageUrl,
      whatsappNumber: _phoneController?.text.trim() ?? newSettings.whatsappNumber,
      minOrderAmount: _minOrderController != null
          ? (double.tryParse(_minOrderController!.text.trim()) ?? newSettings.minOrderAmount)
          : newSettings.minOrderAmount,
    );

    setState(() {
      _settings = merged;
      _initSettingsControllers(merged);
    });

    final success = await SupabaseService.instance.updateStoreSettings(merged);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  successMessage ?? 'Dükkan ayarları başarıyla kaydedildi!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAllSettings() async {
    if (_settings == null) return;
    final annText = _announcementController?.text.trim() ?? '';
    await _saveSettings(
      _settings!.copyWith(
        pickupTitle: _pickupTitleCtrl?.text.trim() ?? 'Gel-Al / Mutfaktan Teslim',
        pickupDescription: _pickupDescCtrl?.text.trim() ?? 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
        deliveryTitle: _deliveryTitleCtrl?.text.trim() ?? 'Adrese Teslimat (Kurye / Kargo)',
        deliveryDescription: _deliveryDescCtrl?.text.trim() ?? 'Siparişiniz adresinize özenle teslim edilir.',
        storyCardTitle: _storyTitleCtrl?.text.trim() ?? 'Mantı Mood Hikayesi',
        storyCardContent: _storyContentCtrl?.text.trim() ?? '',
        storyCardImageUrl: _storyImageCtrl?.text.trim() ?? 'assets/images/manti-mood-logo.png',
        whatsappNumber: _phoneController?.text.trim() ?? '905551234567',
        minOrderAmount: double.tryParse(_minOrderController?.text ?? '200') ?? 200.0,
        announcementText: annText,
        adminPassword: _settings?.adminPassword ?? '',
      ),
      clearAnnouncement: annText.isEmpty,
      successMessage: 'Tüm dükkan ve tema ayarları başarıyla kaydedildi!',
    );
  }

  void _showBadgeDialog(StoreBadge? badge, int? index) {
    final isNew = badge == null;
    final iconCtrl = TextEditingController(text: badge?.icon ?? '🥩');
    final titleCtrl = TextEditingController(text: badge?.title ?? '');
    final subtitleCtrl = TextEditingController(text: badge?.subtitle ?? '');

    const quickEmojis = ['🥩', '🥟', '🌿', '❄️', '✨', '🚚', '❤️', '🥣', '🥇', '🌾', '👨‍🍳', '🧀'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isNew ? 'Vitrin Kartı Ekle' : 'Vitrin Kartını Düzenle'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İkon / Emoji Seçiniz:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickEmojis.map((e) {
                      final isSelected = iconCtrl.text == e;
                      return InkWell(
                        onTap: () {
                          setDialogState(() => iconCtrl.text = e);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iconCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Özel Emoji / İkon',
                      hintText: 'Örn: 🥟 veya 🔥',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kart Başlığı *',
                      hintText: 'Örn: %100 Dana Eti veya Günlük Taze',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alt Açıklama',
                      hintText: 'Örn: Katkısız Harç veya El Açması Hamur',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final newBadge = StoreBadge(
                  icon: iconCtrl.text.trim().isEmpty ? '🥟' : iconCtrl.text.trim(),
                  title: titleCtrl.text.trim(),
                  subtitle: subtitleCtrl.text.trim(),
                );
                final updatedList = List<StoreBadge>.from(_settings!.badges);
                if (index != null && index >= 0 && index < updatedList.length) {
                  updatedList[index] = newBadge;
                } else {
                  updatedList.add(newBadge);
                }
                Navigator.pop(context);
                _saveSettings(_settings!.copyWith(badges: updatedList));
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBadge(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Kartı Sil'),
        content: const Text('Bu vitrin kartını ana sayfadan kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              final updatedList = List<StoreBadge>.from(_settings!.badges);
              if (index >= 0 && index < updatedList.length) {
                updatedList.removeAt(index);
                _saveSettings(_settings!.copyWith(badges: updatedList));
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showBankAccountDialog(BankAccount? account, int? index) {
    final isNew = account == null;
    final bankCtrl = TextEditingController(text: account?.bankName ?? 'Ziraat Bankası');
    final ibanCtrl = TextEditingController(text: account?.iban ?? 'TR');
    final holderCtrl = TextEditingController(text: account?.accountHolder ?? 'Mantı Mood');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isNew ? 'Banka Hesabı Ekle' : 'Banka Hesabını Düzenle'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(labelText: 'Banka Adı *', hintText: 'Örn: Ziraat Bankası, Garanti BBVA'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ibanCtrl,
                decoration: const InputDecoration(labelText: 'IBAN Numarası *', hintText: 'TR.. .. .. ..'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderCtrl,
                decoration: const InputDecoration(labelText: 'Hesap Sahibi Adı *', hintText: 'Örn: Ayşe Yılmaz (Mantı Mood)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () {
              if (ibanCtrl.text.trim().isEmpty || bankCtrl.text.trim().isEmpty) return;
              final newAccount = BankAccount(
                bankName: bankCtrl.text.trim(),
                iban: ibanCtrl.text.trim(),
                accountHolder: holderCtrl.text.trim(),
              );
              final updatedList = List<BankAccount>.from(_settings!.bankAccounts);
              if (index != null && index >= 0 && index < updatedList.length) {
                updatedList[index] = newAccount;
              } else {
                updatedList.add(newAccount);
              }
              Navigator.pop(context);
              _saveSettings(_settings!.copyWith(
                bankAccounts: updatedList,
                hasClearedBankAccounts: false,
              ));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBankAccount(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hesabı Sil'),
        content: const Text('Bu banka hesabını ödeme seçeneklerinden silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              final updatedList = List<BankAccount>.from(_settings!.bankAccounts);
              if (index >= 0 && index < updatedList.length) {
                updatedList.removeAt(index);
                _saveSettings(_settings!.copyWith(
                  bankAccounts: updatedList,
                  hasClearedBankAccounts: updatedList.isEmpty,
                ));
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_settings == null) return const Center(child: Text('Ayarlar yüklenemedi.'));

    if (_phoneController == null) {
      _initSettingsControllers(_settings!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A) DÜKKAN TEMASI & RENK PALETİ (SADECE YÖNETİCİ DEĞİŞTİREBİLİR)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.palette_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dükkan Teması & Renk Paleti',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Dükkanınızın ve menünüzün renk atmosferini tek tıkla değiştirebilirsiniz. Sadece yöneticiler değiştirebilir ve tüm müşterilerde anında canlı olarak aktif olur.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AppThemePresets.all.map((preset) {
                          final isSelected = (_settings!.themePreset == preset.key) ||
                              (_settings!.themePreset.isEmpty && preset.key == 'classic');
                          return InkWell(
                            onTap: () {
                              _saveSettings(
                                _settings!.copyWith(themePreset: preset.key),
                                successMessage: 'Dükkan teması "${preset.name}" olarak güncellendi!',
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: isWide ? (constraints.maxWidth - 12) / 2 : double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? preset.primary.withValues(alpha: 0.08) : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? preset.primary : AppColors.cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Mini Dükkan Atmosfer Önizleme Kutusu (Arka Plan + Kart + Çerçeve)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: preset.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: preset.cardBorder, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: preset.surface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: preset.primary, width: 2),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: preset.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${preset.badge} ${preset.name}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  color: isSelected ? preset.primary : AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (preset.key == 'classic') ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryContainer,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Varsayılan',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          preset.description,
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: preset.primary, size: 22)
                                  else
                                    const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted, size: 20),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 1. TESLİMAT SEÇENEKLERİ (GEL-AL & ADRESE TESLİMAT)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teslimat Seçenekleri Yönetimi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Müşterilerin sipariş verirken kullanacağı teslimat yöntemlerini aktif/pasif yapabilir, başlık ve açıklamalarını özelleştirebilirsiniz.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),

                  // A) GEL-AL / ELDEN TESLİMAT
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Gel-Al / Elden Teslim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _settings!.isPickupActive ? 'Aktif' : 'Pasif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _settings!.isPickupActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: _settings!.isPickupActive,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (val) {
                                    _saveSettings(
                                      _settings!.copyWith(isPickupActive: val),
                                      successMessage: val ? 'Gel-Al / Elden Teslimat aktif edildi.' : 'Gel-Al / Elden Teslimat kapatıldı.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pickupTitleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Gel-Al Başlığı *',
                            hintText: 'Örn: Gel-Al / Mutfaktan Teslim',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pickupDescCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Gel-Al Açıklama & Bilgilendirme Metni *',
                            hintText: 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz...',
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // B) ADRESE TESLİMAT
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Adrese Teslimat (Kurye)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _settings!.isDeliveryActive ? 'Aktif' : 'Pasif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _settings!.isDeliveryActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: _settings!.isDeliveryActive,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (val) {
                                    _saveSettings(
                                      _settings!.copyWith(isDeliveryActive: val),
                                      successMessage: val ? 'Adrese Teslimat seçeneği aktif edildi.' : 'Adrese Teslimat seçeneği kapatıldı.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _deliveryTitleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Adrese Teslimat Başlığı *',
                            hintText: 'Örn: Adrese Teslimat (Kurye / Kargo)',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _deliveryDescCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Adrese Teslimat Açıklama Metni',
                            hintText: 'Siparişiniz adresinize özenle teslim edilir...',
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text(
                        'Teslimat Ayarlarını Kaydet',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onPressed: () {
                        _saveSettings(
                          _settings!.copyWith(
                            pickupTitle: _pickupTitleCtrl?.text.trim() ?? 'Gel-Al / Mutfaktan Teslim',
                            pickupDescription: _pickupDescCtrl?.text.trim() ?? 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
                            deliveryTitle: _deliveryTitleCtrl?.text.trim() ?? 'Adrese Teslimat (Kurye / Kargo)',
                            deliveryDescription: _deliveryDescCtrl?.text.trim() ?? 'Siparişiniz adresinize özenle teslim edilir.',
                          ),
                          successMessage: 'Teslimat yöntemleri ve açıklamaları kaydedildi!',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. ÖDEME YÖNTEMLERİ AKTİF/PASİF
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payment, color: AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ödeme Yöntemleri Seçenekleri',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  SwitchListTile(
                    title: const Text('Havale / EFT ile Ödeme'),
                    subtitle: const Text('Tanımlı banka hesaplarınıza havale/EFT ile ödeme alınır.', style: TextStyle(fontSize: 12)),
                    value: _settings!.isBankTransferActive,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) {
                      _saveSettings(
                        _settings!.copyWith(isBankTransferActive: val),
                        successMessage: val ? 'Havale/EFT ile ödeme aktif edildi.' : 'Havale/EFT ile ödeme kapatıldı.',
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Kapıda / Elden Ödeme'),
                    subtitle: const Text('Teslimat anında nakit veya anlık EFT/havale ile ödeme kabul edilir.', style: TextStyle(fontSize: 12)),
                    value: _settings!.isCodActive,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) {
                      _saveSettings(
                        _settings!.copyWith(isCodActive: val),
                        successMessage: val ? 'Kapıda/Elden ödeme aktif edildi.' : 'Kapıda/Elden ödeme kapatıldı.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. ÇOKLU BANKA HESABI & IBAN YÖNETİMİ
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.infoContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance, color: AppColors.info),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Banka Hesapları (${_settings!.bankAccounts.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ekle'),
                        onPressed: () => _showBankAccountDialog(null, null),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  if (_settings!.bankAccounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Henüz ekli banka hesabı bulunmuyor.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ..._settings!.bankAccounts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final acc = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  SelectableText(
                                    acc.iban,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                                  ),
                                  Text('Hesap Sahibi: ${acc.accountHolder}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Düzenle',
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              onPressed: () => _showBankAccountDialog(acc, idx),
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              onPressed: () => _confirmDeleteBankAccount(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. VİTRİN DEĞER ROZETLERİ (%100 Dana Eti, Taze vs.)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('🏷️', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vitrin Kartları (${_settings!.badges.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ekle'),
                        onPressed: () => _showBadgeDialog(null, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ana sayfada ürünlerin üstünde görünen özellik kartları (%100 Dana Eti, Günlük Taze vb.). İkon, başlık ve açıklamayı dilediğiniz gibi düzenleyebilirsiniz.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  if (_settings!.badges.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Henüz vitrin kartı eklenmemiş.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ..._settings!.badges.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final badge = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(badge.icon, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(badge.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (badge.subtitle.isNotEmpty)
                                    Text(badge.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Düzenle (Emoji, Başlık, Alt Metin)',
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              onPressed: () => _showBadgeDialog(badge, idx),
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              onPressed: () => _confirmDeleteBadge(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 5. ANA SAYFA ALT KARTI (HİKAYE & TANITIM BÖLÜMÜ)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.view_agenda_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ana Sayfa Alt Kartı',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _settings!.isStoryCardActive ? 'Görünür' : 'Gizli',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _settings!.isStoryCardActive ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            value: _settings!.isStoryCardActive,
                            activeThumbColor: AppColors.success,
                            onChanged: (val) {
                              _saveSettings(
                                _settings!.copyWith(isStoryCardActive: val),
                                successMessage: val ? 'Alt kart ana sayfada görünür yapıldı.' : 'Alt kart ana sayfada gizlendi.',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _settings!.isStoryCardActive
                        ? 'Alt kart şu anda ana sayfada vitrinin altında yayında.'
                        : 'Alt kart pasif hale getirildi (ana sayfada tamamen gizlendi).',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _settings!.isStoryCardActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  if (_settings!.isStoryCardActive) ...[
                    // Görsel Önizleme ve Değiştirme
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 460;
                        final imageWidget = ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ProductImage(
                            imageUrl: _storyImageCtrl?.text.isNotEmpty == true 
                                ? _storyImageCtrl!.text 
                                : 'assets/images/manti-mood-logo.png',
                            width: isNarrow ? 90 : 80,
                            height: isNarrow ? 90 : 80,
                            fit: BoxFit.contain,
                          ),
                        );
                        final controls = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_photo_alternate, size: 15),
                                  label: const Text('Görsel / Logo Seç', style: TextStyle(fontSize: 11)),
                                  onPressed: () async {
                                    final picked = await MediaUploadService.instance.pickImageForCropping();
                                    if (picked != null && context.mounted) {
                                      final cropped = await ImageCropperDialog.show(
                                        context,
                                        imageSource: picked,
                                        originalSource: picked,
                                        defaultAspectRatio: 1 / 1,
                                        title: 'Alt Kart Görselini Çerçevele',
                                      );
                                      setState(() {
                                        _storyImageCtrl?.text = cropped ?? picked;
                                      });
                                    }
                                  },
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.crop, size: 15),
                                  label: const Text('Görseli Kırp', style: TextStyle(fontSize: 11)),
                                  onPressed: () async {
                                    final current = _storyImageCtrl?.text.trim() ?? '';
                                    if (current.isNotEmpty && mounted) {
                                      final cropped = await ImageCropperDialog.show(
                                        context,
                                        imageSource: current,
                                        defaultAspectRatio: 1 / 1,
                                        title: 'Alt Kart Görselini Çerçevele',
                                      );
                                      if (cropped != null) {
                                        setState(() {
                                          _storyImageCtrl?.text = cropped;
                                        });
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _storyImageCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                labelText: 'veya Görsel URL / Dosya Yolu',
                                hintText: 'assets/images/... veya https://...',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: imageWidget),
                              const SizedBox(height: 12),
                              controls,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            imageWidget,
                            const SizedBox(width: 14),
                            Expanded(child: controls),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _storyTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alt Kart Başlığı *',
                        hintText: 'Örn: Mantı Mood Hikayesi veya Butik Mutfak',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _storyContentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alt Kart İçeriği & Hikaye Metni *',
                        hintText: 'Evimizde annelerimizin elleriyle, taptaze un ve %100 yerli dana kıymayla...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Alt Kart Ayarlarını Kaydet'),
                        onPressed: () {
                          _saveSettings(
                            _settings!.copyWith(
                              storyCardTitle: _storyTitleCtrl?.text.trim() ?? 'Mantı Mood Hikayesi',
                              storyCardContent: _storyContentCtrl?.text.trim() ?? '',
                              storyCardImageUrl: _storyImageCtrl?.text.trim() ?? 'assets/images/manti-mood-logo.png',
                            ),
                            successMessage: 'Alt kart ayarları başarıyla kaydedildi!',
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 7. DÜKKAN DUYURUSU (ANA SAYFA ÜST ŞERİT)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Duyuru',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _settings!.announcementText.trim().isNotEmpty
                              ? AppColors.successContainer
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _settings!.announcementText.trim().isNotEmpty ? '🟢 Yayında' : '⚪ Pasif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _settings!.announcementText.trim().isNotEmpty
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ana sayfanın en üstünde müşterilerinize gösterilecek duyuru şerididir. Kaydettiğiniz metin, sayfa yenilense veya tarayıcı kapatılsa dahi kalıcı olarak sabit kalır. Duyuruyu kaldırmak için metni silip kaydetmeniz veya "Duyuruyu Temizle" butonuna basmanız yeterlidir.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  TextField(
                    controller: _announcementController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Duyuru Metni',
                      hintText: 'Örn: Bayram boyunca her gün taze mantı servisi mutfaktan devam ediyor!',
                    ),
                    onChanged: (val) {
                      setState(() {
                        _settings = _settings!.copyWith(announcementText: val);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.campaign, size: 18),
                        label: const Text('Duyuruyu Kaydet & Yayınla'),
                        onPressed: () {
                          final text = _announcementController?.text.trim() ?? '';
                          _saveSettings(
                            _settings!.copyWith(announcementText: text),
                            clearAnnouncement: text.isEmpty,
                            successMessage: text.isNotEmpty
                                ? 'Duyuru başarıyla kaydedildi ve ana sayfada sabitlendi!'
                                : 'Duyuru metni boş olduğu için duyuru kaldırıldı.',
                          );
                        },
                      ),
                      if (_announcementController?.text.trim().isNotEmpty == true || _settings!.announcementText.trim().isNotEmpty)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Duyuruyu Temizle'),
                          onPressed: () {
                            _announcementController?.clear();
                            _saveSettings(
                              _settings!.copyWith(announcementText: ''),
                              clearAnnouncement: true,
                              successMessage: 'Duyuru kaldırıldı.',
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 8. GENEL DÜKKAN & İLETİŞİM BİLGİLERİ
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dükkan & İletişim Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'WhatsApp Sipariş Hattı', hintText: '905xxxxxxxxx'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min. Sipariş Tutarı (₺)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Dükkan Sipariş Alıyor mu?'),
                    subtitle: Text(_settings!.isOpen ? 'Açık: Müşteriler sipariş verebilir.' : 'Kapalı: Sipariş alımı geçici durduruldu.'),
                    value: _settings!.isOpen,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) {
                      _saveSettings(
                        _settings!.copyWith(isOpen: val),
                        successMessage: val ? 'Dükkan sipariş alımına açıldı.' : 'Dükkan sipariş alımı geçici durduruldu.',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('"Satıcıya Sor" Butonu (WhatsApp)'),
                    subtitle: Text(_settings!.isAskSellerActive
                        ? 'Aktif: Üst barda müşteriler için "Satıcıya Sor" butonu gösterilir.'
                        : 'Pasif: Buton gizlenir.'),
                    value: _settings!.isAskSellerActive,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) {
                      _saveSettings(
                        _settings!.copyWith(isAskSellerActive: val),
                        successMessage: val ? '"Satıcıya Sor" butonu aktif edildi.' : '"Satıcıya Sor" butonu kapatıldı.',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('İletişim & Dükkan Bilgilerini Kaydet'),
                      onPressed: () {
                        _saveSettings(
                          _settings!.copyWith(
                            whatsappNumber: _phoneController?.text.trim() ?? '905551234567',
                            minOrderAmount: double.tryParse(_minOrderController?.text ?? '200') ?? 200.0,
                          ),
                          successMessage: 'İletişim ve dükkan bilgileri kaydedildi!',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 9. TÜM DÜKKAN AYARLARINI TEK TIKLA KAYDETME
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              icon: const Icon(Icons.done_all, size: 22),
              label: const Text(
                'Tüm Dükkan Ayarlarını Kaydet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              onPressed: _saveAllSettings,
            ),
          ),

          // 9. YEDEKLEME & VERİLERİ DIŞA AKTARMA (JSON)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.backup_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Verileri Dışa Aktar & Yedekle (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.cardBorder, height: 24),
                  const Text(
                    'Panelde güncellediğiniz tüm ürünleri, yeni fiyatları, porsiyon seçeneklerini, fotoğrafları, vitrin kartlarını ve dükkan ayarlarını tek tıkla JSON formatında dışa aktarabilirsiniz.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text(
                      'Tüm Verileri Dışa Aktar (JSON)',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onPressed: _exportAllDataDialog,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _exportAllDataDialog() {
    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'store_settings': _settings?.toJson() ?? {},
      'products': _products.map((p) => p.toJson()).toList(),
      'banners': _banners.map((b) => b.toJson()).toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final ctrl = TextEditingController(text: jsonStr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.download_for_offline, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dükkan Verilerini Dışa Aktar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panelde düzenlediğiniz tüm ürünler, fiyatlar, porsiyonlar, vitrin kartları ve dükkan ayarları bu JSON verisinin içindedir. Kopyalayarak yedekleyebilir veya geliştiricinize iletebilirsiniz:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 260,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: ctrl,
                  readOnly: true,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Panoya Kopyala'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm dükkan verileri ve ayarları panoya kopyalandı!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return AppColors.warning;
      case 'preparing':
        return Colors.orange;
      case 'ready':
      case 'on_the_way':
        return AppColors.info;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}

class _VariantEditorItem {
  final TextEditingController titleCtrl;
  final TextEditingController priceCtrl;

  _VariantEditorItem({required String title, required double price})
      : titleCtrl = TextEditingController(text: title),
        priceCtrl = TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : '');
}
