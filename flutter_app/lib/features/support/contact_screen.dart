import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../../core/utils/api_service.dart';
import 'info_screen.dart';
import '../../shared/widgets/app_top_bar.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _selectedSubject;
  bool _isLoading = false;

  final List<String> _subjects = [
    'General Inquiry',
    'Technical Support',
    'Billing',
    'Feature Request',
    'Other'
  ];

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Required Fields',
        'Please fill in all the required fields before sending.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/public/contact', {
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'subject': _selectedSubject ?? 'General Inquiry',
        'message': _messageCtrl.text,
      });
      
      String msg = 'Your message has been sent successfully.';
      try {
        final json = jsonDecode(response.body);
        if (json['message'] != null) msg = json['message'];
      } catch (_) {}

      Get.snackbar(
        'Success',
        msg,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
      
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not send message. Please try again.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppTopBar(
        title: 'Contact Us',
        showMenu: false,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Get in Touch Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                'assets/SVG/message.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(Colors.blue.shade600, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Get in Touch',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Have a question, suggestion or need support? Fill out the form below and we\'ll get back to you soon.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Form Fields
                        _buildInput('Name', 'John Doe', 'assets/SVG/profile.svg', _nameCtrl, isDark),
                        const SizedBox(height: 12),
                        
                        _buildInput('Email Address', 'john@example.com', 'assets/SVG/mail.svg', _emailCtrl, isDark),
                        const SizedBox(height: 12),
                        
                        _buildDropdown('Subject', 'How can we help?', 'assets/SVG/note.svg', isDark),
                        const SizedBox(height: 12),
                        
                        _buildMessageInput(isDark),
                        const SizedBox(height: 16),

                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: _isLoading ? const SizedBox() : SvgPicture.asset('assets/SVG/send.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            label: _isLoading 
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Send Message', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        
                        // Footer
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => Get.to(() => const InfoScreen(
                                      title: 'Terms & Conditions',
                                      endpoint: '/public/legal/terms_and_conditions',
                                      headerColor: Color(0xFF2563EB),
                                      icon: LucideIcons.fileText,
                                      fallbackText: 'Welcome to Auriva BMS.',
                                    )),
                                    child: Text('Terms of Service', style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade600)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('|', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade300)),
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.to(() => const InfoScreen(
                                      title: 'Privacy Policy',
                                      endpoint: '/public/legal/privacy_policy',
                                      headerColor: Color(0xFF0F9D58),
                                      icon: LucideIcons.shieldCheck,
                                      fallbackText: 'Auriva BMS is committed to protecting your privacy.',
                                    )),
                                    child: Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('(c) 2026 Auriva. All rights reserved.', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
          fontSize: 11, 
          fontWeight: FontWeight.w600, 
          color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
        ),
        children: [
          TextSpan(
            text: ' *',
            style: GoogleFonts.inter(
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint, String svgAsset, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isDark),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 8),
              child: SvgPicture.asset(svgAsset, width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, String svgAsset, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isDark),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedSubject,
          icon: Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey.shade400),
          style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 8),
              child: SvgPicture.asset(svgAsset, width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
          items: _subjects.map((String subject) {
            return DropdownMenuItem<String>(
              value: subject,
              child: Text(
                subject,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSubject = newValue;
            });
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Message', isDark),
        const SizedBox(height: 4),
        TextFormField(
          controller: _messageCtrl,
          maxLines: 4,
          maxLength: 500,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
            hintText: 'Write your message here...',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 8, bottom: 60), 
              child: SvgPicture.asset('assets/SVG/message.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
