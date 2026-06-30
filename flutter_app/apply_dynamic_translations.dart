import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  String content = file.readAsStringSync();

  // Handle dynamic strings explicitly
  final dynamicReplacements = {
    "'Terms & Conditions'":
        "'terms_notes'.tr", // using terms_notes for generic "Terms & Conditions"
    "'Place: \$placeOfSupply'":
        "'\${\\'place_of_supply\\'.tr}: \$placeOfSupply'",
    "'A/C Name: \${_mockBankDetails['accountName']}'":
        "'\${\\'ac_name_colon\\'.tr}\${_mockBankDetails[\\'accountName\\']}'",
    "'Number: \${_mockBankDetails['accountNumber']}'":
        "'\${\\'number_colon\\'.tr}\${_mockBankDetails[\\'accountNumber\\']}'",
    "'IFSC: \${_mockBankDetails['ifscCode']}'":
        "'\${\\'ifsc_colon\\'.tr}\${_mockBankDetails[\\'ifscCode\\']}'",
    "'GSTIN: \${_companyInfo['gstin']}'":
        "'\${\\'gstin_colon\\'.tr}\${_companyInfo[\\'gstin\\']}'",
    "'Date: \$quoteDate'": "'\${\\'date_colon\\'.tr}\$quoteDate'",
    "'Valid Until: \$validUntil'":
        "'\${\\'valid_until_colon\\'.tr}\$validUntil'",
    "'Quote #: \$quoteNumber'": "'\${\\'quote_no_colon\\'.tr}\$quoteNumber'",
    "'Issued: \$quoteDate'": "'\${\\'issued_colon\\'.tr}\$quoteDate'",
    "'Proposal Ref: #\$quoteNumber'":
        "'\${\\'proposal_ref_colon\\'.tr}#\$quoteNumber'",
    "'Created On: \$quoteDate'": "'\${\\'created_on_colon\\'.tr}\$quoteDate'",
    "'Beneficiary: \${_mockBankDetails['accountName']}'":
        "'\${\\'beneficiary_colon\\'.tr}\${_mockBankDetails[\\'accountName\\']}'",
    "'Bank Name: \${_mockBankDetails['bankName']}'":
        "'\${\\'bank_name_colon\\'.tr}\${_mockBankDetails[\\'bankName\\']}'",
    "'A/C: \${_mockBankDetails['accountNumber']}'":
        "'\${\\'ac_colon\\'.tr}\${_mockBankDetails[\\'accountNumber\\']}'",
    "'A/C Number: \${_mockBankDetails['accountNumber']}'":
        "'\${\\'number_colon\\'.tr}\${_mockBankDetails[\\'accountNumber\\']}'",
    "'IFSC Identifier: \${_mockBankDetails['ifscCode']}'":
        "'\${\\'ifsc_colon\\'.tr}\${_mockBankDetails[\\'ifscCode\\']}'",
    "'Total Amount: \${formatCurrency.format(_total)}'":
        "'\${\\'amount\\'.tr}: \${formatCurrency.format(_total)}'",
    "Discount (\${discountPercentage.toStringAsFixed(0)}%)":
        "\${\\'discount_percent\\'.tr.split(\\'(\\')[0]} (\${discountPercentage.toStringAsFixed(0)}%)",
  };

  for (var entry in dynamicReplacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  file.writeAsStringSync(content);
  print(
    'Replaced dynamic strings with .tr keys in create_quotation_screen.dart!',
  );
}
