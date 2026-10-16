import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart';

abstract class FileDownloadHelper {
  /// Görsel veya belge baytlarını kullanıcının doğrudan "İndirilenler" (Downloads) klasörüne indirir
  static Future<void> downloadBytes(List<int> bytes, String fileName, {String? mimeType}) =>
      downloadFileBytes(bytes, fileName, mimeType: mimeType);
}
