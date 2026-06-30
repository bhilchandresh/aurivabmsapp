import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  final lines = file.readAsLinesSync();

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains("Text('") || line.contains('Text("')) {
      if (!line.contains('.tr')) {
        print('Line ${i + 1}: ${line.trim()}');
      }
    }
    if (line.contains("pw.Text('") || line.contains('pw.Text("')) {
      if (!line.contains('.tr')) {
        print('Line ${i + 1}: ${line.trim()}');
      }
    }
  }
}
