import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  TextEditingController _nameCtrl = TextEditingController();
  TextEditingController _emailCtrl = TextEditingController();
  TextEditingController _phoneCtrl = TextEditingController();
  TextEditingController _websiteCtrl = TextEditingController();
  TextEditingController _addressCtrl = TextEditingController();
  TextEditingController _gstNumberCtrl = TextEditingController();
  TextEditingController _termsCtrl = TextEditingController();
  TextEditingController _accNameCtrl = TextEditingController();
  TextEditingController _bankNameCtrl = TextEditingController();
  TextEditingController _accNumCtrl = TextEditingController();
  TextEditingController _ifscCtrl = TextEditingController();

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
    "West Bengal"
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
    super.dispose();
  }

  Future<void> _pickLogo() async {
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
        }
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
        final errorMsg = errorBody['message'] ?? 'Failed to update settings. Please try again.';
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
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Company Settings',
        subtitle: 'Manage and update your business, taxation, and billing settings',
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
                  title: 'Company Branding',
                  icon: LucideIcons.image,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMPANY LOGO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
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
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(
                                      child: _logoBase64!.startsWith('data:image') || !_logoBase64!.contains('MOCK_')
                                          ? Image.memory(
                                              base64Decode(_logoBase64!.contains(',') ? _logoBase64!.split(',')[1] : _logoBase64!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, size: 28),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(LucideIcons.building, size: 28, color: AppColors.primary.withValues(alpha: 0.8)),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'LOGO',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
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
                                      child: const Icon(LucideIcons.trash2, size: 12, color: Colors.white),
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
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.image, size: 24, color: Colors.grey.shade400),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No Logo',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
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
                                  icon: const Icon(LucideIcons.upload, size: 14),
                                  label: const Text(
                                    'Upload New Logo',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Recommended: Square image, PNG or JPG (Max 500KB).',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
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
                  title: 'Business Information',
                  icon: LucideIcons.building,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Company Name *',
                        hintText: 'Auriva Technologies...',
                        controller: _nameCtrl,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Company name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Official Email *',
                        hintText: 'billing@auriva.co',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email is required';
                          if (!GetUtils.isEmail(val.trim())) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Phone Number',
                              hintText: '+91 98765 43210',
                              controller: _phoneCtrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'Website (Optional)',
                              hintText: 'https://auriva.co',
                              controller: _websiteCtrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dropdown State selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              'STATE / UT *',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedState,
                            hint: const Text('Select State', style: TextStyle(fontSize: 12)),
                            items: _indianStates.map((state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedState = val;
                              });
                            },
                            validator: (val) => val == null ? 'Please select state' : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Business Address *',
                        hintText: 'Full physical address details...',
                        controller: _addressCtrl,
                        maxLines: 3,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Address is required';
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
                  title: 'Taxation & Invoice Terms',
                  icon: LucideIcons.fileText,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _gstEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _gstEnabled = val ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Register for GST',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        label: 'GSTIN',
                        hintText: 'Enter 15-digit GSTIN (e.g. 09AAACA1234A1Z5)',
                        controller: _gstNumberCtrl,
                        enabled: _gstEnabled,
                        validator: (val) {
                          if (_gstEnabled) {
                            if (val == null || val.trim().isEmpty) return 'GST number is required';
                            if (val.trim().length != 15) return 'GSTIN must be exactly 15 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Default Invoice Terms',
                        hintText: 'Enter default billing notes...',
                        controller: _termsCtrl,
                        maxLines: 4,
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
                  title: 'Banking Details',
                  icon: LucideIcons.creditCard,
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Account Holder Name',
                        hintText: 'Auriva Tech Pvt Ltd',
                        controller: _accNameCtrl,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Bank Name',
                        hintText: 'e.g. HDFC Bank',
                        controller: _bankNameCtrl,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Account Number',
                              hintText: '1234567890',
                              controller: _accNumCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'IFSC Code',
                              hintText: 'HDFC0000001',
                              controller: _ifscCtrl,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                    text: 'Update Business Settings',
                    icon: const Icon(LucideIcons.save, size: 18, color: Colors.white),
                    isLoading: _isSaving,
                    onPressed: _saveSettings,
                  ),
                ),
              ),
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
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          validator: validator,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textPrimary : Colors.grey.shade400,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required int index,
    required String title,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHovered ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.black.withOpacity(0.01),
              blurRadius: isHovered ? 16 : 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isHovered ? AppColors.primary : Colors.grey.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isHovered ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
