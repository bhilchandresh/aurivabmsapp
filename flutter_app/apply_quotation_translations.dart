import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  String content = file.readAsStringSync();

  final Map<String, String> replacements = {
    "'Create New Quotation'": "'create_new_quotation'.tr",
    "'Edit Quotation'": "'edit_quotation'.tr",
    "'Client Details'": "'client_details'.tr",
    "'Select Client'": "'select_client'.tr",
    "'Client Name *'": "'client_name_star'.tr",
    "'Client Email'": "'client_email'.tr",
    "'Client Address'": "'client_address'.tr",
    "'Client Phone'": "'client_phone'.tr",
    "'GSTIN'": "'gstin'.tr",
    "'Quotation Details'": "'quotation_details'.tr",
    "'Quote No *'": "'quote_no_star'.tr",
    "'Date'": "'date'.tr",
    "'Valid Until'": "'valid_until'.tr",
    "'Place of Supply'": "'place_of_supply'.tr",
    "'Tax Type'": "'tax_type'.tr",
    "'Inclusive'": "'inclusive'.tr",
    "'Exclusive'": "'exclusive'.tr",
    "'Line Items'": "'line_items'.tr",
    "'Add Item'": "'add_item'.tr",
    "'ITEM NAME / TITLE *'": "'item_name_title'.tr",
    "'Description (Optional)'": "'desc_optional'.tr",
    "'Qty'": "'qty'.tr",
    "'Rate'": "'rate'.tr",
    "'GST'": "'gst'.tr",
    "'Amount'": "'amount'.tr",
    "'Financial Summary'": "'financial_summary'.tr",
    "'Subtotal'": "'subtotal'.tr",
    "'Discount (%)'": "'discount_percent'.tr",
    "'Grand Total'": "'grand_total'.tr",
    "'Advance Received'": "'advance_received'.tr",
    "'BALANCE DUE'": "'balance_due'.tr",
    "'Terms & Notes'": "'terms_notes'.tr",
    "'Add terms and conditions...'": "'add_terms_cond'.tr",
    "'Save Quotation'": "'save_quotation'.tr",
    "'Export PDF'": "'export_pdf'.tr",
    "'Share PDF'": "'share_pdf'.tr",
    "'PROPOSAL FOR'": "'proposal_for'.tr",
    "'VALID UNTIL'": "'valid_until_caps'.tr",
    "'BANK ACCREDITATION'": "'bank_accreditation'.tr",
    "'Bank Name: '": "'bank_name_colon'.tr",
    "'A/C Name: '": "'ac_name_colon'.tr",
    "'Number: '": "'number_colon'.tr",
    "'IFSC: '": "'ifsc_colon'.tr",
    "'GSTIN: '": "'gstin_colon'.tr",
    "'PROPOSAL'": "'proposal'.tr",
    "'Date: '": "'date_colon'.tr",
    "'Valid Until: '": "'valid_until_colon'.tr",
    "'CLIENT DETAILS'": "'client_details_caps'.tr",
    "'TERMS & CONDITIONS'": "'terms_conditions_caps'.tr",
    "'CLIENT'": "'client'.tr",
    "'Quote #: '": "'quote_no_colon'.tr",
    "'Issued: '": "'issued_colon'.tr",
    "'ELEGANT PROPOSAL'": "'elegant_proposal'.tr",
    "'PREPARED FOR'": "'prepared_for'.tr",
    "'Proposal Ref: '": "'proposal_ref_colon'.tr",
    "'Created On: '": "'created_on_colon'.tr",
    "'PAYMENT PROTOCOL'": "'payment_protocol'.tr",
    "'Beneficiary: '": "'beneficiary_colon'.tr",
    "'BILLED CLIENT'": "'billed_client'.tr",
    "'REVENUE CHANNEL'": "'revenue_channel'.tr",
    "'A/C: '": "'ac_colon'.tr",
    "'AMOUNT IN WORDS'": "'amount_in_words'.tr",
    "'At least one item is required'": "'error_req_item'.tr",
    "'Please enter Client Name'": "'error_req_client'.tr",
    "'Please enter Client Name before exporting'":
        "'error_req_client_export'.tr",
    "'Please enter Proposal/Quotation Number'": "'error_req_quote_no'.tr",
    "'Generating premium Quotation PDF...'": "'generating_pdf'.tr",
  };

  for (var entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  // Handle the dynamic one:
  content = content.replaceAll(
    "'Please enter name for Item #\${i + 1}'",
    "'\${'error_req_item_name'.tr}\${i + 1}'",
  );

  file.writeAsStringSync(content);
  print('Replaced strings with .tr keys in create_quotation_screen.dart!');
}
