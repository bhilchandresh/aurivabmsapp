import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../core/utils/api_service.dart';
import '../../shared/widgets/app_top_bar.dart';

class ViewLegalScreen extends StatefulWidget {
  final String title;
  final String documentType; // 'terms_and_conditions' or 'privacy_policy'

  const ViewLegalScreen({
    super.key,
    required this.title,
    required this.documentType,
  });

  @override
  State<ViewLegalScreen> createState() => _ViewLegalScreenState();
}

class _ViewLegalScreenState extends State<ViewLegalScreen> {
  bool _isLoading = true;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/public/legal/${widget.documentType}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          if (json['data'] is Map && json['data']['value'] != null) {
            _content = json['data']['value'];
          } else if (json['data'] is String) {
            _content = json['data'];
          }
        }
      }
    } catch (e) {
      _content = 'Failed to load document. Please try again later.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppTopBar(
        title: widget.title,
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
                  child: Text(
                    _content.isEmpty ? 'No content available.' : _content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
