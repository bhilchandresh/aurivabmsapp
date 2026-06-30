import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final Map<String, Map<String, String>> translations = {
    'hi_IN': {
      'bms_full_caps': 'व्यवसाय प्रबंधन प्रणाली',
      'your_information': 'आपकी जानकारी',
      'your_info_sub': 'अपना व्यक्तिगत विवरण और भूमिका देखें',
      'notifications': 'सूचनाएं',
      'notifications_sub': 'आपके हाल के अपडेट',
      'no_notifications': 'अभी तक कोई सूचना नहीं',
      'view_details': 'विवरण देखें',
      'full_name': 'पूरा नाम',
      'email_address': 'ईमेल पता',
      'access_level': 'पहुंच स्तर',
      'app_name_auriva': 'ऑरिवा',
      'app_name_bms': 'बीएमएस',
      'user_role_default': 'उपयोगकर्ता',
    },
    'bn_IN': {
      'bms_full_caps': 'ব্যবসা ব্যবস্থাপনা সিস্টেম',
      'your_information': 'আপনার তথ্য',
      'your_info_sub': 'আপনার ব্যক্তিগত বিবরণ এবং ভূমিকা দেখুন',
      'notifications': 'বিজ্ঞপ্তি',
      'notifications_sub': 'আপনার সাম্প্রতিক আপডেট',
      'no_notifications': 'এখনও কোন বিজ্ঞপ্তি নেই',
      'view_details': 'বিস্তারিত দেখুন',
      'full_name': 'পুরো নাম',
      'email_address': 'ইমেইল ঠিকানা',
      'access_level': 'অ্যাক্সেস স্তর',
      'app_name_auriva': 'অরিভা',
      'app_name_bms': 'বিএমএস',
      'user_role_default': 'ব্যবহারকারী',
    },
    'te_IN': {
      'bms_full_caps': 'వ్యాపార నిర్వహణ వ్యవస్థ',
      'your_information': 'మీ సమాచారం',
      'your_info_sub': 'మీ వ్యక్తిగత వివరాలు మరియు పాత్రను చూడండి',
      'notifications': 'నోటిఫికేషన్లు',
      'notifications_sub': 'మీ ఇటీవలి నవీకరణలు',
      'no_notifications': 'ఇంకా నోటిఫికేషన్లు లేవు',
      'view_details': 'వివరాలు చూడండి',
      'full_name': 'పూర్తి పేరు',
      'email_address': 'ఇమెయిల్ చిరునామా',
      'access_level': 'యాక్సెస్ స్థాయి',
      'app_name_auriva': 'ఆరివా',
      'app_name_bms': 'బిఎంఎస్',
      'user_role_default': 'వినియోగదారు',
    },
    'ta_IN': {
      'bms_full_caps': 'வணிக மேலாண்மை அமைப்பு',
      'your_information': 'உங்கள் தகவல்',
      'your_info_sub': 'உங்கள் தனிப்பட்ட விவரங்கள் மற்றும் பாத்திரத்தை காண்க',
      'notifications': 'அறிவிப்புகள்',
      'notifications_sub': 'உங்கள் சமீபத்திய புதுப்பிப்புகள்',
      'no_notifications': 'இதுவரை எந்த அறிவிப்பும் இல்லை',
      'view_details': 'விவரங்களைக் காண்க',
      'full_name': 'முழு பெயர்',
      'email_address': 'மின்னஞ்சல் முகவரி',
      'access_level': 'அணுகல் நிலை',
      'app_name_auriva': 'ஆரிவா',
      'app_name_bms': 'பிஎம்எஸ்',
      'user_role_default': 'பயனர்',
    },
    'ur_IN': {
      'bms_full_caps': 'کاروباری انتظامی نظام',
      'your_information': 'آپ کی معلومات',
      'your_info_sub': 'اپنی ذاتی تفصیلات اور کردار دیکھیں',
      'notifications': 'اطلاعات',
      'notifications_sub': 'آپ کی حالیہ اپ ڈیٹس',
      'no_notifications': 'ابھی تک کوئی اطلاع نہیں',
      'view_details': 'تفصیلات دیکھیں',
      'full_name': 'پورا نام',
      'email_address': 'ای میل ایڈریس',
      'access_level': 'رسائی کی سطح',
      'app_name_auriva': 'آریوا',
      'app_name_bms': 'بی ایم ایس',
      'user_role_default': 'صارف',
    },
    'kn_IN': {
      'bms_full_caps': 'ವ್ಯಾಪಾರ ನಿರ್ವಹಣಾ ವ್ಯವಸ್ಥೆ',
      'your_information': 'ನಿಮ್ಮ ಮಾಹಿತಿ',
      'your_info_sub': 'ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ವಿವರಗಳು ಮತ್ತು ಪಾತ್ರವನ್ನು ವೀಕ್ಷಿಸಿ',
      'notifications': 'ಸೂಚನೆಗಳು',
      'notifications_sub': 'ನಿಮ್ಮ ಇತ್ತೀಚಿನ ನವೀಕರಣಗಳು',
      'no_notifications': 'ಇನ್ನೂ ಯಾವುದೇ ಸೂಚನೆಗಳಿಲ್ಲ',
      'view_details': 'ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
      'full_name': 'ಪೂರ್ಣ ಹೆಸರು',
      'email_address': 'ಇಮೇಲ್ ವಿಳಾಸ',
      'access_level': 'ಪ್ರವೇಶ ಮಟ್ಟ',
      'app_name_auriva': 'ಔರಿವಾ',
      'app_name_bms': 'ಬಿಎಂಎಸ್',
      'user_role_default': 'ಬಳಕೆದಾರ',
    },
    'or_IN': {
      'bms_full_caps': 'ବ୍ୟବସାୟ ପରିଚାଳନା ପ୍ରଣାଳୀ',
      'your_information': 'ଆପଣଙ୍କ ସୂଚନା',
      'your_info_sub': 'ଆପଣଙ୍କର ବ୍ୟକ୍ତିଗତ ବିବରଣୀ ଏବଂ ଭୂମିକା ଦେଖନ୍ତୁ',
      'notifications': 'ବିଜ୍ଞପ୍ତିଗୁଡ଼ିକ',
      'notifications_sub': 'ଆପଣଙ୍କର ସାମ୍ପ୍ରତିକ ଅପଡେଟ୍',
      'no_notifications': 'ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି ବିଜ୍ଞପ୍ତି ନାହିଁ',
      'view_details': 'ବିବରଣୀ ଦେଖନ୍ତୁ',
      'full_name': 'ପୂରା ନାମ',
      'email_address': 'ଇମେଲ୍ ଠିକଣା',
      'access_level': 'ଆକ୍ସେସ୍ ସ୍ତର',
      'app_name_auriva': 'ଔରିଭା',
      'app_name_bms': 'ବିଏମଏସ୍',
      'user_role_default': 'ବ୍ୟବହାରକାରୀ',
    },
    'ml_IN': {
      'bms_full_caps': 'ബിസിനസ്സ് മാനേജ്മെന്റ് സിസ്റ്റം',
      'your_information': 'നിങ്ങളുടെ വിവരങ്ങൾ',
      'your_info_sub': 'നിങ്ങളുടെ വ്യക്തിഗത വിശദാംശങ്ങളും റോളും കാണുക',
      'notifications': 'അറിയിപ്പുകൾ',
      'notifications_sub': 'നിങ്ങളുടെ സമീപകാല അപ്‌ഡേറ്റുകൾ',
      'no_notifications': 'ഇതുവരെ അറിയിപ്പുകളൊന്നുമില്ല',
      'view_details': 'വിശദാംശങ്ങൾ കാണുക',
      'full_name': 'മുഴുവൻ പേര്',
      'email_address': 'ഇമെയിൽ വിലാസം',
      'access_level': 'ആക്സസ് ലെവൽ',
      'app_name_auriva': 'ഓറിവ',
      'app_name_bms': 'ബിഎംഎസ്',
      'user_role_default': 'ഉപയോക്താവ്',
    },
    'gu_IN': {
      'bms_full_caps': 'વ્યાપાર સંચાલન સિસ્ટમ',
      'your_information': 'તમારી માહિતી',
      'your_info_sub': 'તમારી વ્યક્તિગત વિગતો અને ભૂમિકા જુઓ',
      'notifications': 'સૂચનાઓ',
      'notifications_sub': 'તમારા તાજેતરના અપડેટ્સ',
      'no_notifications': 'હજી સુધી કોઈ સૂચનાઓ નથી',
      'view_details': 'વિગતો જુઓ',
      'full_name': 'પૂરું નામ',
      'email_address': 'ઇમેઇલ સરનામું',
      'access_level': 'એક્સેસ સ્તર',
      'app_name_auriva': 'ઓરિવા',
      'app_name_bms': 'બીએમએસ',
      'user_role_default': 'વપરાશકર્તા',
    },
    'mr_IN': {
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
    },
  };

  final List<String> keys = [
    'bms_full_caps',
    'your_information',
    'your_info_sub',
    'notifications',
    'notifications_sub',
    'no_notifications',
    'view_details',
    'full_name',
    'email_address',
    'access_level',
    'app_name_auriva',
    'app_name_bms',
    'user_role_default',
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

  file.writeAsStringSync(content);
  print('Done fixing translations!');
}
