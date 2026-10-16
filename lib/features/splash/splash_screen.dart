import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/product.dart';
import '../../core/models/banner_item.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();

    // Nefes alma / pulse animasyonu döngüsü (1400 ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 28.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Arka planda verileri ve görselleri hazırla, tam 3 saniye animasyonu garanti et
    _preloadAndNavigate();
  }

  Future<void> _preloadAndNavigate() async {
    final startTime = DateTime.now();
    try {
      final service = SupabaseService.instance;
      final results = await Future.wait([
        service.getProducts(forceRefresh: true),
        service.getBanners(forceRefresh: true),
        service.getStoreSettings(forceRefresh: true),
      ]);

      final products = results[0] as List<Product>;
      final banners = results[1] as List<BannerItem>;

      if (mounted) {
        // İlk vitrin ürünlerinin ve bannerların görsellerini önceden hafızaya al (precache)
        final precacheList = <Future<void>>[];
        for (final b in banners.take(3)) {
          final url = b.imageUrl.trim();
          if (url.startsWith('http')) {
            precacheList.add(
              precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {}),
            );
          }
        }
        for (final p in products.take(6)) {
          final url = p.imageUrl.trim();
          if (url.startsWith('http')) {
            precacheList.add(
              precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {}),
            );
          }
        }
        if (precacheList.isNotEmpty) {
          await Future.wait(precacheList).timeout(
            const Duration(milliseconds: 1800),
            onTimeout: () => [],
          );
        }
      }
    } catch (e) {
      debugPrint('Preload in splash warning: $e');
    }

    // Tam 3 saniye (3000 ms) animasyon süresini bekle
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 3000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted && !_isNavigated) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted || _isNavigated) return;
    _isNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(
          opacity: animation,
          child: const HomeScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Nefes Alan Logo Animasyonu
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: _glowAnimation.value,
                            spreadRadius: _glowAnimation.value * 0.35,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/manti-mood-logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('🥟', style: TextStyle(fontSize: 64)),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              // Marka İsmi
              Text(
                'Mantı Mood',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // Slogan
              Text(
                'Ev Yapımı Mantı & Yöresel Lezzetler',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              // Alt Yükleme Göstergesi
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lezzet fırını hazırlanıyor...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
