import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/theme/app_colors.dart';

class CookingGuideDialog extends StatelessWidget {
  final Product product;

  const CookingGuideDialog({super.key, required this.product});

  static void show(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => CookingGuideDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pişirme & Saklama Rehberi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 16),
              // Pişirme Adımları
              _buildSection(
                context,
                icon: Icons.timer_outlined,
                iconColor: AppColors.primary,
                title: 'Nasıl Pişirilir? (8-10 Dakika)',
                content: product.cookingInstructions.isNotEmpty
                    ? product.cookingInstructions
                    : '1. Geniş bir tencereye bol su koyup kaynatın ve 1 tatlı kaşığı tuz ekleyin.\n'
                      '2. Şoklanmış mantıları çözülmesini beklemeden doğrudan kaynayan suya atın.\n'
                      '3. Arada hafifçe tahta kaşıkla karıştırarak orta ateşte 8-10 dakika haşlayın.\n'
                      '4. Mantılar su yüzeyine çıktığında süzgeçle servis tabağına alın.',
              ),
              const SizedBox(height: 18),
              // Sos Önerisi
              _buildSection(
                context,
                icon: Icons.local_fire_department,
                iconColor: AppColors.accentDark,
                title: 'Mantı Mood Özel Sos Tavsiyesi',
                content: 'Tavada hakiki tereyağını kızdırıp üzerine hafif nane ve pul biber ekleyin. '
                    'Tabağa aldığınız mantının üzerine önce çırpılmış sarımsaklı süzme yoğurt, '
                    'ardından kızgın tereyağlı sosu gezdirin. Afiyet olsun!',
              ),
              const SizedBox(height: 18),
              // Saklama Koşulları
              _buildSection(
                context,
                icon: Icons.ac_unit,
                iconColor: AppColors.info,
                title: 'Nasıl Saklanır?',
                content: product.storageInstructions.isNotEmpty
                    ? product.storageInstructions
                    : 'Teslim aldıktan sonra dondurucuya (-18°C) yerleştiriniz. '
                      'Mantılarımız şoklanarak tazeliği kilitlendiği için 3 aya kadar lezzetini korur. '
                      'Pişireceğiniz zaman buzunu çözdürmeyiniz.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anladım, Teşekkürler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
