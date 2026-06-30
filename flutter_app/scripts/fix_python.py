import sys

def fix_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            print(f"Replaced string in {filepath}")
        else:
            print(f"WARNING: String not found in {filepath}: {old[:50]}...")
            
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

invoice_replacements = [
    (
        '''Text('${'discount'.tr} (${discountPct.toStringAsFixed(0)}%)'', style: const TextStyle(fontSize: 10, color: Colors.black54)),''',
        '''Text('${'discount'.tr} (${discountPct.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 10, color: Colors.black54)),'''
    ),
    (
        '''Text("${\"total_amount\".tr}:" ${formatCurrency.format(_total)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),''',
        '''Text('${'total_amount'.tr}: ${formatCurrency.format(_total)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),'''
    ),
    (
        '''Text("${\"total_amount\".tr}:" ${formatCurrency.format(invoiceTotal)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),''',
        '''Text('${'total_amount'.tr}: ${formatCurrency.format(invoiceTotal)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),'''
    )
]

quote_replacements = [
    (
        '''buildRow('${'discount'.tr} (${double.tryParse(_discountPercentageController.text)' != null ? double.tryParse(_discountPercentageController.text)!.toStringAsFixed(0) : "0"}%)', '- ${formatCurrency.format(_discountAmount)}'),''',
        '''buildRow('${'discount'.tr} (${double.tryParse(_discountPercentageController.text) != null ? double.tryParse(_discountPercentageController.text)!.toStringAsFixed(0) : "0"}%)', '- ${formatCurrency.format(_discountAmount)}'),'''
    ),
    (
        '''Text("${\"total_amount\".tr}:" ${formatCurrency.format(_total)}', style: TextStyle(fontSize: 11, color: Colors.grey)),''',
        '''Text('${'total_amount'.tr}: ${formatCurrency.format(_total)}', style: TextStyle(fontSize: 11, color: Colors.grey)),'''
    )
]

fix_file('lib/features/invoices/create_invoice_screen.dart', invoice_replacements)
fix_file('lib/features/quotations/create_quotation_screen.dart', quote_replacements)

# Some fallback for other formats of total amount if they exist
with open('lib/features/invoices/create_invoice_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
    c = c.replace('Text("${\\"total_amount\\".tr}:" ${formatCurrency.format', "Text('${'total_amount'.tr}: ${formatCurrency.format")
with open('lib/features/invoices/create_invoice_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)

with open('lib/features/quotations/create_quotation_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
    c = c.replace('Text("${\\"total_amount\\".tr}:" ${formatCurrency.format', "Text('${'total_amount'.tr}: ${formatCurrency.format")
with open('lib/features/quotations/create_quotation_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)
