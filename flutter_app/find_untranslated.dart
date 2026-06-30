import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  final content = file.readAsStringSync();

  // Find strings in Text, label, hintText, title, etc.
  final regex = RegExp(
    r"(?:Text|label:|hintText:|hint:|title:|TextSpan\(text:)\s*(?:const\s+)?(['" +
        '"' +
        r"'])(.*?)\1(?!\.tr)",
  );
  final matches = regex.allMatches(content);

  final Set<String> untranslated = {};
  for (var match in matches) {
    // Only capture strings with alphabet characters
    if (match.group(2)!.contains(RegExp(r'[a-zA-Z]'))) {
      untranslated.add(match.group(2)!);
    }
  }

  print('Untranslated Strings Found:');
  for (var str in untranslated) {
    print(str);
  }
}
