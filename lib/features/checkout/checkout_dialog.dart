import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/order.dart';
import '../../core/models/store_settings.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../legal/legal_dialogs.dart';

class CheckoutDialog extends StatefulWidget {
  final StoreSettings? storeSettings;

  const CheckoutDialog({super.key, this.storeSettings});

  static Future<void> show(BuildContext context, {StoreSettings? storeSettings}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckoutDialog(storeSettings: storeSettings),
    );
  }

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

const List<String> _turkeyProvinces = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin',
  'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
  'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan',
  'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Isparta',
  'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir',
  'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla',
  'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt',
  'Sinop', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak',
  'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman',
  'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye',
  'Düzce'
];

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCity;
  String _deliveryMethod = 'pickup'; // 'pickup' | 'delivery'
  String _paymentMethod = 'bank_transfer'; // 'bank_transfer' | 'cod'
  String _codType = 'cash'; // 'cash' | 'instant_eft'
  bool _agreedKvkk = true;
  bool _agreedSales = true;
  bool _isLoading = false;
  StoreSettings? _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.storeSettings ?? SupabaseService.instance.currentSettings;
    _initDeliveryAndPayment();
    SupabaseService.instance.settingsNotifier.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) {
      final s = SupabaseService.instance.settingsNotifier.value;
      if (s != null) {
        setState(() {
          _settings = s;
          _initDeliveryAndPayment();
        });
      }
    }
  }

  void _initDeliveryAndPayment() {
    final s = _settings;
    if (s != null) {
      if (s.isDeliveryActive && !s.isPickupActive) {
        _deliveryMethod = 'delivery';
      } else if (!s.isDeliveryActive && s.isPickupActive) {
        _deliveryMethod = 'pickup';
      } else if (s.isDeliveryActive && s.isPickupActive) {
        if (_deliveryMethod != 'delivery' && _deliveryMethod != 'pickup') {
          _deliveryMethod = 'pickup';
        }
      }
      if (!s.isBankTransferActive && s.isCodActive) {
        _paymentMethod = 'cod';
      } else if (s.isBankTransferActive && !s.isCodActive) {
        _paymentMethod = 'bank_transfer';
      }
    }
  }

  @override
  void dispose() {
    SupabaseService.instance.settingsNotifier.removeListener(_onSettingsChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final s = _settings;
    if (s != null && !s.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dükkanımız şu anda sipariş alımına kapalıdır.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (s != null && !s.isDeliveryActive && !s.isPickupActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şu anda aktif bir teslimat yöntemi bulunmamaktadır.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (s != null && !s.isBankTransferActive && !s.isCodActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şu anda aktif bir ödeme yöntemi bulunmamaktadır.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (!_agreedKvkk || !_agreedSales) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yasal sözleşmeleri onaylayınız.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cart = CartController.instance;
    final orderItems = cart.items.map((cartItem) {
      return OrderItemModel(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        variantTitle: cartItem.variant.title,
        quantity: cartItem.quantity,
        unitPrice: cartItem.variant.price,
        subtotal: cartItem.subtotal,
      );
    }).toList();

    final isDelivery = _deliveryMethod == 'delivery';
    final deliveryCity = isDelivery ? (_selectedCity ?? '-') : '-';
    final deliveryDistrict = isDelivery ? _districtController.text.trim() : '-';
    final pickupName = widget.storeSettings?.pickupTitle.isNotEmpty == true 
        ? widget.storeSettings!.pickupTitle 
        : 'Gel-Al / Elden Teslim';
    final deliveryAddress = isDelivery 
        ? _addressController.text.trim() 
        : 'Gel-Al / Elden Teslim ($pickupName)';

    final order = await SupabaseService.instance.createOrder(
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      deliveryCity: deliveryCity,
      deliveryDistrict: deliveryDistrict,
      deliveryAddress: deliveryAddress,
      paymentMethod: _paymentMethod,
      codType: _codType,
      totalAmount: cart.totalPrice,
      customerNote: _noteController.text.trim(),
      items: orderItems,
    );

    setState(() => _isLoading = false);

    if (order != null) {
      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } catch (_) {}
      cart.clear();
      Navigator.pop(context); // Dialogu kapat
      _showSuccessDialog(order);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(OrderModel order) {
    HapticFeedback.mediumImpact();
    final settings = widget.storeSettings;
    final whatsapp = settings?.whatsappNumber ?? '905551234567';
    final accounts = settings?.bankAccounts.isNotEmpty == true
        ? settings!.bankAccounts
        : [
            BankAccount(
              bankName: settings?.bankName.isNotEmpty == true ? settings!.bankName : 'Ziraat Bankası',
              iban: settings?.iban.isNotEmpty == true ? settings!.iban : 'TR12 0006 2000 0000 1234 5678 90',
              accountHolder: settings?.accountHolder.isNotEmpty == true ? settings!.accountHolder : 'Mantı Mood',
            ),
          ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
              ),
              const SizedBox(height: 18),
              Text(
                'Siparişiniz Alındı!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sipariş Takip Numaranız:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Sipariş Numarasını Kopyala',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.orderNumber));
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
              ),
              const SizedBox(height: 16),
              if (order.paymentMethod == 'bank_transfer') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Havale / EFT için Banka Hesapları:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...accounts.map((acc) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.bankName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                SelectableText(
                                  acc.iban,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                                ),
                                Text(
                                  'Alıcı: ${acc.accountHolder}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const Divider(height: 12),
                              ],
                            ),
                          )),
                      const Text(
                        'Lütfen transfer açıklamasına sipariş takip numaranızı ekleyiniz.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Toplam Tutar: ${order.totalAmount.toStringAsFixed(0)} ₺',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp ile Bilgi / Onay Bildir'),
                onPressed: () async {
                  final message = Uri.encodeComponent(
                    'Merhaba Mantı Mood! Siparişimi verdim.\n'
                    'Sipariş Kodu: ${order.orderNumber}\n'
                    'Tutar: ${order.totalAmount.toStringAsFixed(0)} ₺\n'
                    'Adım: ${order.customerName}',
                  );
                  final uri = Uri.parse('https://wa.me/$whatsapp?text=$message');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam, Teşekkürler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final settings = _settings ?? widget.storeSettings ?? SupabaseService.instance.currentSettings;

    final isNarrow = MediaQuery.of(context).size.width < 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        padding: EdgeInsets.all(isNarrow ? 16 : 24),
        child: Form(
          key: _formKey,
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
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Siparişi Tamamla',
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
              const SizedBox(height: 8),

              // Form Alanları (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İletişim Bilgileri
                      const Text(
                        'İletişim Bilgileri',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Adınız Soyadınız *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Lütfen adınızı giriniz' : null,
                      ),
                      const SizedBox(height: 12),
                      if (isNarrow) ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası *',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '05xx xxx xx xx',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Lütfen telefon numarası giriniz';
                            }
                            final digits = v.replaceAll(RegExp(r'\D'), '');
                            if (digits.length == 10 && digits.startsWith('5')) return null;
                            if (digits.length == 11 && digits.startsWith('05')) return null;
                            if (digits.length == 12 && digits.startsWith('905')) return null;
                            return 'Geçerli bir cep telefonu giriniz (05xx xxx xx xx)';
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-posta (İsteğe Bağlı)',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Geçerli bir e-posta adresi giriniz';
                              }
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefon Numarası *',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  hintText: '05xx xxx xx xx',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Lütfen telefon numarası giriniz';
                                  }
                                  final digits = v.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length == 10 && digits.startsWith('5')) return null;
                                  if (digits.length == 11 && digits.startsWith('05')) return null;
                                  if (digits.length == 12 && digits.startsWith('905')) return null;
                                  return 'Geçerli bir cep telefonu giriniz (05xx xxx xx xx)';
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'E-posta (İsteğe Bağlı)',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v != null && v.trim().isNotEmpty) {
                                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                    if (!emailRegex.hasMatch(v.trim())) {
                                      return 'Geçerli bir e-posta adresi giriniz';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Teslimat Bölümü (Yönetici Aktif/Pasif Kontrolü)
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Teslimat Yöntemi',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Spacer(),
                          if ((settings?.isDeliveryActive ?? false) && (settings?.isPickupActive ?? true))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('2 Seçenek Mevcut', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if ((settings?.isDeliveryActive ?? false) && (settings?.isPickupActive ?? true)) ...[
                        // Hem Adrese Teslimat hem Gel-Al aktif: Müşteri seçim yapabilir
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _deliveryMethod = 'pickup'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: _deliveryMethod == 'pickup' ? AppColors.primaryContainer.withValues(alpha: 0.6) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _deliveryMethod == 'pickup' ? AppColors.primary : AppColors.cardBorder,
                                      width: _deliveryMethod == 'pickup' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _deliveryMethod == 'pickup' ? Icons.radio_button_checked : Icons.radio_button_off,
                                        size: 18,
                                        color: _deliveryMethod == 'pickup' ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          settings?.pickupTitle.isNotEmpty == true ? settings!.pickupTitle : 'Gel-Al / Elden Teslim',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _deliveryMethod == 'pickup' ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _deliveryMethod = 'delivery'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: _deliveryMethod == 'delivery' ? AppColors.primaryContainer.withValues(alpha: 0.6) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _deliveryMethod == 'delivery' ? AppColors.primary : AppColors.cardBorder,
                                      width: _deliveryMethod == 'delivery' ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _deliveryMethod == 'delivery' ? Icons.radio_button_checked : Icons.radio_button_off,
                                        size: 18,
                                        color: _deliveryMethod == 'delivery' ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          settings?.deliveryTitle.isNotEmpty == true ? settings!.deliveryTitle : 'Adrese Teslimat',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _deliveryMethod == 'delivery' ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (!(settings?.isDeliveryActive ?? false) && !(settings?.isPickupActive ?? true)) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Şu anda aktif teslimat yöntemi bulunmamaktadır.',
                                  style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_deliveryMethod == 'pickup') ...[
                        // GEL-AL / ELDEN TESLİM KARTI (YÖNETİCİ DÜZENLENEBİLİR)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings?.pickupTitle.isNotEmpty == true
                                          ? settings!.pickupTitle
                                          : 'Teslimat Yöntemi: Gel-Al / Mutfaktan Teslim',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings?.pickupDescription.isNotEmpty == true
                                          ? settings!.pickupDescription
                                          : 'Siparişiniz taze açılıp hazırlandığında elden teslim alabilirsiniz. Adres bilgisi gerekmemektedir.',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // ADRESE TESLİMAT KARTI (BAŞLIK & AÇIKLAMA)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings?.deliveryTitle.isNotEmpty == true
                                          ? settings!.deliveryTitle
                                          : 'Teslimat Yöntemi: Adrese Teslimat',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                    if (settings?.deliveryDescription.isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        settings!.deliveryDescription,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ADRESE TESLİMAT AKTİF: 81 İL, İLÇE VE AÇIK ADRES
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'İl Seçiniz *',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: _turkeyProvinces.map((city) {
                            return DropdownMenuItem(value: city, child: Text(city));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCity = val),
                          validator: (v) => v == null || v.isEmpty ? 'Lütfen il seçiniz' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _districtController,
                          decoration: const InputDecoration(
                            labelText: 'İlçe / Semt *',
                            prefixIcon: Icon(Icons.location_city_outlined),
                            hintText: 'İlçe adı giriniz',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Lütfen ilçe belirtiniz' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Açık Teslimat Adresi *',
                            prefixIcon: Icon(Icons.home_outlined),
                            hintText: 'Mahalle, Cadde, Sokak, No, Daire...',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Lütfen açık adres giriniz' : null,
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Sipariş Notu (İsteğe Bağlı)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Ödeme Yöntemi Seçimi
                      const Text(
                        'Ödeme Yöntemi Seçiniz',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),

                      if (!(settings?.isBankTransferActive ?? true) && !(settings?.isCodActive ?? true))
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Şu anda aktif ödeme yöntemi bulunmamaktadır.',
                                  style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 1. Havale / EFT
                      if (settings?.isBankTransferActive ?? true) ...[
                        _buildPaymentOption(
                          title: 'Havale / EFT (Banka Hesabına)',
                          subtitle: 'Sipariş sonrası belirtilen IBAN adresine havale',
                          icon: Icons.account_balance,
                          value: 'bank_transfer',
                          isSelected: _paymentMethod == 'bank_transfer',
                          onTap: () => setState(() => _paymentMethod = 'bank_transfer'),
                        ),
                        if (_paymentMethod == 'bank_transfer') ...[
                          Container(
                            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...(settings?.bankAccounts.isNotEmpty == true
                                        ? settings!.bankAccounts
                                        : [
                                            BankAccount(
                                              bankName: settings?.bankName.isNotEmpty == true ? settings!.bankName : 'Ziraat Bankası',
                                              iban: settings?.iban.isNotEmpty == true ? settings!.iban : 'TR12 0006 2000 0000 1234 5678 90',
                                              accountHolder: settings?.accountHolder.isNotEmpty == true ? settings!.accountHolder : 'Mantı Mood',
                                            ),
                                          ])
                                    .map((acc) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                acc.bankName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              SelectableText(
                                                acc.iban,
                                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                                              ),
                                              Text(
                                                'Alıcı: ${acc.accountHolder}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'IBAN Kopyala',
                                          icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: acc.iban.replaceAll(' ', '')));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${acc.bankName} IBAN kopyalandı!')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],

                      // 2. Kapıda / Elden Ödeme
                      if (settings?.isCodActive ?? true) ...[
                        _buildPaymentOption(
                          title: 'Kapıda / Elden Ödeme',
                          subtitle: 'Teslimat anında nakit veya anlık EFT/havale ile ödeme',
                          icon: Icons.handshake_outlined,
                          value: 'cod',
                          isSelected: _paymentMethod == 'cod',
                          onTap: () => setState(() => _paymentMethod = 'cod'),
                        ),
                        if (_paymentMethod == 'cod') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Kapıda Nakit Ödeme'),
                                  selected: _codType == 'cash',
                                  onSelected: (s) => setState(() => _codType = 'cash'),
                                ),
                                ChoiceChip(
                                  label: const Text('Anlık Havale / EFT'),
                                  selected: _codType == 'instant_eft',
                                  onSelected: (s) => setState(() => _codType = 'instant_eft'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),

                      // Yasal Onay Kutuları
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedKvkk,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _agreedKvkk = v ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => LegalDialogs.showKvkkDialog(context),
                              child: const Text.rich(
                                TextSpan(
                                  text: 'KVKK Aydınlatma Metni',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '\'ni okudum, onaylıyorum.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedSales,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _agreedSales = v ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => LegalDialogs.showTermsOfService(context),
                              child: const Text.rich(
                                TextSpan(
                                  text: 'Mesafeli Satış Sözleşmesi',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '\'ni okudum, kabul ediyorum.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.cardBorder),

              // Toplam & Onayla Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Toplam Tutar',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${cart.totalPrice.toStringAsFixed(0)} ₺',
                          style: TextStyle(
                            fontSize: isNarrow ? 19 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (_isLoading ||
                            !(settings?.isOpen ?? true) ||
                            (!(settings?.isDeliveryActive ?? false) && !(settings?.isPickupActive ?? true)) ||
                            (!(settings?.isBankTransferActive ?? true) && !(settings?.isCodActive ?? true)))
                        ? null
                        : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 18 : 28, vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text((settings?.isOpen ?? true) ? 'Siparişi Onayla' : 'Dükkan Kapalı'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
