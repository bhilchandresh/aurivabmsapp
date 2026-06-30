import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

void saveAndShareFile(Uint8List bytes, String filename) {
  final base64 = base64Encode(bytes);
  final anchor =
      html.AnchorElement(
          href:
              'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64',
        )
        ..setAttribute('download', filename)
        ..click();
}
