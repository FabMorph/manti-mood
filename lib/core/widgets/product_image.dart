import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool get isVideo {
    final lower = imageUrl.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.startsWith('data:video') ||
        lower.contains('video');
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) {
      return _buildPlaceholder();
    }

    if (isVideo) {
      return Container(
        width: width,
        height: height,
        color: Colors.black87,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.videocam, color: Colors.white54, size: 48),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            ),
          ],
        ),
      );
    }

    if (cleanUrl.startsWith('data:image')) {
      try {
        final commaIndex = cleanUrl.indexOf(',');
        final base64Str = commaIndex != -1 ? cleanUrl.substring(commaIndex + 1) : cleanUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    if (cleanUrl.startsWith('assets/') || cleanUrl.startsWith('/assets/')) {
      final assetPath = cleanUrl.startsWith('/') ? cleanUrl.substring(1) : cleanUrl;
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (cleanUrl.contains('manti-cesitleri') || cleanUrl.contains('images/')) {
      final assetPath = cleanUrl.startsWith('assets/') ? cleanUrl : 'assets/$cleanUrl';
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(Icons.restaurant, color: AppColors.primary, size: 36),
      ),
    );
  }
}
