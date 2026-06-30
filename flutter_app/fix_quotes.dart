import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  String content = file.readAsStringSync();

  // The faulty pattern looks like: '${\'some_key\'.tr}...'
  // We want to replace it with: "${'some_key'.tr}..."

  // We can just use standard String replacement for the ones that we know failed:
  final fixes = {
    r"'${\'place_of_supply\'.tr}: $placeOfSupply'":
        r'"${'
        "'place_of_supply'.tr}: \$placeOfSupply"
        '"',
    r"'${\'ac_name_colon\'.tr}${_mockBankDetails[\'accountName\']}'":
        r'"${'
        "'ac_name_colon'.tr}\${_mockBankDetails['accountName']}"
        '"',
    r"'${\'number_colon\'.tr}${_mockBankDetails[\'accountNumber\']}'":
        r'"${'
        "'number_colon'.tr}\${_mockBankDetails['accountNumber']}"
        '"',
    r"'${\'ifsc_colon\'.tr}${_mockBankDetails[\'ifscCode\']}'":
        r'"${'
        "'ifsc_colon'.tr}\${_mockBankDetails['ifscCode']}"
        '"',
    r"'${\'gstin_colon\'.tr}${_companyInfo[\'gstin\']}'":
        r'"${'
        "'gstin_colon'.tr}\${_companyInfo['gstin']}"
        '"',
    r"'${\'date_colon\'.tr}$quoteDate'":
        r'"${'
        "'date_colon'.tr}\$quoteDate"
        '"',
    r"'${\'valid_until_colon\'.tr}$validUntil'":
        r'"${'
        "'valid_until_colon'.tr}\$validUntil"
        '"',
    r"'${\'quote_no_colon\'.tr}$quoteNumber'":
        r'"${'
        "'quote_no_colon'.tr}\$quoteNumber"
        '"',
    r"'${\'issued_colon\'.tr}$quoteDate'":
        r'"${'
        "'issued_colon'.tr}\$quoteDate"
        '"',
    r"'${\'proposal_ref_colon\'.tr}#$quoteNumber'":
        r'"${'
        "'proposal_ref_colon'.tr}#\$quoteNumber"
        '"',
    r"'${\'created_on_colon\'.tr}$quoteDate'":
        r'"${'
        "'created_on_colon'.tr}\$quoteDate"
        '"',
    r"'${\'beneficiary_colon\'.tr}${_mockBankDetails[\'accountName\']}'":
        r'"${'
        "'beneficiary_colon'.tr}\${_mockBankDetails['accountName']}"
        '"',
    r"'${\'bank_name_colon\'.tr}${_mockBankDetails[\'bankName\']}'":
        r'"${'
        "'bank_name_colon'.tr}\${_mockBankDetails['bankName']}"
        '"',
    r"'${\'ac_colon\'.tr}${_mockBankDetails[\'accountNumber\']}'":
        r'"${'
        "'ac_colon'.tr}\${_mockBankDetails['accountNumber']}"
        '"',
    r"'${\'amount\'.tr}: ${formatCurrency.format(_total)}'":
        r'"${'
        "'amount'.tr}: \${formatCurrency.format(_total)}"
        '"',
    r"Text('${\'discount_percent\'.tr.split(\'(\')[0]} (${discountPercentage.toStringAsFixed(0)}%)'":
        r'Text("${'
        "'discount_percent'.tr.split('(')[0]} (\${discountPercentage.toStringAsFixed(0)}%)"
        '"',
    r"'${\'error_req_item_name\'.tr}${i + 1}'":
        r'"${'
        "'error_req_item_name'.tr}\${i + 1}"
        '"',
  };

  for (var entry in fixes.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  file.writeAsStringSync(content);
  print('Fixed syntax errors in create_quotation_screen.dart!');
}
