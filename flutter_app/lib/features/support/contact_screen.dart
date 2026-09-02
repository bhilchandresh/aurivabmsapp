import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/utils/api_service.dart';
import 'info_screen.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isLoading = false;

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
        'subject': _subjectCtrl.text,
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
      
      // Delay slightly before going back so the user sees the success message
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
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        foregroundColor: Colors.white,
          title: Text(
                "Contact Us",
                style: GoogleFonts.inter(
                 color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight : FontWeight.bold,
                ),
            ),       
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
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
                      padding: const EdgeInsets.all(32),
                      child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Email (Responsive Row)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 400) {
                              return Row(
                                children: [
                                  Expanded(child: _buildInput('Name', 'John Doe', LucideIcons.user, _nameCtrl)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildInput('Email Address', 'john@example.com', LucideIcons.mail, _emailCtrl)),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildInput('Name', 'John Doe', LucideIcons.user, _nameCtrl),
                                  const SizedBox(height: 16),
                                  _buildInput('Email Address', 'john@example.com', LucideIcons.mail, _emailCtrl),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildInput('Subject', 'How can we help?', LucideIcons.bookOpen, _subjectCtrl),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Message',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write your message here...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),

                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: _isLoading ? const SizedBox() : const Icon(LucideIcons.send, size: 18),
                            label: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Send Message', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8.0,
                            children: [
                              Wrap(
                                spacing: 12.0,
                                children: [
                                  GestureDetector(
                                    onTap: () => Get.to(() => const InfoScreen(
                                      title: 'Terms & Conditions',
                                      endpoint: '/public/legal/terms_and_conditions',
                                      headerColor: Color(0xFF2563EB),
                                      icon: LucideIcons.fileText,
                                      fallbackText: 'Welcome to Auriva BMS. By accessing or using our Business Management System, web application, and mobile application (collectively, the "Service"), you agree to be bound by these Terms and Conditions.\n\n1. General Usage\nAuriva BMS provides a software-as-a-service (SaaS) platform for invoicing, quotation management, and business tracking.\n\n2. User Responsibilities\nYou are responsible for maintaining the confidentiality of your account credentials. Any activity occurring under your account is your sole responsibility.',
                                    )),
                                    child: Text('Terms of Service', style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade600, decoration: TextDecoration.underline, decorationColor: Colors.blue.shade600)),
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.to(() => const InfoScreen(
                                      title: 'Privacy Policy',
                                      endpoint: '/public/legal/privacy_policy',
                                      headerColor: Color(0xFF0F9D58),
                                      icon: LucideIcons.shieldCheck,
                                      fallbackText: 'Auriva BMS ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our web application and mobile application.\n\n1. Information We Collect\nWe collect personal information that you voluntarily provide to us when you register on the Service, such as your name, email address, phone number, and company details.\n\n2. How We Use Your Information\nWe use the information we collect primarily to provide, maintain, and improve our Service.',
                                    )),
                                    child: Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade600, decoration: TextDecoration.underline, decorationColor: Colors.blue.shade600)),
                                  ),
                                ],
                              ),
                              Text('© 2026 Auriva. All rights reserved.', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
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

  Widget _buildInput(String label, String hint, IconData icon, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
