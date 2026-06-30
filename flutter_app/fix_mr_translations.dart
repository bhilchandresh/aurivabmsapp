import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final dict = {
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
    'bms_full_caps': 'व्यवसाय व्यवस्थापन प्रणाली',
    'your_information': 'तुमची माहिती',
    'your_info_sub': 'तुमचे वैयक्तिक तपशील आणि भूमिका पहा',
    'notifications': 'सूचना',
    'notifications_sub': 'तुमची अलीकडील अपडेट्स',
    'no_notifications': 'अद्याप कोणतीही सूचना नाही',
    'view_details': 'तपशील पहा',
    'full_name': 'पूर्ण नाव',
    'email_address': 'ईमेल पत्ता',
    'access_level': 'प्रवेश स्तर',
    'app_name_auriva': 'ऑरिवा',
    'app_name_bms': 'बीएमएस',
    'user_role_default': 'वापरकर्ता',
  };

  final startIndex = content.indexOf("'mr_IN': {");
  if (startIndex != -1) {
    // The end of the file is basically the end of mr_IN block
    String localeBlock = content.substring(startIndex);
    for (var key in dict.keys) {
      final regex = RegExp("'$key':\\s*'.*?',");
      if (localeBlock.contains(regex)) {
        localeBlock = localeBlock.replaceAll(regex, "'$key': '${dict[key]}',");
      }
    }
    content = content.substring(0, startIndex) + localeBlock;
    file.writeAsStringSync(content);
    print('Fixed mr_IN');
  }
}
