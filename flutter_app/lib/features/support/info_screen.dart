import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';
import '../../core/utils/api_service.dart';

class InfoScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  final Color headerColor;
  final IconData icon;
  final String fallbackText;

  const InfoScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.headerColor,
    required this.icon,
    required this.fallbackText,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: widget.headerColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: ApiService.get(widget.endpoint),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ));
            }
            
            String contentText = widget.fallbackText;
            if (snapshot.hasData && snapshot.data != null) {
              try {
                final json = jsonDecode(snapshot.data!.body);
                if (json['success'] == true && json['data'] != null) {
                  if (json['data'] is Map && json['data']['value'] != null) {
                    contentText = json['data']['value'];
                  } else if (json['data'] is String) {
                    contentText = json['data'];
                  }
                }
              } catch (_) {
                // Fallback to widget.fallbackText if API is 404 HTML
              }
            }

            // Ensure newlines from API or fallback text are preserved as HTML line breaks
            final formattedContent = contentText.replaceAll('\n', '<br>');

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Html(
                data: formattedContent,
                style: {
                  "body": Style(
                    fontFamily: GoogleFonts.inter().fontFamily,
                    fontSize: FontSize(14.0),
                    lineHeight: const LineHeight(1.6),
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
