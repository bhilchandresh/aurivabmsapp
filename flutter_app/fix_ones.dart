import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  String content = file.readAsStringSync();

  // Fix known instances
  content = content.replaceAll(r'\1(days: 30)', 'const Duration(days: 30)');
  content = content.replaceAll(
    r'\1(LucideIcons.trash2',
    'Icon(LucideIcons.trash2',
  );
  content = content.replaceAll(r'\1(message: ', 'LoadingOverlay(message: ');
  content = content.replaceAll(r'\1(message:', 'LoadingOverlay(message:');

  // Let's check if there are any other \1 left
  if (content.contains(r'\1')) {
    print('There are still some \\1 left!');
  } else {
    print('All \\1 fixed!');
  }

  // Also fix line 1979 const_eval_extension_method
  // 'Text('elegant_proposal'.tr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: Colors.deepPurple))'
  // Let's ensure there's no const in front of it.
  content = content.replaceAll(
    'const Text(\'elegant_proposal\'.tr',
    'Text(\'elegant_proposal\'.tr',
  );

  file.writeAsStringSync(content);
}
