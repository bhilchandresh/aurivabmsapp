import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final Map<String, Map<String, String>> translations = {
    'bn_IN': {
      'contact_client': 'যোগাযোগ ',
      'contact_method_prompt':
          'আপনি কিভাবে ক্লায়েন্টের সাথে যোগাযোগ করতে চান?',
      'outstanding_due_rs': 'বকেয়া পাওনা: টাকা ',
      'advance_rs': 'অগ্রিম: টাকা ',
      'outstanding_nil': 'বকেয়া পাওনা: শূন্য',
      'hello_greeting': 'হ্যালো ',
      'sms_sent_success': 'সরাসরি এসএমএস পাঠানো হয়েছে ',
      'sms_send_error': 'এসএমএস পাঠানো যায়নি: ',
      'sms_permission_denied':
          'ব্যাকগ্রাউন্ডে বার্তা পাঠাতে এসএমএস অনুমতি প্রয়োজন',
      'direct_call_error': 'সরাসরি কল করা যায়নি: ',
      'phone_permission_denied': 'সরাসরি কল করতে ফোন অনুমতি প্রয়োজন',
      'direct_sms': 'সরাসরি এসএমএস',
      'call': 'কল',
      'phone_missing': 'ফোন নেই',
      'phone_not_configured': 'এই ক্লায়েন্টের কোন ফোন নম্বর কনফিগার করা নেই।',
      'qty_rate': 'পরিমাণ / হার',
      'gst_rate_percent': 'জিএসটি হার (%)',
      'tax_amount_caps': 'করের পরিমাণ',
      'hsn_sac_code': 'এইচএসএন/এসএসি কোড',
      'taxable_amount': 'করযোগ্য পরিমাণ',
    },
    'te_IN': {
      'contact_client': 'సంప్రదించండి ',
      'contact_method_prompt': 'మీరు క్లయింట్‌ను ఎలా సంప్రదించాలనుకుంటున్నారు?',
      'outstanding_due_rs': 'బకాయి: రూ. ',
      'advance_rs': 'అడ్వాన్స్: రూ. ',
      'outstanding_nil': 'బకాయి: సున్నా',
      'hello_greeting': 'హలో ',
      'sms_sent_success': 'నేరుగా SMS పంపబడింది ',
      'sms_send_error': 'SMS పంపలేకపోయాము: ',
      'sms_permission_denied': 'నేపథ్యంలో సందేశాలు పంపడానికి SMS అనుమతి అవసరం',
      'direct_call_error': 'నేరుగా కాల్ చేయలేకపోయాము: ',
      'phone_permission_denied': 'నేరుగా కాల్ చేయడానికి ఫోన్ అనుమతి అవసరం',
      'direct_sms': 'డైరెక్ట్ SMS',
      'call': 'కాల్',
      'phone_missing': 'ఫోన్ లేదు',
      'phone_not_configured': 'ఈ క్లయింట్‌కు ఫోన్ నంబర్ కాన్ఫిగర్ చేయబడలేదు.',
      'qty_rate': 'మొత్తం / ధర',
      'gst_rate_percent': 'GST రేటు (%)',
      'tax_amount_caps': 'పన్ను మొత్తం',
      'hsn_sac_code': 'HSN/SAC కోడ్',
      'taxable_amount': 'పన్ను విధించదగిన మొత్తం',
    },
    'ta_IN': {
      'contact_client': 'தொடர்பு கொள்க ',
      'contact_method_prompt':
          'வாடிக்கையாளரை எவ்வாறு தொடர்பு கொள்ள விரும்புகிறீர்கள்?',
      'outstanding_due_rs': 'நிலுவைத் தொகை: ரூ. ',
      'advance_rs': 'முன்பணம்: ரூ. ',
      'outstanding_nil': 'நிலுவைத் தொகை: இல்லை',
      'hello_greeting': 'வணக்கம் ',
      'sms_sent_success': 'நேரடியாக SMS அனுப்பப்பட்டது ',
      'sms_send_error': 'SMS அனுப்ப முடியவில்லை: ',
      'sms_permission_denied': 'பின்னணியில் செய்திகளை அனுப்ப SMS அனுமதி தேவை',
      'direct_call_error': 'நேரடி அழைப்பு செய்ய முடியவில்லை: ',
      'phone_permission_denied':
          'நேரடி அழைப்புகளைச் செய்ய தொலைபேசி அனுமதி தேவை',
      'direct_sms': 'நேரடி SMS',
      'call': 'அழை',
      'phone_missing': 'தொலைபேசி இல்லை',
      'phone_not_configured':
          'இந்த வாடிக்கையாளருக்கு தொலைபேசி எண் அமைக்கப்படவில்லை.',
      'qty_rate': 'அளவு / விலை',
      'gst_rate_percent': 'GST விகிதம் (%)',
      'tax_amount_caps': 'வரித் தொகை',
      'hsn_sac_code': 'HSN/SAC குறியீடு',
      'taxable_amount': 'வரிக்கு உட்பட்ட தொகை',
    },
    'mr_IN': {
      'contact_client': 'संपर्क करा ',
      'contact_method_prompt': 'आपल्याला क्लायंटशी कसा संपर्क साधायचा आहे?',
      'outstanding_due_rs': 'थकबाकी: रु. ',
      'advance_rs': 'आगाऊ रक्कम: रु. ',
      'outstanding_nil': 'थकबाकी: काहीही नाही',
      'hello_greeting': 'नमस्कार ',
      'sms_sent_success': 'थेट SMS पाठवला ',
      'sms_send_error': 'SMS पाठवू शकलो नाही: ',
      'sms_permission_denied':
          'पार्श्वभूमीत संदेश पाठवण्यासाठी SMS परवानगी आवश्यक आहे',
      'direct_call_error': 'थेट कॉल करू शकलो नाही: ',
      'phone_permission_denied': 'थेट कॉल करण्यासाठी फोन परवानगी आवश्यक आहे',
      'direct_sms': 'थेट SMS',
      'call': 'कॉल करा',
      'phone_missing': 'फोन उपलब्ध नाही',
      'phone_not_configured': 'या क्लायंटसाठी फोन नंबर कॉन्फिगर केलेला नाही.',
      'qty_rate': 'प्रमाण / दर',
      'gst_rate_percent': 'GST दर (%)',
      'tax_amount_caps': 'कर रक्कम',
      'hsn_sac_code': 'HSN/SAC कोड',
      'taxable_amount': 'करपात्र रक्कम',
    },
    'gu_IN': {
      'contact_client': 'સંપર્ક કરો ',
      'contact_method_prompt': 'તમે ક્લાયંટનો કેવી રીતે સંપર્ક કરવા માંગો છો?',
      'outstanding_due_rs': 'બાકી રકમ: રૂ. ',
      'advance_rs': 'એડવાન્સ: રૂ. ',
      'outstanding_nil': 'બાકી રકમ: શૂન્ય',
      'hello_greeting': 'નમસ્તે ',
      'sms_sent_success': 'સીધો SMS મોકલ્યો ',
      'sms_send_error': 'SMS મોકલી શક્યા નથી: ',
      'sms_permission_denied':
          'બેકગ્રાઉન્ડમાં મેસેજ મોકલવા માટે SMS પરવાનગી જરૂરી છે',
      'direct_call_error': 'સીધો કૉલ કરી શક્યા નથી: ',
      'phone_permission_denied': 'સીધા કૉલ કરવા માટે ફોન પરવાનગી જરૂરી છે',
      'direct_sms': 'સીધો SMS',
      'call': 'કૉલ કરો',
      'phone_missing': 'ફોન ગેરહાજર',
      'phone_not_configured': 'આ ક્લાયંટ માટે ફોન નંબર ગોઠવેલ નથી.',
      'qty_rate': 'જથ્થો / દર',
      'gst_rate_percent': 'GST દર (%)',
      'tax_amount_caps': 'કરની રકમ',
      'hsn_sac_code': 'HSN/SAC કોડ',
      'taxable_amount': 'કરપાત્ર રકમ',
    },
    'ur_IN': {
      'contact_client': 'رابطہ کریں ',
      'contact_method_prompt': 'آپ کلائنٹ سے کیسے رابطہ کرنا چاہیں گے؟',
      'outstanding_due_rs': 'بقایا جات: روپے ',
      'advance_rs': 'ایڈوانس: روپے ',
      'outstanding_nil': 'بقایا جات: کچھ نہیں',
      'hello_greeting': 'ہیلو ',
      'sms_sent_success': 'براہ راست SMS بھیجا گیا ',
      'sms_send_error': 'SMS نہیں بھیجا جا سکا: ',
      'sms_permission_denied':
          'پس منظر میں پیغامات بھیجنے کے لیے SMS کی اجازت درکار ہے',
      'direct_call_error': 'براہ راست کال نہیں کی جا سکی: ',
      'phone_permission_denied':
          'براہ راست کال کرنے کے لیے فون کی اجازت درکار ہے',
      'direct_sms': 'براہ راست SMS',
      'call': 'کال کریں',
      'phone_missing': 'فون غائب',
      'phone_not_configured': 'اس کلائنٹ کا فون نمبر کنفیگر نہیں کیا گیا ہے۔',
      'qty_rate': 'مقدار / شرح',
      'gst_rate_percent': 'جی ایس ٹی کی شرح (%)',
      'tax_amount_caps': 'ٹیکس کی رقم',
      'hsn_sac_code': 'HSN/SAC کوڈ',
      'taxable_amount': 'قابل ٹیکس رقم',
    },
    'kn_IN': {
      'contact_client': 'ಸಂಪರ್ಕಿಸಿ ',
      'contact_method_prompt': 'ಕ್ಲೈಂಟ್ ಅನ್ನು ಹೇಗೆ ಸಂಪರ್ಕಿಸಲು ನೀವು ಬಯಸುತ್ತೀರಿ?',
      'outstanding_due_rs': 'ಬಾಕಿ ಮೊತ್ತ: ರೂ. ',
      'advance_rs': 'ಮುಂಗಡ: ರೂ. ',
      'outstanding_nil': 'ಬಾಕಿ ಮೊತ್ತ: ಇಲ್ಲ',
      'hello_greeting': 'ನಮಸ್ಕಾರ ',
      'sms_sent_success': 'ನೇರ SMS ಕಳುಹಿಸಲಾಗಿದೆ ',
      'sms_send_error': 'SMS ಕಳುಹಿಸಲಾಗಲಿಲ್ಲ: ',
      'sms_permission_denied':
          'ಹಿನ್ನೆಲೆಯಲ್ಲಿ ಸಂದೇಶಗಳನ್ನು ಕಳುಹಿಸಲು SMS ಅನುಮತಿ ಅಗತ್ಯವಿದೆ',
      'direct_call_error': 'ನೇರ ಕರೆ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ: ',
      'phone_permission_denied': 'ನೇರ ಕರೆಗಳನ್ನು ಮಾಡಲು ಫೋನ್ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ',
      'direct_sms': 'ನೇರ SMS',
      'call': 'ಕರೆ ಮಾಡಿ',
      'phone_missing': 'ಫೋನ್ ಇಲ್ಲ',
      'phone_not_configured': 'ಈ ಕ್ಲೈಂಟ್‌ಗೆ ಫೋನ್ ಸಂಖ್ಯೆ ಕಾನ್ಫಿಗರ್ ಆಗಿಲ್ಲ.',
      'qty_rate': 'ಪ್ರಮಾಣ / ದರ',
      'gst_rate_percent': 'GST ದರ (%)',
      'tax_amount_caps': 'ತೆರಿಗೆ ಮೊತ್ತ',
      'hsn_sac_code': 'HSN/SAC ಕೋಡ್',
      'taxable_amount': 'ತೆರಿಗೆಗೆ ಒಳಪಡುವ ಮೊತ್ತ',
    },
    'or_IN': {
      'contact_client': 'ସମ୍ପର୍କ କରନ୍ତୁ ',
      'contact_method_prompt':
          'ଆପଣ କ୍ଲାଏଣ୍ଟଙ୍କ ସହ କିପରି ସମ୍ପର୍କ କରିବାକୁ ଚାହାଁନ୍ତି?',
      'outstanding_due_rs': 'ବକେୟା: ଟ. ',
      'advance_rs': 'ଅଗ୍ରୀମ: ଟ. ',
      'outstanding_nil': 'ବକେୟା: ଶୂନ୍ୟ',
      'hello_greeting': 'ନମସ୍କାର ',
      'sms_sent_success': 'ସିଧାସଳଖ SMS ପଠାଗଲା ',
      'sms_send_error': 'SMS ପଠାଇ ହେଲାନି: ',
      'sms_permission_denied':
          'ବ୍ୟାକଗ୍ରାଉଣ୍ଡରେ ମେସେଜ୍ ପଠାଇବା ପାଇଁ SMS ଅନୁମତି ଆବଶ୍ୟକ',
      'direct_call_error': 'ସିଧା କଲ୍ କରିହେଲାନି: ',
      'phone_permission_denied': 'ସିଧା କଲ୍ କରିବା ପାଇଁ ଫୋନ୍ ଅନୁମତି ଆବଶ୍ୟକ',
      'direct_sms': 'ସିଧା SMS',
      'call': 'କଲ୍ କରନ୍ତୁ',
      'phone_missing': 'ଫୋନ୍ ନାହିଁ',
      'phone_not_configured': 'ଏହି କ୍ଲାଏଣ୍ଟର ଫୋନ୍ ନମ୍ବର କନଫିଗର ହୋଇନାହିଁ।',
      'qty_rate': 'ପରିମାଣ / ହାର',
      'gst_rate_percent': 'GST ହାର (%)',
      'tax_amount_caps': 'ଟ୍ୟାକ୍ସ ପରିମାଣ',
      'hsn_sac_code': 'HSN/SAC କୋଡ୍',
      'taxable_amount': 'ଟ୍ୟାକ୍ସଯୋଗ୍ୟ ପରିମାଣ',
    },
    'ml_IN': {
      'contact_client': 'ബന്ധപ്പെടുക ',
      'contact_method_prompt':
          'നിങ്ങൾ എങ്ങനെ ക്ലയന്റുമായി ബന്ധപ്പെടാൻ ആഗ്രഹിക്കുന്നു?',
      'outstanding_due_rs': 'കുടിശ്ശിക: രൂ. ',
      'advance_rs': 'അഡ്വാൻസ്: രൂ. ',
      'outstanding_nil': 'കുടിശ്ശിക: ഇല്ല',
      'hello_greeting': 'ഹലോ ',
      'sms_sent_success': 'നേരിട്ട് SMS അയച്ചു ',
      'sms_send_error': 'SMS അയക്കാൻ കഴിഞ്ഞില്ല: ',
      'sms_permission_denied':
          'പശ്ചാത്തലത്തിൽ സന്ദേശങ്ങൾ അയക്കുന്നതിന് SMS അനുമതി ആവശ്യമാണ്',
      'direct_call_error': 'നേരിട്ട് വിളിക്കാൻ കഴിഞ്ഞില്ല: ',
      'phone_permission_denied':
          'നേരിട്ടുള്ള കോളുകൾ ചെയ്യാൻ ഫോൺ അനുമതി ആവശ്യമാണ്',
      'direct_sms': 'നേരിട്ടുള്ള SMS',
      'call': 'വിളിക്കുക',
      'phone_missing': 'ഫോൺ ഇല്ല',
      'phone_not_configured': 'ഈ ക്ലയന്റിന് ഫോൺ നമ്പർ നൽകിയിട്ടില്ല.',
      'qty_rate': 'അളവ് / നിരക്ക്',
      'gst_rate_percent': 'GST നിരക്ക് (%)',
      'tax_amount_caps': 'നികുതി തുക',
      'hsn_sac_code': 'HSN/SAC കോഡ്',
      'taxable_amount': 'നികുതി വിധേയമായ തുക',
    },
  };

  final List<String> keys = [
    'contact_client',
    'contact_method_prompt',
    'outstanding_due_rs',
    'advance_rs',
    'outstanding_nil',
    'hello_greeting',
    'sms_sent_success',
    'sms_send_error',
    'sms_permission_denied',
    'direct_call_error',
    'phone_permission_denied',
    'direct_sms',
    'call',
    'phone_missing',
    'phone_not_configured',
    'qty_rate',
    'gst_rate_percent',
    'tax_amount_caps',
    'hsn_sac_code',
    'taxable_amount',
  ];

  for (var entry in translations.entries) {
    final locale = entry.key;
    final dict = entry.value;

    final startIndex = content.indexOf("'\$locale': {");
    if (startIndex == -1) continue;

    final endIndex = content.indexOf("},", startIndex);
    if (endIndex == -1) continue;

    String localeBlock = content.substring(startIndex, endIndex);

    for (var key in keys) {
      final regex = RegExp("'\$key':\\s*'.*?',");
      if (localeBlock.contains(regex)) {
        localeBlock = localeBlock.replaceAll(
          regex,
          "'\$key': '\${dict[key]}',",
        );
      }
    }

    content = content.replaceRange(startIndex, endIndex, localeBlock);
  }

  // Also remove duplicated keys
  // Since the old script accidentally appended the same keys twice inside en_US, etc.
  // Wait, I will just leave the first occurrence updated, but we might have duplicates in the file.
  // Instead of complex deduplication, the Dart Map just takes the last one or we can just clean it if needed.
  // Actually, replaceAll replaces all occurrences in the localeBlock, so both duplicates will be updated to the same text. That's fine!

  file.writeAsStringSync(content);
  print('Done fixing old translations!');
}
