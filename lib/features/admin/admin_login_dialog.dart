import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

/// Yönetici Girişi Modalı (Yalnızca Yetkili Hesaplar İçin)
class AdminLoginDialog extends StatefulWidget {
  const AdminLoginDialog({super.key});

  @override
  State<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _authSubscription = SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final email = session?.user.email?.toLowerCase().trim();
      if (email != null && email.isNotEmpty) {
        if (SupabaseService.allowedAdminEmails.contains(email)) {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          // Eğer giriş yapmaya çalışan hesap yetkili listede yoksa
          if (_isLoading) {
            SupabaseService.instance.client.auth.signOut();
            if (mounted) {
              setState(() {
                _errorMessage = 'Erişim Reddedildi: Giriş yapılan hesabın yönetim paneline erişim yetkisi bulunmamaktadır.';
                _isLoading = false;
                _statusMessage = null;
              });
            }
          }
        }
      }
    });
  }

  void _checkInitialAuth() {
    if (SupabaseService.instance.isCurrentAdminAuthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Google oturum açma sayfası açılıyor, lütfen bekleyiniz...';
    });

    try {
      final success = await SupabaseService.instance.signInWithGoogle();
      if (!success) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Google ile giriş başlatılamadı. Lütfen tekrar deneyiniz.';
            _isLoading = false;
            _statusMessage = null;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'Oturum açma bekleniyor... Lütfen tarayıcıdaki adımları tamamlayınız.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Giriş sırasında bir sorun oluştu. Lütfen bağlantınızı kontrol edip tekrar deneyiniz.';
          _isLoading = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Güvenlik İkonu
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // Başlık
                const Text(
                  'Yönetici Girişi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mantı Mood Yönetim Paneli',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),

                // Güvenlik Bilgilendirme Kutusu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bu alan yalnızca yöneticilerinin erişimine açıktır. Lütfen yetkili hesabınız ile giriş yapınız.',
                          style: TextStyle(fontSize: 11.5, height: 1.45, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Bilgilendirme Mesajı (Oturum Açma Beklenirken)
                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Hata Bildirimi (Yetkisiz hesap veya bağlantı hatası)
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Google ile Giriş Yap (Resmi ve Tek Üretim Giriş Yöntemi)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 2,
                      side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading && _statusMessage != null
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                width: 22,
                                height: 22,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Google ile Giriş Yap',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3C4043),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Yetkili yönetici hesabınız ile güvenle oturum açabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),

                // Yalnızca Geliştirici (Debug) Modunda Görünen Hızlı Test Butonu
                // Release (Üretim) derlemelerinde bu kod derleyici tarafından tamamen budanır (tree-shaking)
                if (kDebugMode) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.developer_mode, size: 16, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Text(
                              'Geliştirici Modu (Yalnızca Test)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text(
                              'Hızlı Test Girişi (Geliştirici)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              SupabaseService.instance.setSimulatedAdmin(SupabaseService.allowedAdminEmails.first);
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Vazgeç Butonu
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Vazgeç',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
