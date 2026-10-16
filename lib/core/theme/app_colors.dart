import 'package:flutter/material.dart';

/// Mantı Mood kurumsal marka ve arayüz renkleri
/// Kaynak: manti-mood-logo.png renk analizi
class AppColors {
  AppColors._();

  // Ana Renk (Kırmızı / Kiremit / Bordo - Logodaki "Mantı" ve kurdele rengi)
  static const Color primary = Color(0xFFB91C1C);
  static const Color primaryDark = Color(0xFF7F1D1D);
  static const Color primaryLight = Color(0xFFDC2626);
  static const Color primaryContainer = Color(0xFFFEE2E2);

  // Vurgu & Tereyağı Sarısı (Logodaki altın şerit, duman ve kenarlık gradyanı)
  static const Color accent = Color(0xFFE5A93C);
  static const Color accentLight = Color(0xFFFDE68A);
  static const Color accentDark = Color(0xFFB45309);

  // Doğal Zemin & Hamur Kremi (Temiz, ferah, fotoğrafları öne çıkaran gurme zemin)
  static const Color background = Color(0xFFF9F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F4F6);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // Tipografi & Gövde Metinleri (Net, kontrastı yüksek, modern)
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Durum Renkleri
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);
}
