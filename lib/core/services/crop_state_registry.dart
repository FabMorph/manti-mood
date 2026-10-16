import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir görselin kırpılma geçmişi, orijinal yüksek çözünürlüklü kaynağı ve uygulanan zoom/rotasyon/matrix verileri
class CropState {
  final String originalSource;
  final double scale;
  final int rotationQuarterTurns;
  final Matrix4? transformMatrix;
  final double aspectRatio;
  final DateTime timestamp;

  const CropState({
    required this.originalSource,
    required this.scale,
    this.rotationQuarterTurns = 0,
    this.transformMatrix,
    this.aspectRatio = 4 / 3,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'originalSource': originalSource,
    'scale': scale,
    'rotationQuarterTurns': rotationQuarterTurns,
    'aspectRatio': aspectRatio,
    'matrix': transformMatrix != null ? List<double>.from(transformMatrix!.storage) : null,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CropState.fromJson(Map<String, dynamic> json) {
    Matrix4? matrix;
    if (json['matrix'] is List) {
      try {
        final list = (json['matrix'] as List).map((e) => (e as num).toDouble()).toList();
        if (list.length == 16) {
          matrix = Matrix4.fromList(list);
        }
      } catch (_) {}
    }
    return CropState(
      originalSource: json['originalSource'] as String? ?? '',
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotationQuarterTurns: (json['rotationQuarterTurns'] as num?)?.toInt() ?? 0,
      transformMatrix: matrix,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? (4 / 3),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Kırpma durumlarını ve orijinal (master) fotoğrafları yöneten merkezi kayıt yöneticisi (Registry).
/// Bu sayede görsel daha önce %400 zoom ile kırpılmış olsa dahi, kullanıcı tekrar ayarlamaya girdiğinde:
/// 1. Asla kırpılmış kalitesiz görsel açılmaz, ORİJİNAL yüksek çözünürlüklü görsel açılır.
/// 2. Sayaç %100'e sıfırlanmaz, önceki ayarı (%400) algılar ve slayderi oraya çeker.
/// 3. Kullanıcı isterse %400'den %100'e veya %50'ye rahatça uzaklaşabilir (zoom out yapabilir).
/// 4. Resmin doğallığı ve netliği asla bozulmaz (tahribatsız / non-destructive düzenleme).
class CropStateRegistry {
  static final CropStateRegistry instance = CropStateRegistry._internal();
  CropStateRegistry._internal() {
    _loadFromPreferences();
  }

  static const String _prefKey = 'mm_crop_state_registry_v1';
  static final Map<String, CropState> _registry = {};
  static bool _prefsLoaded = false;

  /// Kırpma işlemini kaydeder ve çıktı görseli ile ana görseli birbirine bağlar
  static void register({
    required String originalSource,
    required String croppedResult,
    required double scale,
    int rotationQuarterTurns = 0,
    Matrix4? transformMatrix,
    double aspectRatio = 4 / 3,
  }) {
    final orig = originalSource.trim();
    final result = croppedResult.trim();
    if (orig.isEmpty || result.isEmpty) return;

    // Eğer originalSource zaten daha önceki bir kırpmaysa, en baştaki asıl kaynağı bul
    final rootMaster = _registry[orig]?.originalSource.isNotEmpty == true
        ? _registry[orig]!.originalSource
        : orig;

    final state = CropState(
      originalSource: rootMaster,
      scale: scale,
      rotationQuarterTurns: rotationQuarterTurns,
      transformMatrix: transformMatrix != null ? Matrix4.copy(transformMatrix) : null,
      aspectRatio: aspectRatio,
      timestamp: DateTime.now(),
    );

    _registry[result] = state;
    _registry[rootMaster] = state;
    if (orig != rootMaster) {
      _registry[orig] = state;
    }

    _persistToPreferences(result, state);
  }

  /// Verilen görselin orijinal/ana kaynağını döndürür. Kayıtlı değilse kendisini döndürür.
  static String getOriginalSource(String source) {
    final clean = source.trim();
    if (clean.isEmpty) return '';
    final state = _registry[clean];
    if (state != null && state.originalSource.isNotEmpty) {
      return state.originalSource;
    }
    return clean;
  }

  /// Verilen görsel için daha önce kaydedilmiş zoom oranını döndürür (Varsayılan 1.0)
  static double getSavedScale(String source) {
    final clean = source.trim();
    if (clean.isEmpty) return 1.0;
    return _registry[clean]?.scale ?? 1.0;
  }

  /// Verilen görsel için daha önce kaydedilmiş 90 derece döndürme sayısını döndürür
  static int getSavedRotation(String source) {
    final clean = source.trim();
    if (clean.isEmpty) return 0;
    return _registry[clean]?.rotationQuarterTurns ?? 0;
  }

  /// Verilen görsel için daha önce kaydedilmiş dönüşüm matrisini döndürür
  static Matrix4? getSavedMatrix(String source) {
    final clean = source.trim();
    if (clean.isEmpty) return null;
    return _registry[clean]?.transformMatrix;
  }

  /// Kayıtlı tam CropState nesnesini döndürür
  static CropState? getCropState(String source) {
    final clean = source.trim();
    return _registry[clean];
  }

  /// Görselin daha önce kırpılmış olup olmadığını ve orijinal ana kaynağının bulunup bulunmadığını kontrol eder
  static bool hasMaster(String source) {
    final clean = source.trim();
    final state = _registry[clean];
    return state != null && state.originalSource != clean;
  }

  /// URL bazlı hafif kayıtları SharedPreferences'e kalıcı olarak kaydeder (Base64'ler bellek içi tutulur)
  static Future<void> _persistToPreferences(String key, CropState state) async {
    // Büyük Base64 dizgilerini LocalStorage'ı şişirmemek için bellekte tutuyoruz, sadece URL ve dosya yollarını kaydediyoruz
    if (key.startsWith('data:') || state.originalSource.startsWith('data:')) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentJson = prefs.getString(_prefKey);
      Map<String, dynamic> map = {};
      if (currentJson != null) {
        try {
          map = Map<String, dynamic>.from(jsonDecode(currentJson));
        } catch (_) {}
      }
      map[key] = state.toJson();
      // En son 50 kaydı sakla
      if (map.length > 50) {
        final keysToRemove = map.keys.take(map.length - 50).toList();
        for (final k in keysToRemove) {
          map.remove(k);
        }
      }
      await prefs.setString(_prefKey, jsonEncode(map));
    } catch (_) {}
  }

  static Future<void> _loadFromPreferences() async {
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentJson = prefs.getString(_prefKey);
      if (currentJson != null) {
        final map = Map<String, dynamic>.from(jsonDecode(currentJson));
        for (final entry in map.entries) {
          if (entry.value is Map<String, dynamic>) {
            _registry[entry.key] = CropState.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      }
    } catch (_) {}
  }
}
