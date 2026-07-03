import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_extensions.dart';

class LanguageModel {
  final String name;
  final String code;
  final String countryCode;
  final String flag;

  LanguageModel({
    required this.name,
    required this.code,
    required this.countryCode,
    required this.flag,
  });
}

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLangCode;

  final List<LanguageModel> _languages = [
    LanguageModel(
      name: 'English (US)',
      code: 'en',
      countryCode: 'US',
      flag: 'US',
    ),
    LanguageModel(
      name: 'हिंदी (Hindi)',
      code: 'hi',
      countryCode: 'IN',
      flag: 'IN',
    ),
    LanguageModel(
      name: 'ગુજરાતી (Gujarati)',
      code: 'gu',
      countryCode: 'IN',
      flag: 'GJ',
    ),
    LanguageModel(
      name: 'मराठी (Marathi)',
      code: 'mr',
      countryCode: 'IN',
      flag: 'MH',
    ),
    LanguageModel(
      name: 'বাংলা (Bengali)',
      code: 'bn',
      countryCode: 'IN',
      flag: 'WB',
    ),
    LanguageModel(
      name: 'తెలుగు (Telugu)',
      code: 'te',
      countryCode: 'IN',
      flag: 'AP',
    ),
    LanguageModel(
      name: 'தமிழ் (Tamil)',
      code: 'ta',
      countryCode: 'IN',
      flag: 'TN',
    ),
    LanguageModel(
      name: 'اردو (Urdu)',
      code: 'ur',
      countryCode: 'IN',
      flag: 'UP',
    ),
    LanguageModel(
      name: 'ಕನ್ನಡ (Kannada)',
      code: 'kn',
      countryCode: 'IN',
      flag: 'KA',
    ),
    LanguageModel(
      name: 'ଓଡ଼ିଆ (Odia)',
      code: 'or',
      countryCode: 'IN',
      flag: 'OD',
    ),
    LanguageModel(
      name: 'മലയാളം (Malayalam)',
      code: 'ml',
      countryCode: 'IN',
      flag: 'KL',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLangCode = Get.locale?.languageCode ?? 'en';
  }

  void _saveLanguage() async {
    final selectedLang = _languages.firstWhere(
      (l) => l.code == _selectedLangCode,
      orElse: () => _languages.first,
    );

    // Show loading overlay
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: context.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Please wait...',
                  style: context.typography.inputText.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    const storage = FlutterSecureStorage();
    await storage.write(key: 'app_lang_code', value: selectedLang.code);
    await storage.write(
      key: 'app_country_code',
      value: selectedLang.countryCode,
    );

    final newLocale = Locale(selectedLang.code, selectedLang.countryCode);
    AppTheme.currentLocale = newLocale;
    
    // Slight delay before changing theme/locale to let the dialog render smoothly
    await Future.delayed(const Duration(milliseconds: 100));
    
    Get.updateLocale(newLocale);
    Get.changeTheme(Get.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme);

    // Wait for 1.5 seconds to mask the font/theme change glitch
    await Future.delayed(const Duration(milliseconds: 1500));

    // Close dialog
    Get.back();
    // Close screen
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Language',
          style: context.typography.topBarTitle.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.displayLarge?.color,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 28),
          onPressed: () => Get.back(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveLanguage,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(LucideIcons.save),
              label: Text(
                'save_and_exit'.tr,
                style: context.typography.buttonText.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = _selectedLangCode == lang.code;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLangCode = lang.code;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: Text(
                        lang.flag,
                        style: context.typography.inputText.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    lang.name,
                    style: context.typography.sectionTitle.copyWith(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
