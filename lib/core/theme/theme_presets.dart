import 'package:flutter/material.dart';

/// Mantı Mood Renk Paleti Modeli
class AppColorPalette {
  final String key;
  final String name;
  final String badge;
  final String description;
  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryContainer;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppColorPalette({
    required this.key,
    required this.name,
    required this.badge,
    required this.description,
    this.isDark = false,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryContainer,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });
}

/// Mantı Mood Yönetici Tarafından Seçilebilir Butik Temalar
class AppThemePresets {
  AppThemePresets._();

  /// 1. Klasik Butik (Varsayılan - Kiremit Kırmızısı & Tereyağı Altını)
  static const AppColorPalette classic = AppColorPalette(
    key: 'classic',
    name: 'Klasik Butik',
    badge: '🥟 Klasik',
    description: 'Kiremit Kırmızısı & Tereyağı Altını. Sıcak, güven veren geleneksel lezzet.',
    isDark: false,
    primary: Color(0xFFB91C1C),
    primaryDark: Color(0xFF7F1D1D),
    primaryLight: Color(0xFFDC2626),
    primaryContainer: Color(0xFFFEE2E2),
    accent: Color(0xFFE5A93C),
    accentLight: Color(0xFFFDE68A),
    background: Color(0xFFF9F9FB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3F4F6),
    cardBorder: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
  );

  /// 2. Taş Fırın & Pişmiş Toprak (Terracotta & Sıcak Karamel)
  static const AppColorPalette terracotta = AppColorPalette(
    key: 'terracotta',
    name: 'Taş Fırın & Terracotta',
    badge: '🏺 Geleneksel',
    description: 'Pişmiş toprak & odun ateşi sıcaklığı. Geleneksel Anadolu zanaati hissi.',
    isDark: false,
    primary: Color(0xFFC2410C),
    primaryDark: Color(0xFF7C2D12),
    primaryLight: Color(0xFFEA580C),
    primaryContainer: Color(0xFFFFEDD5),
    accent: Color(0xFFD97706),
    accentLight: Color(0xFFFED7AA),
    background: Color(0xFFF8F3EC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDE4D6),
    cardBorder: Color(0xFFDFCABA),
    textPrimary: Color(0xFF2E190E),
    textSecondary: Color(0xFF6E5142),
    textMuted: Color(0xFF9E8172),
  );

  /// 3. Gurme Gece & Altın (Midnight Gold - Lüks Şef Grafit)
  static const AppColorPalette midnight = AppColorPalette(
    key: 'midnight',
    name: 'Gurme Gece & Altın',
    badge: '🌙 Şef Gurme',
    description: 'Derin grafit tonları ve parlak altın detaylar. Lüks şef mutfağı zarafeti.',
    isDark: true,
    primary: Color(0xFFF59E0B),
    primaryDark: Color(0xFFD97706),
    primaryLight: Color(0xFFFBBF24),
    primaryContainer: Color(0xFF293548),
    accent: Color(0xFF38BDF8),
    accentLight: Color(0xFF7DD3FC),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceMuted: Color(0xFF152033),
    cardBorder: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
  );

  /// 4. Ege & Taze Bahçe (Adaçayı & Zeytinyağı)
  static const AppColorPalette sage = AppColorPalette(
    key: 'sage',
    name: 'Ege & Taze Bahçe',
    badge: '🌿 Taze Gurme',
    description: 'Adaçayı yeşili ve sızma zeytinyağı tonları. Doğal, taze ve organik lezzet.',
    isDark: false,
    primary: Color(0xFF15803D),
    primaryDark: Color(0xFF14532D),
    primaryLight: Color(0xFF16A34A),
    primaryContainer: Color(0xFFDCFCE7),
    accent: Color(0xFFCA8A04),
    accentLight: Color(0xFFFEF9C3),
    background: Color(0xFFF2F8F4),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE2EEE5),
    cardBorder: Color(0xFFC5DECC),
    textPrimary: Color(0xFF14301D),
    textSecondary: Color(0xFF4A6B53),
    textMuted: Color(0xFF7E9A86),
  );

  /// 5. Saray Usulü & Derin Bordo
  static const AppColorPalette bordeaux = AppColorPalette(
    key: 'bordeaux',
    name: 'Saray Usulü & Bordo',
    badge: '👑 Asil Bordo',
    description: 'Derin vişne mürdümü ve bronz altın. Butik davet ve saray mutfağı prestiji.',
    isDark: false,
    primary: Color(0xFF831843),
    primaryDark: Color(0xFF500724),
    primaryLight: Color(0xFF9D174D),
    primaryContainer: Color(0xFFFCE7F3),
    accent: Color(0xFFB45309),
    accentLight: Color(0xFFFED7AA),
    background: Color(0xFFFAF2F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF2DFE7),
    cardBorder: Color(0xFFE0C4D1),
    textPrimary: Color(0xFF300B1A),
    textSecondary: Color(0xFF6B3A4F),
    textMuted: Color(0xFF9E6F83),
  );

  /// Tüm temalar listesi
  static const List<AppColorPalette> all = [
    classic,
    terracotta,
    midnight,
    sage,
    bordeaux,
  ];

  /// Anahtar kelimeye göre paleti getirir (varsayılan: classic)
  static AppColorPalette fromKey(String? key) {
    if (key == null || key.isEmpty) return classic;
    return all.firstWhere((p) => p.key == key, orElse: () => classic);
  }
}
