import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  final content = file.readAsStringSync();

  final stringsToCheck = [
    "Create New Quotation",
    "Edit Quotation",
    "Client Details",
    "Select Client",
    "Client Name *",
    "Client Email",
    "Client Address",
    "Client Phone",
    "GSTIN",
    "Quotation Details",
    "Quote No *",
    "Date",
    "Valid Until",
    "Place of Supply",
    "Tax Type",
    "Inclusive",
    "Exclusive",
    "Line Items",
    "Add Item",
    "ITEM NAME / TITLE *",
    "Description (Optional)",
    "Qty",
    "Rate",
    "GST",
    "Amount",
    "Financial Summary",
    "Subtotal",
    "Discount (%)",
    "Grand Total",
    "Advance Received",
    "BALANCE DUE",
    "Terms & Notes",
    "Add terms and conditions...",
    "Save Quotation",
    "Export PDF",
    "Share PDF",
    "PROPOSAL FOR",
    "VALID UNTIL",
    "BANK ACCREDITATION",
    "PROPOSAL",
    "CLIENT DETAILS",
    "TERMS & CONDITIONS",
    "CLIENT",
    "ELEGANT PROPOSAL",
    "PREPARED FOR",
    "PAYMENT PROTOCOL",
    "BILLED CLIENT",
    "REVENUE CHANNEL",
    "AMOUNT IN WORDS",
    "At least one item is required",
    "Please enter Client Name",
    "Please enter Client Name before exporting",
    "Please enter Proposal/Quotation Number",
    "Generating premium Quotation PDF...",
  ];

  print('Looking for un-translated strings:');
  for (final s in stringsToCheck) {
    if (content.contains("'$s'") || content.contains('"$s"')) {
      print('- $s');
    }
  }
}
