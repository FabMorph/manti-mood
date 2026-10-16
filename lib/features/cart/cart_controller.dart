import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/product.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    this.quantity = 1,
  });

  double get subtotal => variant.price * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'variant': variant.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      variant: ProductVariant.fromJson(Map<String, dynamic>.from(json['variant'] as Map)),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartController extends ChangeNotifier {
  static const String storageKey = 'mm_persistent_cart_v1';
  static final CartController instance = CartController._internal();

  CartController._internal() {
    loadFromStorage();
  }

  final List<CartItem> _items = [];
  bool _isLoaded = false;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = <CartItem>[];
          for (final entry in decoded) {
            if (entry is Map) {
              loaded.add(CartItem.fromJson(Map<String, dynamic>.from(entry)));
            }
          }
          // Eğer yükleme tamamlanana kadar kullanıcı yeni ürün eklemediyse doğrudan yükle
          if (_items.isEmpty && loaded.isNotEmpty) {
            _items.addAll(loaded);
            notifyListeners();
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading cart from local storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(storageKey);
      } else {
        final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
        await prefs.setString(storageKey, encoded);
      }
    } catch (e) {
      debugPrint('Error saving cart to local storage: $e');
    }
  }

  void addItem(Product product, ProductVariant variant, {int quantity = 1}) {
    HapticFeedback.lightImpact();
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.variant.title == variant.title,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        variant: variant,
        quantity: quantity,
      ));
    }
    _saveToStorage();
    notifyListeners();
  }

  void increment(CartItem item) {
    HapticFeedback.lightImpact();
    item.quantity++;
    _saveToStorage();
    notifyListeners();
  }

  void decrement(CartItem item) {
    HapticFeedback.lightImpact();
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    _saveToStorage();
    notifyListeners();
  }

  void removeItem(CartItem item) {
    HapticFeedback.mediumImpact();
    _items.remove(item);
    _saveToStorage();
    notifyListeners();
  }

  void clear() {
    HapticFeedback.mediumImpact();
    _items.clear();
    _saveToStorage();
    notifyListeners();
  }

  bool get isLoaded => _isLoaded;
}
