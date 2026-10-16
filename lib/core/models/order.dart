class OrderItemModel {
  final String? id;
  final String? productId;
  final String productName;
  final String variantTitle;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemModel({
    this.id,
    this.productId,
    required this.productName,
    required this.variantTitle,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String?,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      variantTitle: json['variant_title'] as String? ?? '1 Kg',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'variant_title': variantTitle,
    'quantity': quantity,
    'unit_price': unitPrice,
    'subtotal': subtotal,
  };
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String? userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryCity;
  final String deliveryDistrict;
  final String deliveryAddress;
  final String paymentMethod; // 'bank_transfer' | 'cod'
  final String codType; // 'cash' | 'pos'
  final String status; // 'order_received', 'pending_payment', 'payment_received', 'preparing', 'ready', 'shipped', 'delivered', 'cancelled'
  final List<String> statusSteps;
  final double totalAmount;
  final String customerNote;
  final bool invoiceSent;
  final DateTime? invoiceSentAt;
  final String trackingCode;
  final String carrierCompany;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryCity,
    required this.deliveryDistrict,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.codType,
    required this.status,
    this.statusSteps = const ['order_received'],
    required this.totalAmount,
    required this.customerNote,
    required this.invoiceSent,
    this.invoiceSentAt,
    required this.trackingCode,
    required this.carrierCompany,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<OrderItemModel>? items}) {
    final status = json['status'] as String? ?? 'order_received';
    final paymentMethod = json['payment_method'] as String? ?? 'bank_transfer';
    final rawSteps = json['status_steps'];
    final steps = (rawSteps is List)
        ? rawSteps.map((e) => e.toString()).toList()
        : inferDefaultStatusSteps(status, paymentMethod);

    return OrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      userId: json['user_id'] as String?,
      customerName: json['customer_name'] as String? ?? '',
      customerEmail: json['customer_email'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      deliveryCity: json['delivery_city'] as String? ?? 'İstanbul',
      deliveryDistrict: json['delivery_district'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      paymentMethod: paymentMethod,
      codType: json['cod_type'] as String? ?? 'cash',
      status: status,
      statusSteps: steps.isEmpty ? ['order_received'] : steps,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      customerNote: json['customer_note'] as String? ?? '',
      invoiceSent: json['invoice_sent'] as bool? ?? false,
      invoiceSentAt: json['invoice_sent_at'] != null 
          ? DateTime.tryParse(json['invoice_sent_at'])?.toLocal()
          : null,
      trackingCode: json['tracking_code'] as String? ?? '',
      carrierCompany: json['carrier_company'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      items: items ?? (json['items'] is List
          ? (json['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map((i) => OrderItemModel.fromJson(i))
              .toList()
          : []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'user_id': userId,
    'customer_name': customerName,
    'customer_email': customerEmail,
    'customer_phone': customerPhone,
    'delivery_city': deliveryCity,
    'delivery_district': deliveryDistrict,
    'delivery_address': deliveryAddress,
    'payment_method': paymentMethod,
    'cod_type': codType,
    'status': status,
    'status_steps': statusSteps,
    'total_amount': totalAmount,
    'customer_note': customerNote,
    'invoice_sent': invoiceSent,
    'invoice_sent_at': invoiceSentAt?.toIso8601String(),
    'tracking_code': trackingCode,
    'carrier_company': carrierCompany,
    'created_at': createdAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  String get statusTitle {
    switch (status) {
      case 'order_received':
        return 'Sipariş Alındı';
      case 'pending_payment':
        return 'Ödeme Bekleniyor';
      case 'payment_received':
        return 'Ödeme Alındı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazırlandı';
      case 'shipped':
      case 'on_the_way':
        return 'Kargoda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Sipariş Alındı';
    }
  }

  String get paymentMethodLabel {
    if (paymentMethod == 'bank_transfer') {
      return 'Havale / EFT';
    }
    if (codType == 'instant_eft') {
      return 'Kapıda Ödeme (Anlık Havale / EFT)';
    }
    if (codType == 'pos') {
      return 'Kapıda Ödeme (Kredi Kartı / POS)';
    }
    return 'Kapıda Ödeme (Nakit)';
  }

  /// Kamu ve misafir sipariş sorgulamalarında müşteri kişisel verilerini (KVKK) maskeler.
  OrderModel toPublicMasked() {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      userId: null,
      customerName: maskCustomerName(customerName),
      customerEmail: maskCustomerEmail(customerEmail),
      customerPhone: maskCustomerPhone(customerPhone),
      deliveryCity: deliveryCity,
      deliveryDistrict: deliveryDistrict,
      deliveryAddress: maskDeliveryAddress(deliveryAddress, deliveryDistrict, deliveryCity),
      paymentMethod: paymentMethod,
      codType: codType,
      status: status,
      statusSteps: statusSteps,
      totalAmount: totalAmount,
      customerNote: '', // Özel kapı şifresi veya notların sızmasını önlemek için gizli
      invoiceSent: invoiceSent,
      invoiceSentAt: invoiceSentAt,
      trackingCode: trackingCode,
      carrierCompany: carrierCompany,
      createdAt: createdAt,
      items: items,
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? deliveryCity,
    String? deliveryDistrict,
    String? deliveryAddress,
    String? paymentMethod,
    String? codType,
    String? status,
    List<String>? statusSteps,
    double? totalAmount,
    String? customerNote,
    bool? invoiceSent,
    DateTime? invoiceSentAt,
    String? trackingCode,
    String? carrierCompany,
    DateTime? createdAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryDistrict: deliveryDistrict ?? this.deliveryDistrict,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      codType: codType ?? this.codType,
      status: status ?? this.status,
      statusSteps: statusSteps ?? this.statusSteps,
      totalAmount: totalAmount ?? this.totalAmount,
      customerNote: customerNote ?? this.customerNote,
      invoiceSent: invoiceSent ?? this.invoiceSent,
      invoiceSentAt: invoiceSentAt ?? this.invoiceSentAt,
      trackingCode: trackingCode ?? this.trackingCode,
      carrierCompany: carrierCompany ?? this.carrierCompany,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  static List<String> inferDefaultStatusSteps(String? status, String? paymentMethod) {
    final s = status ?? 'order_received';
    final isTransfer = paymentMethod == 'bank_transfer';

    if (s == 'cancelled') {
      return ['order_received', 'cancelled'];
    }
    if (s == 'delivered') {
      return isTransfer
          ? ['order_received', 'pending_payment', 'payment_received', 'preparing', 'ready', 'shipped', 'delivered']
          : ['order_received', 'preparing', 'ready', 'shipped', 'delivered'];
    }
    if (s == 'shipped' || s == 'on_the_way') {
      return isTransfer
          ? ['order_received', 'pending_payment', 'payment_received', 'preparing', 'ready', 'shipped']
          : ['order_received', 'preparing', 'ready', 'shipped'];
    }
    if (s == 'ready') {
      return isTransfer
          ? ['order_received', 'pending_payment', 'payment_received', 'preparing', 'ready']
          : ['order_received', 'preparing', 'ready'];
    }
    if (s == 'preparing') {
      return isTransfer
          ? ['order_received', 'pending_payment', 'payment_received', 'preparing']
          : ['order_received', 'preparing'];
    }
    if (s == 'payment_received') {
      return ['order_received', 'pending_payment', 'payment_received'];
    }
    if (s == 'pending_payment') {
      return ['order_received', 'pending_payment'];
    }
    return ['order_received'];
  }

  static String calculatePrimaryStatus(List<String> steps, {String? fallback}) {
    if (steps.contains('cancelled')) return 'cancelled';
    if (steps.contains('delivered')) return 'delivered';
    if (steps.contains('shipped') || steps.contains('on_the_way')) return 'shipped';
    if (steps.contains('ready')) return 'ready';
    if (steps.contains('preparing')) return 'preparing';
    if (steps.contains('payment_received')) return 'payment_received';
    if (steps.contains('pending_payment')) return 'pending_payment';
    return fallback ?? 'order_received';
  }

  static String maskCustomerName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '***';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.map((part) {
      if (part.isEmpty) return '';
      if (part.length <= 2) return '${part[0]}*';
      return '${part[0]}${'*' * (part.length - 1)}';
    }).join(' ');
  }

  static String maskCustomerPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 7) return '***';
    if (clean.length == 10) {
      return '0${clean.substring(0, 2)}* *** ** ${clean.substring(8)}';
    } else if (clean.length == 11 && clean.startsWith('0')) {
      return '${clean.substring(0, 3)}* *** ** ${clean.substring(9)}';
    } else if (clean.length >= 12 && clean.startsWith('90')) {
      return '+90 ${clean.substring(2, 4)}* *** ** ${clean.substring(10)}';
    }
    return '${clean.substring(0, 2)}***${clean.substring(clean.length - 2)}';
  }

  static String maskCustomerEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return '***';
    final parts = trimmed.split('@');
    final user = parts[0];
    final domain = parts.sublist(1).join('@');
    if (user.length <= 2) {
      return '${user.isNotEmpty ? user[0] : '*'}*@$domain';
    }
    return '${user.substring(0, 2)}${'*' * (user.length - 2)}@$domain';
  }

  static String maskDeliveryAddress(String address, String district, String city) {
    final lower = address.trim().toLowerCase();
    if (lower.contains('mutfaktan') || lower.contains('gel-al') || lower.contains('gel al') || lower.contains('elden teslim')) {
      return 'Mutfaktan Teslim (Gel-Al)';
    }
    final locationParts = [district, city].where((s) => s.trim().isNotEmpty).toList();
    if (locationParts.isNotEmpty) {
      return '${locationParts.join(" / ")} (Açık adres güvenlik gereği gizlenmiştir)';
    }
    return 'Güvenlik gereği açık adres gizlenmiştir';
  }
}
