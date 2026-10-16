import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MediaUploadService {
  static final MediaUploadService instance = MediaUploadService._internal();
  MediaUploadService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Cihazdan tekli fotoğraf seçip Supabase Storage'a yükler (Yedek: Base64 Data URI)
  Future<String?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return null;
      return await _processAndUpload(file, isVideo: false);
    } catch (e) {
      debugPrint('pickImage error: $e');
      return null;
    }
  }

  /// Cihazdan fotoğraf seçer ve kırpma ekranına doğrudan yüksek kaliteli Base64 Data URI olarak verir.
  /// Bu sayede görsel sunucuya gitmeden veya CORS engeline takılmadan anında ve hatasız kırpılabilir.
  Future<String?> pickImageForCropping({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final cleanExt = ext.isNotEmpty ? ext : 'jpg';
      final mime = file.mimeType ?? 'image/$cleanExt';
      final base64String = base64Encode(bytes);
      return 'data:$mime;base64,$base64String';
    } catch (e) {
      debugPrint('pickImageForCropping error: $e');
      return null;
    }
  }

  /// Cihazdan çoklu fotoğraf seçip yükler
  Future<List<String>> pickMultiImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (files.isEmpty) return [];

      List<String> uploadedUrls = [];
      for (var f in files) {
        final url = await _processAndUpload(f, isVideo: false);
        if (url != null) uploadedUrls.add(url);
      }
      return uploadedUrls;
    } catch (e) {
      debugPrint('pickMultiImages error: $e');
      return [];
    }
  }

  /// Cihazdan video seçip yükler
  Future<String?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (file == null) return null;
      return await _processAndUpload(file, isVideo: true);
    } catch (e) {
      debugPrint('pickVideo error: $e');
      return null;
    }
  }

  Future<String?> _processAndUpload(XFile file, {required bool isVideo}) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = file.mimeType ?? (isVideo ? 'video/$ext' : 'image/$ext');
      final cleanExt = ext.isNotEmpty ? ext : (isVideo ? 'mp4' : 'jpg');
      final fileName = '${isVideo ? "vid" : "img"}_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

      // 1. Supabase Storage 'products' bucket'ına yüklemeyi dene
      try {
        final client = SupabaseService.instance.client;
        await client.storage.from('products').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: mime, upsert: true),
            );
        final publicUrl = client.storage.from('products').getPublicUrl(fileName);
        return publicUrl;
      } catch (storageError) {
        debugPrint('Supabase storage upload failed: $storageError. Using data URI fallback.');
        // 2. Eğer bucket henüz açılmamışsa veya hata olursa güvenli Data URI fallback
        final base64String = base64Encode(bytes);
        return 'data:$mime;base64,$base64String';
      }
    } catch (e) {
      debugPrint('_processAndUpload error: $e');
      return null;
    }
  }

  /// Kırpılmış veya işlenmiş ham görsel baytlarını Supabase Storage'a veya Base64 Data URI'ye yükler
  Future<String> uploadRawImageBytes(Uint8List bytes, {String? fileName}) async {
    final name = fileName ?? 'crop_${DateTime.now().millisecondsSinceEpoch}.png';
    const mime = 'image/png';
    try {
      final client = SupabaseService.instance.client;
      await client.storage.from('products').uploadBinary(
            name,
            bytes,
            fileOptions: const FileOptions(contentType: mime, upsert: true),
          );
      return client.storage.from('products').getPublicUrl(name);
    } catch (e) {
      debugPrint('Supabase upload binary fallback to data URI: $e');
      final base64String = base64Encode(bytes);
      return 'data:$mime;base64,$base64String';
    }
  }
}
