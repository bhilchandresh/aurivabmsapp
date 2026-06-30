import 'dart:io';

void main() {
  final result = Process.runSync('cmd', [
    '/c',
    'flutter',
    'analyze',
    '--no-fatal-infos',
    '--no-fatal-warnings',
  ]);
  final lines = result.stdout.toString().split('\n');

  int fixedCount = 0;

  for (var line in lines) {
    if (line.contains('const_eval_extension_method') ||
        line.contains('const_eval_property_access') ||
        line.contains('undefined_getter') ||
        line.contains('extra_positional_arguments_could_be_named') ||
        line.contains('expected_token') ||
        line.contains('missing_required_argument') ||
        line.contains('undefined_identifier')) {
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final fileInfo = parts[parts.length - 2].trim();
        final fileParts = fileInfo.split(':');
        if (fileParts.length >= 3) {
          final filePath = fileParts[0];
          final lineNum = int.tryParse(fileParts[1]);

          if (lineNum != null) {
            final file = File(filePath);
            if (file.existsSync()) {
              final fileLines = file.readAsLinesSync();
              int currentLine = lineNum - 1;

              // Look for 'const ' on this line or up to 5 lines above
              bool fixed = false;
              for (int i = 0; i < 5; i++) {
                if (currentLine - i >= 0 &&
                    currentLine - i < fileLines.length) {
                  String text = fileLines[currentLine - i];
                  if (text.contains('const ')) {
                    fileLines[currentLine - i] = text.replaceAll('const ', '');
                    file.writeAsStringSync(fileLines.join('\n'));
                    print(
                      'Fixed const in $filePath at line ${currentLine - i + 1}',
                    );
                    fixed = true;
                    fixedCount++;
                    break;
                  }
                }
              }
              if (!fixed) {
                print('Could not find const near $filePath:$lineNum');
              }
            }
          }
        }
      }
    }
  }
  print('Fixed $fixedCount const issues.');
}
