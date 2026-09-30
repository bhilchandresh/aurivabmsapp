import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/utils/api_service.dart';
import '../../shared/widgets/app_top_bar.dart';

class EditLegalScreen extends StatefulWidget {
  const EditLegalScreen({super.key});

  @override
  State<EditLegalScreen> createState() => _EditLegalScreenState();
}

class _EditLegalScreenState extends State<EditLegalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedDoc = 'terms_and_conditions';
  
  final Map<String, String> _docTypes = {
    'terms_and_conditions': 'Terms & Conditions',
    'privacy_policy': 'Privacy Policy',
  };

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/public/legal/$_selectedDoc');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          if (json['data'] is Map && json['data']['value'] != null) {
            _textCtrl.text = json['data']['value'];
          } else if (json['data'] is String) {
            _textCtrl.text = json['data'];
          } else {
            _textCtrl.text = '';
          }
        } else {
          _textCtrl.text = '';
        }
      } else {
        _textCtrl.text = '';
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load document: ',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final payload = {
        _selectedDoc: _textCtrl.text,
      };
      final response = await ApiService.put('/settings', payload);
      
      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          ' updated successfully!',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', 'Failed to save changes.',
            backgroundColor: Colors.red.shade600, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while saving: ',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppTopBar(
        title: 'Legal Documents',
        showMenu: false,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Legal Documents',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color ?? (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Update your Privacy Policy and Terms & Conditions directly from here. These will be visible to users in the app.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Document Selector
                        Text(
                          'Select Document',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.displayLarge?.color ?? (isDark ? Colors.white70 : Colors.blueGrey.shade800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDoc,
                          icon: Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey.shade400),
                          dropdownColor: cardColor,
                          style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).textTheme.displayLarge?.color ?? (isDark ? Colors.white : Colors.black87)),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          items: _docTypes.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedDoc = newValue;
                              });
                              _loadDocument();
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Document Content
                        Text(
                          'Content',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.displayLarge?.color ?? (isDark ? Colors.white70 : Colors.blueGrey.shade800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _textCtrl,
                          maxLines: 8,
                          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(16),
                            hintText: 'Enter document content here...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Content cannot be empty' : null,
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveDocument,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: _isSaving ? const SizedBox() : const Icon(LucideIcons.save, size: 18),
                            label: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Save Changes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
