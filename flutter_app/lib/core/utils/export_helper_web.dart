// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void saveAndShareFile(Uint8List bytes, String filename) {
  final base64 = base64Encode(bytes);
  html.AnchorElement(
      href:
          'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64',
    )
    ..setAttribute('download', filename)
    ..click();
}
