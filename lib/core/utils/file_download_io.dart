import 'dart:io';

Future<void> downloadFileBytes(List<int> bytes, String fileName, {String? mimeType}) async {
  try {
    String? downloadsPath;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        downloadsPath = '$userProfile\\Downloads';
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        downloadsPath = '$home/Downloads';
      }
    }

    if (downloadsPath != null) {
      final dir = Directory(downloadsPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('$downloadsPath${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);
    }
  } catch (_) {
    // Platform-specific IO error fallback
  }
}
