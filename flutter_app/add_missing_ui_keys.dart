import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final Map<String, Map<String, String>> newTranslations = {
    'en_US': {
      'new_quotation': 'New Quotation',
      'create_new_estimate_proposal': 'Create a new estimate/Proposal',
      'quote_to': 'QUOTE TO',
      'search_existing_client': 'Search Existing Client',
      'type_to_search_clients': 'Type to search clients...',
      'client_name_star': 'Client Name *',
      'quote_details': 'QUOTE DETAILS',
      'quotation_date_star': 'Quotation Date *',
      'valid_until_star': 'Valid Until *',
      'line_items': 'LINE ITEMS',
      'detailed_description_optional': 'DETAILED DESCRIPTION (OPTIONAL)',
      'add_extra_details': 'Add extra details...',
      'amount_caps': 'AMOUNT',
      'add_new_item_line': '+ Add New Item Line',
      'remove_item': 'Remove Item',
      'default_terms_notes':
          '1. Goods once sold will not be taken back.\\n2. Interest @18% pa will be charged if payment is not made within the due date.',
      'financial_summary': 'FINANCIAL SUMMARY',
      'terms_notes': 'TERMS & NOTES',
      'save': 'Save',
      'enable_gst': 'Enable GST',
    },
    'gu_IN': {
      'new_quotation': 'નવું ક્વોટેશન',
      'create_new_estimate_proposal': 'નવો અંદાજ/પ્રસ્તાવ બનાવો',
      'quote_to': 'ક્વોટ ટુ',
      'search_existing_client': 'હાલના ગ્રાહકને શોધો',
      'type_to_search_clients': 'ગ્રાહકો શોધવા માટે ટાઈપ કરો...',
      'client_name_star': 'ગ્રાહકનું નામ *',
      'quote_details': 'ક્વોટ વિગતો',
      'quotation_date_star': 'ક્વોટેશન તારીખ *',
      'valid_until_star': 'અહીં સુધી માન્ય *',
      'line_items': 'લાઇન આઇટમ્સ',
      'detailed_description_optional': 'વિગતવાર વર્ણન (વૈકલ્પિક)',
      'add_extra_details': 'વધારાની વિગતો ઉમેરો...',
      'amount_caps': 'રકમ',
      'add_new_item_line': '+ નવી આઇટમ લાઇન ઉમેરો',
      'remove_item': 'આઇટમ દૂર કરો',
      'default_terms_notes':
          '1. માલ વેચ્યા પછી પાછો લેવામાં આવશે નહીં.\\n2. જો નિયત તારીખમાં ચુકવણી કરવામાં નહીં આવે તો વાર્ષિક 18% વ્યાજ લેવામાં આવશે.',
      'financial_summary': 'નાણાકીય સારાંશ',
      'terms_notes': 'શરતો અને નોંધો',
      'save': 'સાચવો',
      'enable_gst': 'GST સક્ષમ કરો',
    },
    'hi_IN': {
      'new_quotation': 'नया उद्धरण',
      'create_new_estimate_proposal': 'नया अनुमान/प्रस्ताव बनाएं',
      'quote_to': 'कोट टू',
      'search_existing_client': 'मौजूदा ग्राहक खोजें',
      'type_to_search_clients': 'ग्राहकों को खोजने के लिए टाइप करें...',
      'client_name_star': 'ग्राहक का नाम *',
      'quote_details': 'उद्धरण विवरण',
      'quotation_date_star': 'उद्धरण तिथि *',
      'valid_until_star': 'तक वैध *',
      'line_items': 'लाइन आइटम',
      'detailed_description_optional': 'विस्तृत विवरण (वैकल्पिक)',
      'add_extra_details': 'अतिरिक्त विवरण जोड़ें...',
      'amount_caps': 'मात्रा',
      'add_new_item_line': '+ नई आइटम पंक्ति जोड़ें',
      'remove_item': 'मद हटाएँ',
      'default_terms_notes':
          '1. बिका हुआ माल वापस नहीं लिया जाएगा।\\n2. नियत तारीख के भीतर भुगतान नहीं होने पर 18% प्रति वर्ष की दर से ब्याज लिया जाएगा।',
      'financial_summary': 'वित्तीय सारांश',
      'terms_notes': 'नियम एवं नोट्स',
      'save': 'सहेजें',
      'enable_gst': 'जीएसटी सक्षम करें',
    },
  };

  List<String> langs = [
    'en_US',
    'hi_IN',
    'bn_IN',
    'te_IN',
    'ta_IN',
    'ur_IN',
    'kn_IN',
    'or_IN',
    'ml_IN',
    'gu_IN',
    'mr_IN',
  ];

  for (String lang in langs) {
    Map<String, String> toAdd =
        newTranslations[lang] ?? newTranslations['en_US']!;

    int index = content.indexOf("'\$lang': {");
    if (index != -1) {
      int insertIndex = content.indexOf('\n', index) + 1;

      String stringsToAdd = '';
      toAdd.forEach((k, v) {
        if (!content.contains("'\$k':")) {
          String escapedValue = v
              .replaceAll("'", "\\'")
              .replaceAll('\n', '\\n');
          stringsToAdd += "          '\$k': '\$escapedValue',\n";
        }
      });

      if (stringsToAdd.isNotEmpty) {
        content =
            content.substring(0, insertIndex) +
            stringsToAdd +
            content.substring(insertIndex);
      }
    }
  }

  file.writeAsStringSync(content);
  print('Added missing quotation UI keys to app_translations.dart!');
}
