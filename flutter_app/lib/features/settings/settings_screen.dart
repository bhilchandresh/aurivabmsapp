// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/services/permission_manager.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_button.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _gstNumberCtrl = TextEditingController();
  final TextEditingController _termsCtrl = TextEditingController();
  final TextEditingController _accNameCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _accNumCtrl = TextEditingController();
  final TextEditingController _ifscCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();

  String? _selectedState;
  bool _gstEnabled = false;
  String? _logoBase64;
  bool _isSaving = false;
  bool _isLoading = true;
  int? _hoveredCardIndex;

  final List<String> _indianStates = [
    "Andaman and Nicobar Islands",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chandigarh",
    "Chhattisgarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jammu and Kashmir",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Ladakh",
    "Lakshadweep",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Puducherry",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final authController = Get.find<AuthController>();
      await authController.fetchTenantSettings();
      final tenant = authController.tenantInfo.value ?? {};

      _nameCtrl.text = tenant['name'] ?? 'Loading Company';
      _emailCtrl.text = tenant['email'] ?? 'loading@company.com';
      _phoneCtrl.text = tenant['phone'] ?? '+91 0000000000';
      _websiteCtrl.text = tenant['website'] ?? 'https://loading.com';
      _addressCtrl.text = tenant['address'] ?? 'Loading Address Details';
      _gstNumberCtrl.text = tenant['gstNumber'] ?? '29ABCDE1234F1Z1';
      _termsCtrl.text = tenant['defaultTerms'] ?? 'Loading Terms';

      final bank = tenant['bankDetails'] ?? {};
      _accNameCtrl.text = bank['accountName'] ?? 'Loading Name';
      _bankNameCtrl.text = bank['bankName'] ?? 'Loading Bank';
      _accNumCtrl.text = bank['accountNumber'] ?? '00000000000';
      _ifscCtrl.text = bank['ifscCode'] ?? 'SBIN0000000';

      _selectedState = tenant['state'];
      _stateCtrl.text = _selectedState ?? '';
      _gstEnabled = tenant['gstEnabled'] ?? false;
      _logoBase64 = tenant['logoImage'];
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _gstNumberCtrl.dispose();
    _termsCtrl.dispose();
    _accNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final isGranted = await PermissionManager.requestGalleryPermission();
    if (!isGranted) return;
    
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 600,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          Get.snackbar(
            'File Too Large',
            'Please choose an image smaller than 2MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          return;
        }

        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        setState(() {
          _logoBase64 = base64String;
        });

        Get.snackbar(
          'Logo Uploaded',
          'Company logo loaded successfully (save settings to commit).',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Upload Failed',
        'Could not upload logo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _removeLogo() {
    setState(() {
      _logoBase64 = null;
    });
    Get.snackbar(
      'Logo Removed',
      'Company logo has been removed from branding settings.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.amber.shade600,
      colorText: Colors.white,
    );
  }

  void _showStatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'select_state'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _indianStates.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    final state = _indianStates[index];
                    final isSelected = _selectedState == state;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedState = state;
                          _stateCtrl.text = state;
                        });
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(LucideIcons.check, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Form Incomplete',
        'Please verify and correct all highlighted settings error fields.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authController = Get.find<AuthController>();

      final response = await ApiService.put(ApiConstants.settings, {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'state': _selectedState,
        'gstEnabled': _gstEnabled,
        'gstNumber': _gstEnabled ? _gstNumberCtrl.text.trim() : '',
        'logoImage': _logoBase64,
        'defaultTerms': _termsCtrl.text.trim(),
        'bankDetails': {
          'accountName': _accNameCtrl.text.trim(),
          'bankName': _bankNameCtrl.text.trim(),
          'accountNumber': _accNumCtrl.text.trim(),
          'ifscCode': _ifscCtrl.text.trim(),
        },
      });

      if (response.statusCode == 200) {
        await authController.fetchTenantSettings();

        Get.snackbar(
          'Settings Saved',
          'Company profile and billing configurations updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final errorMsg =
            errorBody['message'] ??
            'Failed to update settings. Please try again.';
        Get.snackbar(
          'Error',
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'company_settings'.tr,
        subtitle: 'manage_company_settings'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BRANDING
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _buildSectionCard(
                    index: 0,
                    title: 'company_branding'.tr,
                    subtitle: 'Upload your logo & brand identity'.tr,
                    icon: LucideIcons.image,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'company_logo'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (_logoBase64 != null)
                              Stack(
                                children: [
                                  Container(
                                    height: 90,
                                    width: 90,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Center(
                                        child:
                                            _logoBase64!.startsWith(
                                                  'data:image',
                                                ) ||
                                                !_logoBase64!.contains('MOCK_')
                                            ? Image.memory(
                                                base64Decode(
                                                  _logoBase64!.contains(',')
                                                      ? _logoBase64!.split(
                                                          ',',
                                                        )[1]
                                                      : _logoBase64!,
                                                ),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      LucideIcons.image,
                                                      size: 28,
                                                    ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    LucideIcons.building,
                                                    size: 28,
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.8),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'no_logo'.tr,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 10,
                                                      color: AppColors.primary,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: _removeLogo,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.trash2,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                height: 90,
                                width: 90,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.image,
                                      size: 24,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'no_logo'.tr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickLogo,
                                    icon: const Icon(
                                      LucideIcons.upload,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'upload_new_logo'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Recommended: Square image,\nPNG or JPG (Max 500KB).'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. BUSINESS INFORMATION
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 350),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _buildSectionCard(
                    index: 1,
                    title: 'business_info'.tr,
                    subtitle: 'Update your company details'.tr,
                    icon: LucideIcons.building,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'company_name_star'.tr,
                          hintText: 'eg_company_name'.tr,
                          controller: _nameCtrl,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Company name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'official_email_star'.tr,
                          hintText: 'eg_official_email'.tr,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!GetUtils.isEmail(val.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'phone_number'.tr,
                                hintText: 'eg_phone_number'.tr,
                                controller: _phoneCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'website_optional'.tr,
                                hintText: 'eg_website'.tr,
                                controller: _websiteCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'state_ut_star'.tr,
                          hintText: 'select_state'.tr,
                          controller: _stateCtrl,
                          readOnly: true,
                          onTap: _showStatePicker,
                          suffixIcon: const Icon(LucideIcons.chevronDown, size: 18, color: Colors.grey),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please select state';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'business_address_star'.tr,
                          hintText: 'eg_business_address'.tr,
                          controller: _addressCtrl,
                          maxLines: 3,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Address is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. TAXATION & INVOICE TERMS
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 450),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _buildSectionCard(
                    index: 2,
                    title: 'taxation_invoice_terms'.tr,
                    subtitle: 'Manage GST registration and invoice terms'.tr,
                    icon: LucideIcons.fileText,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _gstEnabled,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                                onChanged: (val) {
                                  setState(() {
                                    _gstEnabled = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'register_for_gst'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Enable if your business is GST registered'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          label: 'gstin'.tr,
                          hintText: 'eg_gstin'.tr,
                          controller: _gstNumberCtrl,
                          enabled: _gstEnabled,
                          validator: (val) {
                            if (_gstEnabled) {
                              if (val == null || val.trim().isEmpty) {
                                return 'GST number is required';
                              }
                              if (val.trim().length != 15) {
                                return 'GSTIN must be exactly 15 characters';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'default_invoice_terms'.tr,
                          hintText: 'eg_invoice_terms'.tr,
                          controller: _termsCtrl,
                          maxLines: 4,
                          maxLength: 500,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. BANKING DETAILS
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 550),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _buildSectionCard(
                    index: 3,
                    title: 'banking_details'.tr,
                    subtitle: 'Manage your business banking information'.tr,
                    icon: LucideIcons.landmark,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'account_holder_name'.tr,
                          hintText: 'eg_account_holder'.tr,
                          controller: _accNameCtrl,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'bank_name'.tr,
                          hintText: 'eg_bank_name'.tr,
                          controller: _bankNameCtrl,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'account_number'.tr,
                                hintText: 'eg_account_number'.tr,
                                controller: _accNumCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'ifsc_code'.tr,
                                hintText: 'eg_ifsc'.tr,
                                controller: _ifscCtrl,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Save Button
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 650),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'update_business_settings'.tr,
                      icon: const Icon(
                        LucideIcons.save,
                        size: 18,
                        color: Colors.white,
                      ),
                      isLoading: _isSaving,
                      onPressed: _saveSettings,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _buildDangerZone(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Form Field Helper
  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade700),
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black) : Colors.grey.shade400,
            overflow: TextOverflow.ellipsis,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            fillColor: enabled ? Colors.transparent : Colors.grey.shade50,
            filled: !enabled,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredCardIndex = index;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredCardIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHovered
                ? AppColors.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isHovered ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isHovered
                        ? AppColors.primary
                        : Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHovered
                              ? AppColors.primary
                              : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
  Widget _buildDangerZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // tailwind rose-50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFECDD3), // tailwind rose-200
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: Color(0xFFDC2626), // tailwind red-600
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF991B1B), // tailwind red-800
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Permanently deleting your account will revoke access to all your business data, invoices, and settings. This action cannot be undone.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB91C1C), // tailwind red-700
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showDeleteConfirmationDialog,
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: const Text(
              'Request Account Deletion',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    bool isRequestingOTP = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Are you absolutely sure you want to delete your account? A 6-digit OTP will be sent to your email to verify your identity.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // amber-50
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)), // amber-200
                      ),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13, color: Color(0xFF92400E)), // amber-800
                          children: [
                            TextSpan(
                              text: 'Note: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Since business data is crucial, we retain your data securely for ',
                            ),
                            TextSpan(
                              text: '30 days ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'after deletion. If you wish to recover your account during this period, please contact the AurivaBMS team.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isRequestingOTP)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isRequestingOTP
                              ? null
                              : () async {
                                  setStateDialog(() => isRequestingOTP = true);
                                  final authCtrl = Get.find<AuthController>();
                                  final bool success = await authCtrl.requestAccountDeletion();
                                  if (mounted && context.mounted) {
                                    setStateDialog(() => isRequestingOTP = false);
                                    if (success) {
                                      Navigator.pop(context);
                                      _showOTPVerificationDialog();
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: isRequestingOTP
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Yes, Send OTP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOTPVerificationDialog() {
    final TextEditingController otpCtrl = TextEditingController();
    bool isDeleting = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isOtpValid = otpCtrl.text.trim().length == 6;
            
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Enter the 6-digit verification code sent to your email to confirm deletion.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: otpCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (val) {
                          setStateDialog(() {}); // trigger rebuild to update button state
                        },
                        style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                          hintText: "- - - - - -",
                          hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isDeleting)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (isOtpValid && !isDeleting)
                              ? () async {
                                  setStateDialog(() => isDeleting = true);
                                  final authCtrl = Get.find<AuthController>();
                                  final bool success = await authCtrl.confirmAccountDeletion(otpCtrl.text.trim());
                                  if (mounted && context.mounted) {
                                    setStateDialog(() => isDeleting = false);
                                    if (success) {
                                      Navigator.pop(context);
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOtpValid ? const Color(0xFFDC2626) : const Color(0xFFF87171),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            disabledBackgroundColor: const Color(0xFFF87171),
                            disabledForegroundColor: Colors.white,
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Permanently Delete',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
