import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/supabase_service.dart';
import 'core/models/store_settings.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/cart/cart_controller.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Mobil ve webde lastik gibi esneme (bouncing/overscroll stretch) efektini kaldıran scroll davranışı
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android & iOS için Edge-to-Edge sistem bildirim ve gezinme çubuğu uyumu
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Supabase Bulut Veritabanı ve Yerel Sepet Başlatma
  await SupabaseService.initialize();
  await CartController.instance.loadFromStorage();

  runApp(const MantiMoodApp());
}

class MantiMoodApp extends StatelessWidget {
  const MantiMoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StoreSettings?>(
      valueListenable: SupabaseService.instance.settingsNotifier,
      builder: (context, settings, _) {
        final presetKey = settings?.themePreset;
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Mantı Mood — Ev Yapımı Mantı & Yöresel Lezzetler',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          theme: AppTheme.getTheme(presetKey: presetKey),
          home: kIsWeb ? const HomeScreen() : const SplashScreen(),
        );
      },
    );
  }
}
