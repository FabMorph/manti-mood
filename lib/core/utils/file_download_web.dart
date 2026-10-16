// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> downloadFileBytes(List<int> bytes, String fileName, {String? mimeType}) async {
  final mime = mimeType ??
      (fileName.endsWith('.csv')
          ? 'text/csv;charset=utf-8'
          : (fileName.endsWith('.png') ? 'image/png' : 'application/octet-stream'));
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
